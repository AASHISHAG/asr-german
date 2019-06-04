#!/bin/bash

# This script is adapted from swbd Kaldi run.sh (https://github.com/kaldi-asr/kaldi
# Copyright 2019 Kaldi developers (see: https://github.com/kaldi-asr/kaldi/blob/master/COPYING)

[ ! -L "steps" ] && ln -s ../../wsj/s5/steps
[ ! -L "utils" ] && ln -s ../../wsj/s5/utils
[ ! -L "rnnlm" ] && ln -s ../../../scripts/rnnlm/

python3 local/prepare_dir_structure.py

. utils/parse_options.sh

if [ -f cmd.sh ]; then
      . cmd.sh; else
         echo "missing cmd.sh"; exit 1;
fi

if [ ! -d data/wav/german-speechdata-package-v2 ]
  then
      wget --directory-prefix=data/wav/ http://speech.tools/kaldi_tuda_de/german-speechdata-package-v2.tar.gz
      cd data/wav/
      tar xvfz german-speechdata-package-v2.tar.gz
      cd ../../
fi

if [ ! -f $data/local/g2p_300k4/de_g2p_model-6 ]
  then
      mkdir -p ${data/local/g2p_300k4}/

      $sequitur_g2p -e utf8 --train $train_file --devel 3% --write-model ${g2p_model}-1
      $sequitur_g2p -e utf8 --model ${g2p_model}-1 --ramp-up --train $train_file --devel 3% --write-model ${g2p_model}-2
      $sequitur_g2p -e utf8 --model ${g2p_model}-2 --ramp-up --train $train_file --devel 3% --write-model ${g2p_model}-3
      $sequitur_g2p -e utf8 --model ${g2p_model}-3 --ramp-up --train $train_file --devel 3% --write-model ${g2p_model}-4
      $sequitur_g2p -e utf8 --model ${g2p_model}-4 --ramp-up --train $train_file --devel 3% --write-model ${g2p_model}-5
      $sequitur_g2p -e utf8 --model ${g2p_model}-5 --ramp-up --train $train_file --devel 3% --write-model ${g2p_model}-6
  else
      echo "G2P model file already exists, not recreating it."
fi
