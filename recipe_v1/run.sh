#!/bin/bash

# This script is adapted from swbd Kaldi run.sh (https://github.com/kaldi-asr/kaldi
# Copyright 2019 Kaldi developers (see: https://github.com/kaldi-asr/kaldi/blob/master/COPYING)

[ ! -L "steps" ] && ln -s ./steps
[ ! -L "utils" ] && ln -s ./utils
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

wget --directory-prefix=data/lexicon/ https://raw.githubusercontent.com/marytts/marytts-lexicon-de/master/modules/de/lexicon/de.txt
echo "data/lexicon/de.txt">> data/lexicon_ids.txt

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