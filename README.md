# Automatic Speech Recognition (ASR) - German

_This is my [Google Summer of Code 2019](https://summerofcode.withgoogle.com/projects/#5623384702976000) Project with the [Distributed Little Red Hen Lab](http://www.redhenlab.org/)._

This project aims to develop a working Speech to Text module for the Red Hen Lab’s current Audio processing pipeline. This system will be used to transcribe the Television news broadcast captured by Red Hen in Germany.

This Readme will be updated regularly to include information about the code and guidelines to use this software.

#### Contents

1. [Getting Started](#getting-started)
2. [Data-Preprocessing for Training](#data-preprocessing-for-training)
3. [Training](#training)
4. [Some Training Results](#some-training-results)
5. [Running code at Case HPC](#running-code-at-case-hpc)
6. [Acknowledgments](#acknowledgments)

## Getting Started

### Prerequisites

* **Libraries**:

	* [Automake](https://packages.ubuntu.com/xenial/automake)
	* [Autoconf](https://packages.ubuntu.com/xenial/autoconf)
	* [Sox](http://manpages.ubuntu.com/manpages/bionic/man1/sox.1.html)
	* [Python](https://www.python.org/)	
	* [Libtool](https://www.gnu.org/software/libtool/)	
	* [Gfortran](https://gcc.gnu.org/wiki/GFortran)	
	* [Libgstreamer](https://packages.debian.org/sid/libgstreamer1.0-0)	


* **Graphics Processing Unit (GPU)**:

	* [Cuda](https://developer.nvidia.com/cuda-zone)

* **SWIG**:

	* [Swig](https://github.com/swig/swig)
	
* **Grapheme-to-Phoneme**:

	* [Sequitur-G2P](https://github.com/sequitur-g2p/sequitur-g2p)

* **Kaldi**:

	* [Numpy](https://www.numpy.org/)
	* [Beautifulsoup4](https://pypi.org/project/beautifulsoup4/)
	* [LXml](https://pypi.org/project/lxml/)
	* [Requests](https://pypi.org/project/requests/)
	* [Tornado](https://www.tornadoweb.org/en/stable/)
	* [Kaldi Gstreamer Server](https://github.com/alumae/kaldi-gstreamer-server)

* **Singularity**:

	* [Singularity](https://singularity.lbl.gov/)
	
### Installation

* **Libraries**:
	
	```bash
	$ sudo apt-get update
	```
	
	**_NOTE_**:
	_The other important libraries are downloaded in the later steps._
	
* **Graphics Processing Unit (GPU)**:

    * _Ubuntu 16.04_
	
	
	
	```bash
	$ sudo apt-get install linux-headers-$(uname -r)
	$ wget https://developer.nvidia.com/compute/cuda/10.1/Prod/local_installers/cuda-repo-ubuntu1604-10-1-local-10.1.168-418.67_1.0-1_amd64.deb
	$ sudo dpkg -i cuda-repo-ubuntu1604-10-1-local-10.1.168-418.67_1.0-1_amd64.deb
	$ sudo apt-key add /var/cuda-repo-<version>/7fa2af80.pub
	$ sudo apt-key add /var/cuda-repo-10-1-local-10.1.168-418.67/7fa2af80.pub
	$ sudo apt-get update
	$ sudo apt-get install cuda
	```
	
	The above installation is for _Ubuntu 16.04_. Refer below links for other versions.
	
	* [_Cuda-Installation-Guide-Linux_](https://docs.nvidia.com/cuda/cuda-installation-guide-linux/index.html)
	
	* [_Cuda-Downloads_](https://developer.nvidia.com/cuda-downloads)

* **Kaldi**:
	
	**._STEP 1:_**

	```bash
	$ git clone https://github.com/kaldi-asr/kaldi.git kaldi-trunk --origin golden
	$ cd kaldi-trunk
	```
	
	**_STEP 2:_**

	```bash
	$ cd egs
	$ git clone https://github.com/AASHISHAG/asr-german.git
	$ cd asr-german
	$ xargs -a linux_requirements.txt sudo apt-get install
	$ pip3 install -r requirements.txt
	$ pip install -r requirements.txt
	```
	
	**_STEP 3:_**

	```bash
	$ cd ../../tools
	$ sudo extras/install_mkl.sh
	$ sudo extras/install_irstlm.sh
	$ sudo extras/check_dependencies.sh
	$ sudo make USE_THREAD=0 FC=gfortran -j `nproc`
	```
	
	**_IGNORE ERROR/WARNINGS_**:
	1. _IRSTLM is not installed by default anymore. If you need IRSTLM Warning: use the script extras/install_irstlm.sh_
	2. _Please source the tools/extras/env.sh in your path.sh to enable it._
	
	**_STEP 4:_**

	```bash
	$ wget http://github.com/xianyi/OpenBLAS/archive/v0.2.18.tar.gz
	$ tar -xzvf v0.2.18.tar.gz
	$ cd OpenBLAS-0.2.18
	$ make BINARY=64 FC=gfortran USE_THREAD=0
	$ sudo mkdir /opt/openblas_st
	$ sudo make PREFIX=/opt/openblas_st install	
	```
	
	**_STEP 5:_**

	```bash
	$ cd ../../src
	$ sudo ./configure --use-cuda --cudatk-dir=/usr/local/cuda/ --cuda-arch=-arch=sm_70 --shared --static-math=yes --mathlib=OPENBLAS --openblas-root=/opt/openblas_st/
	$ sudo extras/install_irstlm.sh
	$ make -j clean depend `nproc`
	$ make -j `nproc`
	```

	**_STEP 6:_**

	```bash
	$ export KALDI_ROOT= <path to KALDI_ROOT>
	$ cd $KALDI_ROOT/tools/
	$ git clone https://github.com/alumae/gst-kaldi-nnet2-online
	$ cd gst-kaldi-nnet2-online/src
	$ make -j clean depend `nproc`
	$ make -j `nproc`
	```
	
	**_You can now test if the GST-Kaldi-NNET2-Online installation works:_**
	
	```bash
	$ GST_PLUGIN_PATH=$KALDI_ROOT/tools/gst-kaldi-nnet2-online/src gst-inspect-1.0 kaldinnet2onlinedecoder
	```
	
	**_NOTE_**:
	The entire process can take **_4-5 hours_**, depending on the server configurations.
	
* **Swig**:	

    SWIG is a compiler that integrates C and C++ with languages including Perl, Python, Tcl, Ruby, PHP, Java, C#, D, Go, Lua, Octave, R, Scheme (Guile, MzScheme/Racket), Scilab, Ocaml. SWIG can also export its parse tree into XML.
	
	```bash
	$ wget https://netix.dl.sourceforge.net/project/swig/swig/swig-4.0.0/swig-4.0.0.tar.gz
	$ chmod 777 swig-4.0.0.tar.gz
	$ tar -xzvf swig-4.0.0.tar.gz
	$ cd swig-4.0.0/
	$ sudo ./configure --prefix=/home/swig-4.0.0
	$ sudo make -j `nproc`
	$ sudo make install
	$ sudo vim /etc/profile
	$ export SWIG_PATH=/home/swig-4.0.0
	$ export SWIG_PATH=/home/swig-4.0.0/bin
	$ export PATH=$SWIG_PATH:$PATH
	$ source /etc/profile
	$ swig -version
	```
	
* **Sequitur-G2P**:

	Sequitur G2P is a trainable data-driven Grapheme-to-Phoneme converter.
	
	```bash
	$ git clone https://github.com/sequitur-g2p/sequitur-g2p.git
	$ pip3 install git+https://github.com/sequitur-g2p/sequitur-g2p@master
	$ make -j `nproc`
	```
	
	**_NOTE_**:
	_Change Sequitur G2P path in $KALDI_ROOT/egs/asr-german/recipe_v2/cmd.sh_

* **Kaldi Gstreamer Server**:
	
	[Kaldi Gstreamer Server](https://github.com/alumae/kaldi-gstreamer-server) is a real-time full-duplex speech recognition server, based on the Kaldi toolkit and the GStreamer framework and implemented in Python.
	
	```bash
	$ cd $KALDI_ROOT/tools/
	$ git clone https://github.com/alumae/kaldi-gstreamer-server
	$ cd kaldi-gstreamer-server
	$ cp ../../egs/asr-german/kaldi-de.yaml .
	```
	**_NOTE:_** Specify the path of _final.mdl_, _mfcc.conf_, _HCLG.fst_ and _words.txt_ in _kaldi-de.yaml_ (after training).
	
	In general, these would be at the following path:
	
	_./exp/nnet3_cleaned/tri5/final.mdl_
	
	_./conf/mfcc.conf_
	
	_./exp/chain_cleaned/tdnn1f_2048_sp_bi/graph/HCLG.fst_
	
	_./exp/chain_cleaned/tdnn1f_2048_sp_bi/graph/words.txt_

	
## Data-Preprocessing for Training
	
The [official Kaldi's documentation](https://kaldi-asr.org/doc/data_prep.html) is the basis of a lot of this section. The pipeline can easliy be extended for new data. The data should be placed at the following path.
	
``` bash
$KALDI_ROOT/egs/asr-german/recipe_v2/data/wav
```
	
The respective scripts for data preprocessing can be added at [_run.sh_](recipe_v2/run.sh#L47).

Each data clip should contain information regarding the specifics of the audio files, transcripts, and speakers. Specifically, it will contain the following files:

 - text
 
   The text file is essentially the utterance-by-utterance transcript of the corpus. This is a text file with the following format:
	
   ``` bash
   utt_id WORD1 WORD2 WORD3 WORD4 …
   ```
   
   utt_id = utterance ID

   Example text file:

   ``` bash
   0000241_0000659_227982-228681 Schon neunzehn Hundert neunundvierzig hatte Thomas Mann anlässlich der Feiern zu Goethes zwei Hundert Geburtstag
   0000241_0000659_228675-228930 Deutschland einen Besuch abgestattet
   0000241_0000659_228959-229629 zwar in Frankfurt am Main wie auch in Weimar was von der Öffentlichkeit misstrauisch beäugt
    …
   0000241_0000659_229657-229987 von Mann jedoch mit dem Satz kommentiert wurde
   0000241_0000659_230044-230222 Ich kenne keine Zonen
   ```

 - segments
 - wav.scp
 - utt2spk
 - spk2utt

**_text_**
**_segments_**
**_wav.scp_**
**_utt2spk_**
**_spk2utt_**
	
## Training

* Run

	``` bash
	$ cd kaldi/egs/asr-german/recipe_v2
	$ ./run.sh
	```
	
**_NOTE:_** _The training would take a couple of days depending on the server configurations. It is recommended to run it in the background_.

## Some Training Results
Here are some of the results I obtained after training the model. The script [_recipe_v2/show_results.sh_](./recipe_v2/show_results.sh) was used to get these results. These results are based on _best_wer_ file generated by Kaldi.

**_Word Error Rate_ vs _Training Stages_**
<p align="center"><img src="./images/training_graph.png" width='54%' height='60%'></p>

**Percentage of _Deletion_, _Insertion_ and _Subsitution Error_ across different Training Stages**
<img align = "left" src="./images/error_graph-1.png" width='43%' height='45%'> <img float ="right" src="./images/error_graph-2.png" width='44%' height='45%'>

``` bash
%WER 58.10 [ 38790 / 66768, 1903 ins, 16466 del, 20421 sub ] [PARTIAL] exp//tri1/decode_dev_nosp/wer_10_0.0
%WER 61.21 [ 42600 / 69600, 1981 ins, 18961 del, 21658 sub ] [PARTIAL] exp//tri1/decode_test_nosp/wer_10_0.0
%WER 57.75 [ 38560 / 66768, 1614 ins, 18899 del, 18047 sub ] [PARTIAL] exp//tri2/decode_dev_nosp/wer_10_0.0
%WER 59.67 [ 41528 / 69600, 2130 ins, 18606 del, 20792 sub ] [PARTIAL] exp//tri2/decode_test_nosp/wer_9_0.0
%WER 28.85 [ 19261 / 66768, 3215 ins, 2902 del, 13144 sub ] [PARTIAL] exp//tri3/decode_dev_nosp/wer_14_0.0
%WER 28.08 [ 18750 / 66768, 3345 ins, 2516 del, 12889 sub ] [PARTIAL] exp//tri3/decode_dev_pron/wer_13_0.5
%WER 29.56 [ 20572 / 69600, 3568 ins, 2894 del, 14110 sub ] [PARTIAL] exp//tri3/decode_test_nosp/wer_13_0.0
%WER 29.14 [ 20279 / 69600, 3557 ins, 2696 del, 14026 sub ] [PARTIAL] exp//tri3/decode_test_pron/wer_13_0.5
%WER 23.44 [ 15653 / 66768, 3164 ins, 1976 del, 10513 sub ] [PARTIAL] exp//tri4_cleaned/decode_dev/wer_14_0.5
%WER 31.36 [ 20941 / 66768, 3578 ins, 2911 del, 14452 sub ] [PARTIAL] exp//tri4_cleaned/decode_dev.si/wer_13_0.5
%WER 24.86 [ 17305 / 69600, 3544 ins, 1996 del, 11765 sub ] [PARTIAL] exp//tri4_cleaned/decode_test/wer_13_0.5
%WER 31.90 [ 22202 / 69600, 3858 ins, 2984 del, 15360 sub ] [PARTIAL] exp//tri4_cleaned/decode_test.si/wer_13_0.5
%WER 24.08 [ 16075 / 66768, 3463 ins, 1819 del, 10793 sub ] [PARTIAL] exp//tri4/decode_dev_pron/wer_14_0.5
%WER 35.20 [ 23504 / 66768, 4244 ins, 3034 del, 16226 sub ] [PARTIAL] exp//tri4/decode_dev_pron.si/wer_14_0.5
%WER 25.50 [ 17745 / 69600, 3879 ins, 1855 del, 12011 sub ] [PARTIAL] exp//tri4/decode_test_pron/wer_13_0.5
%WER 35.44 [ 24668 / 69600, 4759 ins, 2898 del, 17011 sub ] [PARTIAL] exp//tri4/decode_test_pron.si/wer_13_0.5
%WER 14.61 [ 9758 / 66768, 2517 ins, 884 del, 6357 sub ] [PARTIAL] exp//chain_cleaned/tdnn1f_2048_sp_bi/decode_dev/wer_12_1.0
%WER 15.62 [ 10871 / 69600, 2746 ins, 865 del, 7260 sub ] [PARTIAL] exp//chain_cleaned/tdnn1f_2048_sp_bi/decode_test/wer_11_1.0
```

**_Some Audio Clips and Results_**

**[DE_01](https://aashishag.github.io/others/de_1.wav)**
``` bash
$ Actual: Gerrit erinnerte sich daran dass er einst einen Eid geschworen hatte
$ Output: Garrett erinnerte sich daran dass er einst einen Eid geschworen hatte
```

**[DE_02](https://aashishag.github.io/others/de_2.wav)**
``` bash
$ Actual: Wenn man schnell fährt ist man von Emden nach Landshut nicht lange unterwegs
$ Output: Weil man schnell fährt ist man von Emden nach Landshut nicht lange unterwegs
```

**[DE_03](https://aashishag.github.io/others/de_3.wav)**
``` bash
$ Actual: Valentin hat das Handtuch geworfen
$ Output: Valentin hat das Handtuch geworfen
```

**[DE_04](https://aashishag.github.io/others/de_4.wav)**
``` bash
$ Actual: Auf das was jetzt kommt habe ich nämlich absolut keinen Bock
$ Output: Auf das was jetzt kommt habe ich nämlich absolut keinen Bock
```

**[DE_05](https://aashishag.github.io/others/de_5.wav)**
``` bash
$ Actual: Ich könnte eine Mitfahrgelegenheit nach Schweinfurt anbieten
$ Output: Ich könnte eine Mitfahrgelegenheit nach Schweinfurt anbieten
```

**[DE_06](https://aashishag.github.io/others/de_6.wav)**
``` bash
$ Actual: Man sollte den Länderfinanzausgleich durch einen Bundesligasoli ersetzen
$ Output: Man sollte den Länderfinanzausgleich durch ein Bundesliga Soli ersetzen
```

**[DE_07](https://aashishag.github.io/others/de_7.wav)**
``` bash
$ Actual: Von Salzburg ist es doch nicht weit bis zum Chiemsee
$ Output: Von Salzburg ist es doch nicht weit Bistum Chiemsee
```

**[DE_08](https://aashishag.github.io/others/de_8.wav)**
``` bash
$ Actual: Selbst für den erfahrensten Chirurgen ist der Tumor eine knifflige Herausforderung
$ Output: Selbst für den erfahrensten Chirurgen ist der Tumor eine knifflige raus Federung
```

**[DE_09](https://aashishag.github.io/others/de_9.wav)**
``` bash
$ Actual: Folgende Lektüre kann ich ihnen zum Thema Kognitionspsychologie empfehlen
$ Output: Folgende Lektüre kann ich ihn zum Thema Kognitionspsychologie empfehlen
``` 

**[DE_10](https://aashishag.github.io/others/de_10.wav)**
``` bash
$ Actual: Warum werden da keine strafrechtlichen Konsequenzen gezogen
$ Output: Warum werden da keine strafrechtlichen Konsequenzen gezogen
```

## Running code at Case HPC

### Prerequisites

* Copy project's code in your directory.

	``` bash
	$ cp -r /mnt/rds/redhen/gallina/home/axa1142/ ./new-directory
	```
	
### Running the code
	
* Run the server (_kaldi-gstreamer-server_)
	
	``` bash
	$ ./run-server.sh
	```
	
* Run the worker (_kaldi-gstreamer-server_)
	
	``` bash
	$ ./run-worker.sh
	```
	
* Transcribe an audio clip (_kaldi-gstreamer-server_)
	
	``` bash
	$ ./run-model.sh path_to_audio
	```
	
* Transcribe Red Hen News dataset
	
	``` bash
	$ ./kaldi_de.slurm specify the number of days from the current date the model should transcribe
	```

	**_EXAMPLE:_** 
	
	./kaldi_de.slurm (_if model should transcribe today's news_)
	
	./kaldi_de.slurm 1 (_if model should transcribe yesterdays news_)
	
	./kaldi_de.slurm 2 (_if model should transcribe day before yesterdays news_)
	
### Results of Red Hen News Dataset

* This is a small excerpt from the Red Hen News Dataset. The MP4 files are programmatically converted to WAV and fed to Kaldi-Gstreamer-Server. The model output, i.e., the transcripts are further formatted to adopt [Red Hen's Data Format](https://sites.google.com/site/distributedlittleredhen/home/the-cognitive-core-research-topics-in-red-hen/red-hen-data-format#TOC-Audio-Pipeline-Tags).
	
	``` bash	
	TOP|20190812180001|2019-08-12_1800_DE_DasErste_Tagesschau
	COL|Communication Studies Archive, UCLA
	UID|3ef55370-bd2d-11e9-95d1-b78b1645001f
	DUR|00:14:54
	VID|720x576|640x512
	SRC|Osnabruck, Germany
	CMT|Evening news
	CC1|DEU 150
	ASR_01|DE
	20190812180010.000|20190812180013.760|CC1|Hier ist das Erste Deutsche Fernsehen mit der tagesschau.
	ASR_01|2019-08-15 08:34|Source_Program=Kaldi,infer.sh|Source_Person=Aashish Agarwal|Codebook=Deutsch Speech to Text
	20190812180014.280|20190812180024.280|ASR_01|So ist es die erste deutsche Fernsehen mit der Tagesschau. Heute im Studio Jan Hofer Nama der Damen und Herren ich begrüße sie zwei Tage. Bundesumweltministerin Schultze will die Hersteller von wegwerfen Artikeln künftig an den Kosten für die Müllbeseitigung beteiligen die es für die Politiker werden stellt ihre Pläne heute in Berlin vor Die sprach von einer regelrechten Müll Flut in manchen Städten Ziel sei eine finanzielle Entlastung der Kommunen und ein Umdenken in der Gesellschaft betroffen werden. <UNK> anderem Firmen sein die Verpackungen Getränke Becher Plastiktüten und Zigaretten Filter produzieren. Alltag auf deutschen Straßen. Reste der wegwerfen Gesellschaft. Für die Aufräumarbeiten Zahlen Städte und Gemeinden. Die Bundesumweltministerin will die Kommunen entlasten mit Geld das sie bei den Herstellern der wegwerfen Artikel eintreiben möchte. Heißt das Sie müssen für das Einsammeln dieser Produkte zahlen sie müssen sich anteilsmäßig an den Kosten für das Aufstellen von Abfall Behältern Beteiligungen ebenso müssen sich diese Hersteller an den Kosten für die Entsorgung beziehungsweise das Recycling beteiligen damit setzt wenn ihr Schulz für eine EU Richtlinie. Der Koalitionspartner aber sorgt das ginge auch anders ohne eine Zusatzbelastungen der Verpackungsindustrie
	END|20190812181455|2019-08-12_1800_DE_DasErste_Tagesschau
	```

## Acknowledgments
* [Google Summer of Code 2019](https://summerofcode.withgoogle.com/)
* [Red Hen Lab](http://www.redhenlab.org/)
* [Kaldi](http://www.kaldi-asr.org)
* [Kaldi Help Group](https://groups.google.com/forum/#!forum/kaldi-help)
* [Singularity Help Group](https://groups.google.com/a/lbl.gov/forum/#!forum/singularity)