#!/bin/bash

# This script is adapted from swbd Kaldi run.sh (https://github.com/kaldi-asr/kaldi
# Copyright 2019 Kaldi developers (see: https://github.com/kaldi-asr/kaldi/blob/master/COPYING)

# Refer dependencies from Wall Street Journal Project (Steps and Utils)
[ ! -L "steps" ] && ln -s ../../wsj/steps
[ ! -L "utils" ] && ln -s ../../wsj/utils
[ ! -L "rnnlm" ] && ln -s ../../../scripts/rnnlm/

. utils/parse_options.sh
. path.sh;

utf8()
{
    iconv -f ISO-8859-1 -t UTF-8 $1 > $1.tmp
    mv $1.tmp $1
}

export LC_ALL=C
export LANG=C
export LANGUAGE=C

extra_words_file=local/extra_words.txt
extra_words_file=local/filtered_300k_vocab_de_wiki.txt
dict_suffix=_300k4
dict_dir=data/local/dict${dict_suffix}
local_lang_dir=data/local/lang${dict_suffix}
lang_dir=data/lang${dict_suffix}
lang_dir_nosp=${lang_dir}_nosp${dict_suffix}
format_lang_out_dir=${lang_dir}_test
g2p_dir=data/local/g2p${dict_suffix}
lm_dir=data/local/lm${dict_suffix}
arpa_lm=${lm_dir}/4gram-mincount/lm_pr10.0.gz

if [ -f cmd.sh ]; then
      . cmd.sh; else
         echo "missing cmd.sh"; exit 1;
fi

mfccdir=mfcc

utf8()
{
    iconv -f ISO-8859-1 -t UTF-8 $1 > $1.tmp
    mv $1.tmp $1
}

python3 local/prepare_dir_structure.py

wget --directory-prefix=data/wav/ http://speech.tools/kaldi_tuda_de/german-speechdata-package-v2.tar.gz
cd data/wav/
tar xvfz german-speechdata-package-v2.tar.gz
cd ../../

mkdir -p data/wav/swc/
wget --directory-prefix=data/wav/swc/ https://www2.informatik.uni-hamburg.de/nats/pub/SWC/SWC_German.tar
cd data/wav/swc/
tar xvf SWC_German.tar
cd ../../../

wget --directory-prefix=data/ http://speech.tools/kaldi_tuda_de/swc_train_v2.tar.gz
cd data/
tar xvfz swc_train_v2.tar.gz
cd ../

mkdir -p data/wav/m_ailabs/
wget --directory-prefix=data/wav/m_ailabs/ http://speech.tools/kaldi_tuda_de/m-ailabs.bayern.de_DE.tgz
cd data/wav/m_ailabs/
tar xvfz m-ailabs.bayern.de_DE.tgz
cd ../../../

python3 local/prepare_m-ailabs_data.py

RAWDATA=data/wav/german-speechdata-package-v2

FILTERBYNAME="*.xml"

python3 local/move_files_to_skip.py data/wav/german-speechdata-package-v2/train/

find $RAWDATA/*/$FILTERBYNAME -type f > data/waveIDs.txt

python3 local/data_prepare.py -f data/waveIDs.txt --separate-mic-dirs

local/get_utt2dur.sh data/tuda_train
mv data/tuda_train data/train

wget --directory-prefix=data/lexicon/https://raw.githubusercontent.com/marytts/marytts-lexicon-de/master/modules/de/lexicon/de.txt

mkdir -p ${dict_dir}/
python3 local/build_big_lexicon.py -f data/lexicon_ids.txt -e data/local/combined.dict --export-dir ${dict_dir}/
python3 local/export_lexicon.py -f data/local/combined.dict -o ${dict_dir}/_lexiconp.txt 

g2p_model=${g2p_dir}/de_g2p_model
final_g2p_model=${g2p_model}-6

mkdir -p ${g2p_dir}/

train_file=${g2p_dir}/lexicon.txt
        
cut -d" " -f 1,3- ${dict_dir}/_lexiconp.txt > $train_file
cut -d" " -f 1 ${dict_dir}/_lexiconp.txt > ${g2p_dir}/lexicon_wordlist.txt
  
mkdir -p ${g2p_dir}/

$sequitur_g2p -e utf8 --train $train_file --devel 3% --write-model ${g2p_model}-1
$sequitur_g2p -e utf8 --model ${g2p_model}-1 --ramp-up --train $train_file --devel 3% --write-model ${g2p_model}-2
$sequitur_g2p -e utf8 --model ${g2p_model}-2 --ramp-up --train $train_file --devel 3% --write-model ${g2p_model}-3
$sequitur_g2p -e utf8 --model ${g2p_model}-3 --ramp-up --train $train_file --devel 3% --write-model ${g2p_model}-4
$sequitur_g2p -e utf8 --model ${g2p_model}-4 --ramp-up --train $train_file --devel 3% --write-model ${g2p_model}-5
$sequitur_g2p -e utf8 --model ${g2p_model}-5 --ramp-up --train $train_file --devel 3% --write-model ${g2p_model}-6

cp data/tuda_train/text ${g2p_dir}/complete_text

cat data/swc_train/text >> ${g2p_dir}/complete_text
cat data/m_ailabs_train/text >> ${g2p_dir}/complete_text

gawk "{ printf(\"extra-word-%i %s\n\",NR,\$1) }" $extra_words_file | cat ${g2p_dir}/complete_text - > ${g2p_dir}/complete_text_new
mv ${g2p_dir}/complete_text_new ${g2p_dir}/complete_text

python3 local/find_oov.py -c ${g2p_dir}/complete_text -w ${g2p_dir}/lexicon_wordlist.txt -o ${g2p_dir}/oov.txt

$sequitur_g2p -e utf8 --model $final_g2p_model --apply ${g2p_dir}/oov.txt > ${dict_dir}/oov_lexicon.txt
cat ${dict_dir}/oov_lexicon.txt | gawk '{$1=$1" 1.0"; print }' > ${dict_dir}/_oov_lexiconp.txt
gawk 'NF>=3' ${dict_dir}/_oov_lexiconp.txt > ${dict_dir}/oov_lexiconp.txt
    
if [ -f path.sh ]; then
      . path.sh; else
         echo "missing path.sh"; exit 1;
fi

export LC_ALL=C
export LANG=C
export LANGUAGE=C

sort -u ${dict_dir}/_lexiconp.txt ${dict_dir}/oov_lexiconp.txt > ${dict_dir}/lexiconp.txt

rm ${dict_dir}/lexicon.txt

unixtime=$(date +%s)
mkdir -p ${lang_dir}/old_$unixtime/
mv ${lang_dir}/* ${lang_dir}/old_$unixtime/

utils/prepare_lang.sh ${dict_dir} "<UNK>" ${local_lang_dir} ${lang_dir}

mkdir -p ${lm_dir}/

wget --directory-prefix=${lm_dir}/ http://speech.tools/kaldi_tuda_de/German_sentences_8mil_filtered_maryfied.txt.gz
mv ${lm_dir}/German_sentences_8mil_filtered_maryfied.txt.gz ${lm_dir}/cleaned.gz

local/build_lm.sh --srcdir ${local_lang_dir} --dir ${lm_dir}
local/format_data.sh --arpa_lm $arpa_lm --lang_in_dir $lang_dir --lang_out_dir $format_lang_out_dir


rm data/swc_train/spk2utt
      
cat data/swc_train/segments | sort > data/swc_train/segments_sorted
cat data/swc_train/text | sort | gawk 'NF>=2' > data/swc_train/text_sorted
cat data/swc_train/utt2spk | sort > data/swc_train/utt2spk_sorted
cat data/swc_train/wav.scp | sort > data/swc_train/wav.scp_sorted

mv data/swc_train/wav.scp_sorted data/swc_train/wav.scp
mv data/swc_train/utt2spk_sorted data/swc_train/utt2spk
mv data/swc_train/text_sorted data/swc_train/text
mv data/swc_train/segments_sorted data/swc_train/segments

utils/utt2spk_to_spk2utt.pl data/swc_train/utt2spk > data/swc_train/spk2utt      

for x in swc_train tuda_train dev test; do
    utils/fix_data_dir.sh data/$x # some files fail to get mfcc for many reasons
    steps/make_mfcc.sh --cmd "$train_cmd" --nj $nJobs data/$x exp/make_mfcc/$x $mfccdir
    utils/fix_data_dir.sh data/$x # some files fail to get mfcc for many reasons
    steps/compute_cmvn_stats.sh data/$x exp/make_mfcc/$x $mfccdir
    utils/fix_data_dir.sh data/$x
done

combine_data.sh data/train data/tuda_train data/swc_train

for x in train dev test; do
    utils/fix_data_dir.sh data/$x # some files fail to get mfcc for many reasons
    steps/make_mfcc.sh --cmd "$train_cmd" --nj $nJobs data/$x exp/make_mfcc/$x $mfccdir
    utils/fix_data_dir.sh data/$x # some files fail to get mfcc for many reasons
    steps/compute_cmvn_stats.sh data/$x exp/make_mfcc/$x $mfccdir
    utils/fix_data_dir.sh data/$x
done

mv data/train data/train_without_mailabs 
x=m_ailabs_train
utils/fix_data_dir.sh data/$x # some files fail to get mfcc for many reasons
steps/make_mfcc.sh --cmd "$train_cmd" --nj $nJobs data/$x exp/make_mfcc/$x $mfccdir
utils/fix_data_dir.sh data/$x # some files fail to get mfcc for many reasons
steps/compute_cmvn_stats.sh data/$x exp/make_mfcc/$x $mfccdir
utils/fix_data_dir.sh data/$x

combine_data.sh data/train data/train_without_mailabs data/m_ailabs_train

utils/subset_data_dir.sh --first data/train 4000 data/train_dev # 5hr 6min
  
if [ -f data/train/segments ]; then
  n=$[`cat data/train/segments | wc -l` - 4000]
else
  n=$[`cat data/train/wav.scp | wc -l` - 4000]
fi
  
utils/subset_data_dir.sh --last data/train $n data/train_nodev

utils/subset_data_dir.sh --shortest data/train_nodev 150000 data/train_100kshort
utils/subset_data_dir.sh data/train_100kshort 50000 data/train_30kshort

utils/subset_data_dir.sh --first data/train_nodev 100000 data/train_100k

utils/data/remove_dup_utts.sh 1000 data/train_100k data/train_100k_nodup

utils/data/remove_dup_utts.sh 1000 data/train_nodev data/train_nodup

if [ ! -d ${lang_dir_nosp} ]; then 
  echo "Copying ${lang_dir} to ${lang_dir_nosp}..."
  cp -R ${lang_dir} ${lang_dir_nosp}
fi

steps/train_mono.sh --nj $nJobs --cmd "$train_cmd" \
                    data/train_30kshort ${lang_dir_nosp} exp/mono

steps/align_si.sh --nj $nJobs --cmd "$train_cmd" \
                data/train_100k_nodup ${lang_dir_nosp} exp/mono exp/mono_ali

steps/train_deltas.sh --cmd "$train_cmd" \
                    3200 30000 data/train_100k_nodup ${lang_dir_nosp} exp/mono_ali exp/tri1

graph_dir=exp/tri1/graph_nosp
$train_cmd $graph_dir/mkgraph.log \
           utils/mkgraph.sh ${lang_dir}_test exp/tri1 $graph_dir
    
for dset in dev test; do
    steps/decode_si.sh --nj $nDecodeJobs --cmd "$decode_cmd" --config conf/decode.config \
                   $graph_dir data/${dset} exp/tri1/decode_${dset}_nosp
done
    
steps/align_si.sh --nj $nJobs --cmd "$train_cmd" \
                  data/train_100k_nodup ${lang_dir_nosp} exp/tri1 exp/tri1_ali

steps/train_deltas.sh --cmd "$train_cmd" \
                      4000 70000 data/train_100k_nodup ${lang_dir_nosp} exp/tri1_ali exp/tri2

graph_dir=exp/tri2/graph_nosp
$train_cmd $graph_dir/mkgraph.log \
           utils/mkgraph.sh ${lang_dir}_test exp/tri2 $graph_dir

for dset in dev test; do
    steps/decode.sh --nj $nDecodeJobs --cmd "$decode_cmd" --config conf/decode.config \
                $graph_dir data/${dset} exp/tri2/decode_${dset}_nosp
done

steps/align_si.sh --nj $nJobs --cmd "$train_cmd" \
                  data/train_100k_nodup ${lang_dir_nosp} exp/tri2 exp/tri2_ali_100k_nodup

steps/align_si.sh --nj $nJobs --cmd "$train_cmd" \
                  data/train_nodup ${lang_dir_nosp} exp/tri2 exp/tri2_ali_nodup

steps/train_lda_mllt.sh --cmd "$train_cmd" \
                        6000 140000 data/train_nodup ${lang_dir_nosp} exp/tri2_ali_nodup exp/tri3

graph_dir=exp/tri3/graph_nosp
$train_cmd $graph_dir/mkgraph.log \
           utils/mkgraph.sh ${lang_dir}_test exp/tri3 $graph_dir

for dset in dev test; do
    steps/decode.sh --nj $nDecodeJobs --cmd "$decode_cmd" --config conf/decode.config \
                $graph_dir data/${dset} exp/tri3/decode_${dset}_nosp
done

steps/get_prons.sh --cmd "$train_cmd" data/train_nodup ${lang_dir_nosp} exp/tri3
utils/dict_dir_add_pronprobs.sh --max-normalize true \
                                ${dict_dir} exp/tri3/pron_counts_nowb.txt exp/tri3/sil_counts_nowb.txt \
                                exp/tri3/pron_bigram_counts_nowb.txt ${dict_dir}_pron

utils/prepare_lang.sh ${dict_dir}_pron "<UNK>" ${local_lang_dir} ${lang_dir}

./local/format_data.sh --arpa_lm $arpa_lm --lang_in_dir $lang_dir --lang_out_dir ${lang_dir}_test_pron

graph_dir=exp/tri3/graph_pron
$train_cmd $graph_dir/mkgraph.log \
           utils/mkgraph.sh ${lang_dir}_test_pron exp/tri3 $graph_dir
  
for dset in dev test; do
    steps/decode.sh --nj $nDecodeJobs --cmd "$decode_cmd" --config conf/decode.config \
                $graph_dir data/${dset} exp/tri3/decode_${dset}_pron
done

steps/align_fmllr.sh --nj $nJobs --cmd "$train_cmd" \
                     data/train ${lang_dir}_test_pron exp/tri3 exp/tri3_ali

steps/train_sat.sh  --cmd "$train_cmd" \
                    11500 200000 data/train ${lang_dir} exp/tri3_ali exp/tri4

graph_dir=exp/tri4/graph_pron
$train_cmd $graph_dir/mkgraph.log \
           utils/mkgraph.sh ${lang_dir}_test_pron exp/tri4 $graph_dir

for dset in dev test; do
    steps/decode_fmllr.sh --nj $nDecodeJobs --cmd "$decode_cmd" \
                    --config conf/decode.config \
                    $graph_dir data/${dset} exp/tri4/decode_${dset}_pron
done