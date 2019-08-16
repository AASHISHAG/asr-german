#!/bin/bash

# Copyright  2014  Nickolay V. Shmyrev
#            2014  Brno University of Technology (Author: Karel Vesely)
#            2016  Vincent Nguyen
#            2016  Johns Hopkins University (Author: Daniel Povey)
#            2018  Language Technology, Universitaet Hamburg (Author: Benjamin Milde)

# Adapted from TED-LIUMs run_tdnn_1f.sh TDNN-CHAIN script with i-vectors.
# run_tdnn_1f.sh uses a proportional-shrink 20.

# without cleanup:
# local/chain/run_tdnn_1f.sh  --train-set train --gmm tri3 --nnet3-affix "" &

# note, if you have already run the corresponding non-chain nnet3 system
# (local/nnet3/run_tdnn.sh), you may want to run with --stage 14.

# This script is adapted from local/run_tdnn_7o.sh in Kaldi's SWBD
# The network structure is also known as factorized TDNN (TDNN-F)

# See danielpovey.com/files/2018_interspeech_tdnnf.pdf
# "Semi-Orthogonal Low-Rank Matrix Factorization for Deep Neural Networks", Daniel Povey, Gaofeng Cheng, Yiming Wang, Ke Li, Hainan Xu, Mahsa Yarmohamadi, Sanjeev Khudanpur, Proceedings of Interspeech 2018

set -e -o pipefail

# First the options that are passed through to run_ivector_common.sh
# (some of which are also used in this script directly).
stage=0
nj=28
decode_nj=16
min_seg_len=1.55
xent_regularize=0.1
train_set=train_cleaned
gmm=tri4_cleaned  # the gmm for the target data
num_threads_ubm=32
nnet3_affix=_cleaned  # cleanup affix for nnet3 and chain dirs, e.g. _cleaned

# The rest are configs specific to this script.  Most of the parameters
# are just hardcoded at this level, in the commands below.
train_stage=-10
tree_affix=  # affix for tree directory, e.g. "a" or "b", in case we change the configuration.
decode_affix= #if you want to to change decoding parameters and decode into a different directory
#tdnn_affix=1f
common_egs_dir=  # you can set this to use previously dumped egs.

# how many GPU jobs to start in parallel
num_jobs_initial=1
num_jobs_final=1

# these variables influnce training outcomes
num_chunk_per_minibatch=128
leaky_hmm_coefficient=0.1
l2_regularize=0.0
proportional_shrink=20
#num_hidden=1024
num_epochs=6
frames_per_eg=150,110,100
dropout_schedule='0,0@0.20,0.5@0.50,0'

tdnn_affix=7o_std #${num_hidden}  #affix for TDNN directory, e.g. "a" or "b", in case we change the configuration.

# End configuration section.
echo "$0 $@"  # Print the command line for logging

. ./cmd.sh
. ./path.sh
. ./utils/parse_options.sh


if ! cuda-compiled; then
  cat <<EOF && exit 1
This script is intended to be used with GPUs but you have not compiled Kaldi with CUDA
If you want to use GPUs (and have them), go to src/, and configure and make on a machine
where "nvcc" is installed.
EOF
fi

local/run_ivector_common.sh --stage $stage \
                                  --nj $nj \
                                  --min-seg-len $min_seg_len \
                                  --train-set $train_set \
                                  --gmm $gmm \
                                  --num-threads-ubm $num_threads_ubm \
                                  --nnet3-affix "$nnet3_affix"


gmm_dir=exp/$gmm
ali_dir=exp/${gmm}_ali_${train_set}_sp_comb
tree_dir=exp/chain${nnet3_affix}/tree_bi${tree_affix}
lat_dir=exp/chain${nnet3_affix}/${gmm}_${train_set}_sp_comb_lats
dir=exp/chain${nnet3_affix}/tdnn${tdnn_affix}_sp_bi
train_data_dir=data/${train_set}_sp_hires_comb
lores_train_data_dir=data/${train_set}_sp_comb
train_ivector_dir=exp/nnet3${nnet3_affix}/ivectors_${train_set}_sp_hires_comb


for f in $gmm_dir/final.mdl $train_data_dir/feats.scp $train_ivector_dir/ivector_online.scp \
    $lores_train_data_dir/feats.scp $ali_dir/ali.1.gz $gmm_dir/final.mdl; do
  [ ! -f $f ] && echo "$0: expected file $f to exist" && exit 1
done

if [ $stage -le 14 ]; then
  echo "$0: creating lang directory with one state per phone."
  # Create a version of the lang/ directory that has one state per phone in the
  # topo file. [note, it really has two states.. the first one is only repeated
  # once, the second one has zero or more repeats.]
  if [ -d data/lang_chain ]; then
    if [ data/lang_chain/L.fst -nt data/lang_test_pron/L.fst ]; then
      echo "$0: data/lang_chain already exists, not overwriting it; continuing"
    else
      echo "$0: data/lang_chain already exists and seems to be older than data/lang..."
      echo " ... not sure what to do.  Exiting."
      exit 1;
    fi
  else
    cp -r data/lang_test_pron data/lang_chain
    silphonelist=$(cat data/lang_chain/phones/silence.csl) || exit 1;
    nonsilphonelist=$(cat data/lang_chain/phones/nonsilence.csl) || exit 1;
    # Use our special topology... note that later on may have to tune this
    # topology.
    steps/nnet3/chain/gen_topo.py $nonsilphonelist $silphonelist >data/lang_chain/topo
  fi
fi

if [ $stage -le 15 ]; then
  # Get the alignments as lattices (gives the chain training more freedom).
  # use the same num-jobs as the alignments
  steps/align_fmllr_lats.sh --nj $nj --cmd "$train_cmd" ${lores_train_data_dir} \
    data/lang $gmm_dir $lat_dir
  rm $lat_dir/fsts.*.gz # save space
fi

if [ $stage -le 16 ]; then
  # Build a tree using our new topology.  We know we have alignments for the
  # speed-perturbed data (local/nnet3/run_ivector_common.sh made them), so use
  # those.
  if [ -f $tree_dir/final.mdl ]; then
    echo "$0: $tree_dir/final.mdl already exists, refusing to overwrite it."
    exit 1;
  fi
  steps/nnet3/chain/build_tree.sh --frame-subsampling-factor 3 \
      --context-opts "--context-width=2 --central-position=1" \
      --cmd "$train_cmd" 4000 ${lores_train_data_dir} data/lang_chain $ali_dir $tree_dir
fi

if [ $stage -le 17 ]; then
  mkdir -p $dir

  echo "$0: creating neural net configs using the xconfig parser";

  num_targets=$(tree-info $tree_dir/tree |grep num-pdfs|awk '{print $2}')
  learning_rate_factor=$(echo "print 0.5/$xent_regularize" | python)
  opts="l2-regularize=0.004 dropout-proportion=0.0 dropout-per-dim=true dropout-per-dim-continuous=true"
  linear_opts="orthonormal-constraint=-1.0 l2-regularize=0.004"
  output_opts="l2-regularize=0.002"

  mkdir -p $dir/configs

  cat <<EOF > $dir/configs/network.xconfig
  input dim=100 name=ivector
  input dim=40 name=input
  # please note that it is important to have input layer with the name=input
  # as the layer immediately preceding the fixed-affine-layer to enable
  # the use of short notation for the descriptor
  fixed-affine-layer name=lda input=Append(-1,0,1,ReplaceIndex(ivector, t, 0)) affine-transform-file=$dir/configs/lda.mat
  # the first splicing is moved before the lda layer, so no splicing here
  relu-batchnorm-dropout-layer name=tdnn1 $opts dim=1280
  linear-component name=tdnn2l0 dim=256 $linear_opts input=Append(-1,0)
  linear-component name=tdnn2l dim=256 $linear_opts input=Append(-1,0)
  relu-batchnorm-dropout-layer name=tdnn2 $opts input=Append(0,1) dim=1280
  linear-component name=tdnn3l dim=256 $linear_opts input=Append(-1,0)
  relu-batchnorm-dropout-layer name=tdnn3 $opts dim=1280 input=Append(0,1)
  linear-component name=tdnn4l0 dim=256 $linear_opts input=Append(-1,0)
  linear-component name=tdnn4l dim=256 $linear_opts input=Append(0,1)
  relu-batchnorm-dropout-layer name=tdnn4 $opts input=Append(0,1) dim=1280
  linear-component name=tdnn5l dim=256 $linear_opts
  relu-batchnorm-dropout-layer name=tdnn5 $opts dim=1280 input=Append(0, tdnn3l)
  linear-component name=tdnn6l0 dim=256 $linear_opts input=Append(-3,0)
  linear-component name=tdnn6l dim=256 $linear_opts input=Append(-3,0)
  relu-batchnorm-dropout-layer name=tdnn6 $opts input=Append(0,3) dim=1536
  linear-component name=tdnn7l0 dim=256 $linear_opts input=Append(-3,0)
  linear-component name=tdnn7l dim=256 $linear_opts input=Append(0,3)
  relu-batchnorm-dropout-layer name=tdnn7 $opts input=Append(0,3,tdnn6l,tdnn4l,tdnn2l) dim=1280
  linear-component name=tdnn8l0 dim=256 $linear_opts input=Append(-3,0)
  linear-component name=tdnn8l dim=256 $linear_opts input=Append(0,3)
  relu-batchnorm-dropout-layer name=tdnn8 $opts input=Append(0,3) dim=1536
  linear-component name=tdnn9l0 dim=256 $linear_opts input=Append(-3,0)
  linear-component name=tdnn9l dim=256 $linear_opts input=Append(-3,0)
  relu-batchnorm-dropout-layer name=tdnn9 $opts input=Append(0,3,tdnn8l,tdnn6l,tdnn5l) dim=1280
  linear-component name=tdnn10l0 dim=256 $linear_opts input=Append(-3,0)
  linear-component name=tdnn10l dim=256 $linear_opts input=Append(0,3)
  relu-batchnorm-dropout-layer name=tdnn10 $opts input=Append(0,3) dim=1536
  linear-component name=tdnn11l0 dim=256 $linear_opts input=Append(-3,0)
  linear-component name=tdnn11l dim=256 $linear_opts input=Append(-3,0)
  relu-batchnorm-dropout-layer name=tdnn11 $opts input=Append(0,3,tdnn10l,tdnn9l,tdnn7l) dim=1280
  linear-component name=prefinal-l dim=256 $linear_opts
  relu-batchnorm-layer name=prefinal-chain input=prefinal-l $opts dim=1536
  linear-component name=prefinal-chain-l dim=256 $linear_opts
  batchnorm-component name=prefinal-chain-batchnorm
  output-layer name=output include-log-softmax=false dim=$num_targets $output_opts
  relu-batchnorm-layer name=prefinal-xent input=prefinal-l $opts dim=1536
  linear-component name=prefinal-xent-l dim=256 $linear_opts
  batchnorm-component name=prefinal-xent-batchnorm
  output-layer name=output-xent dim=$num_targets learning-rate-factor=$learning_rate_factor $output_opts
EOF
  steps/nnet3/xconfig_to_configs.py --xconfig-file $dir/configs/network.xconfig --config-dir $dir/configs/
fi
#  mkdir -p $dir/configs
#  cat <<EOF > $dir/configs/network.xconfig
#  input dim=100 name=ivector
#  input dim=40 name=input
#
#  # please note that it is important to have input layer with the name=input
#  # as the layer immediately preceding the fixed-affine-layer to enable
#  # the use of short notation for the descriptor
#  fixed-affine-layer name=lda input=Append(-1,0,1,ReplaceIndex(ivector, t, 0)) affine-transform-file=$dir/configs/lda.mat
#
#  # the first splicing is moved before the lda layer, so no splicing here
#  relu-batchnorm-layer name=tdnn1 dim=$num_hidden self-repair-scale=1.0e-04
#  relu-batchnorm-layer name=tdnn2 input=Append(-1,0,1) dim=$num_hidden
#  relu-batchnorm-layer name=tdnn3 input=Append(-1,0,1,2) dim=$num_hidden
#  relu-batchnorm-layer name=tdnn4 input=Append(-3,0,3) dim=$num_hidden
#  relu-batchnorm-layer name=tdnn5 input=Append(-3,0,3) dim=$num_hidden
#  relu-batchnorm-layer name=tdnn6 input=Append(-6,-3,0) dim=$num_hidden
#
#  ## adding the layers for chain branch
#  relu-batchnorm-layer name=prefinal-chain input=tdnn6 dim=$num_hidden target-rms=0.5
#  output-layer name=output include-log-softmax=false dim=$num_targets max-change=1.5
#
#  # adding the layers for xent branch
#  # This block prints the configs for a separate output that will be
#  # trained with a cross-entropy objective in the 'chain' models... this
#  # has the effect of regularizing the hidden parts of the model.  we use
#  # 0.5 / args.xent_regularize as the learning rate factor- the factor of
#  # 0.5 / args.xent_regularize is suitable as it means the xent
#  # final-layer learns at a rate independent of the regularization
#  # constant; and the 0.5 was tuned so as to make the relative progress
#  # similar in the xent and regular final layers.
#  relu-batchnorm-layer name=prefinal-xent input=tdnn6 dim=$num_hidden target-rms=0.5
#  output-layer name=output-xent dim=$num_targets learning-rate-factor=$learning_rate_factor max-change=1.5
#
#EOF
#  steps/nnet3/xconfig_to_configs.py --xconfig-file $dir/configs/network.xconfig --config-dir $dir/configs/
#
#fi

if [ $stage -le 18 ]; then
  if [[ $(hostname -f) == *.clsp.jhu.edu ]] && [ ! -d $dir/egs/storage ]; then
    utils/create_split_dir.pl \
     /export/b0{5,6,7,8}/$USER/kaldi-data/egs/ami-$(date +'%m_%d_%H_%M')/s5/$dir/egs/storage $dir/egs/storage
  fi

#    --trainer.optimization.proportional-shrink $proportional_shrink \

 steps/nnet3/chain/train.py --stage $train_stage \
    --cmd "$decode_cmd" \
    --feat.online-ivector-dir $train_ivector_dir \
    --feat.cmvn-opts "--norm-means=false --norm-vars=false" \
    --chain.xent-regularize $xent_regularize \
    --chain.leaky-hmm-coefficient $leaky_hmm_coefficient \
    --chain.l2-regularize $l2_regularize \
    --chain.apply-deriv-weights false \
    --chain.lm-opts="--num-extra-lm-states=2000" \
    --trainer.dropout-schedule $dropout_schedule \
    --trainer.add-option="--optimization.memory-compression-level=2" \
    --egs.dir "$common_egs_dir" \
    --egs.opts "--frames-overlap-per-eg 0" \
    --egs.chunk-width $frames_per_eg \
    --trainer.num-chunk-per-minibatch $num_chunk_per_minibatch \
    --trainer.frames-per-iter 1500000 \
    --trainer.num-epochs $num_epochs \
    --trainer.optimization.num-jobs-initial $num_jobs_initial \
    --trainer.optimization.num-jobs-final $num_jobs_final \
    --trainer.optimization.initial-effective-lrate 0.0005 \
    --trainer.optimization.final-effective-lrate 0.00005 \
    --trainer.max-param-change 2.0 \
    --cleanup.remove-egs true \
    --feat-dir $train_data_dir \
    --tree-dir $tree_dir \
    --lat-dir $lat_dir \
    --dir $dir #\
#    --egs.stage 100 \
#    --stage 1400
fi

if [ $stage -le 19 ]; then
  # Note: it might appear that this data/lang_chain directory is mismatched, and it is as
  # far as the 'topo' is concerned, but this script doesn't read the 'topo' from
  # the lang directory.
  utils/mkgraph.sh --self-loop-scale 1.0 data/lang_test_pron $dir $dir/graph${decode_affix}
fi

if [ $stage -le 20 ]; then
  rm $dir/.error 2>/dev/null || true
  for dset in dev test; do
      
      steps/nnet3/decode.sh --num-threads 4 --nj $decode_nj --cmd "$decode_cmd" \
          --acwt 1.0 --post-decode-acwt 10.0 \
          --online-ivector-dir exp/nnet3${nnet3_affix}/ivectors_${dset}_hires \
          --scoring-opts "--min-lmwt 5 " \
         $dir/graph${decode_affix} data/${dset}_hires $dir/decode_${dset}${decode_affix} || exit 1;
    #  steps/lmrescore_const_arpa.sh --cmd "$decode_cmd" data/lang data/lang_rescore \
    #    data/${dset}_hires ${dir}/decode_${dset} ${dir}/decode_${dset}_rescore || exit 1
  done
  if [ -f $dir/.error ]; then
    echo "$0: something went wrong in decoding"
    exit 1
  fi
fi
exit 0
