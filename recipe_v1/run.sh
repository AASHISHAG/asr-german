#!/bin/bash

[ ! -L "steps" ] && ln -s ../../wsj/s5/steps
[ ! -L "utils" ] && ln -s ../../wsj/s5/utils

python3 local/prepare_dir_structure.py

  if [ ! -d data/wav/german-speechdata-package-v2 ]
  then
      wget --directory-prefix=data/wav/ http://speech.tools/kaldi_tuda_de/german-speechdata-package-v2.tar.gz
      cd data/wav/
      tar xvfz german-speechdata-package-v2.tar.gz
      cd ../../
  fi
