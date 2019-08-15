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

	* [Git Large File Storage](https://git-lfs.github.com/)
	* [Zlib1g-dev](https://packages.debian.org/stretch/zlib1g-dev)
	* [Automake](https://packages.ubuntu.com/search?keywords=automake)
	* [Autoconf](https://packages.ubuntu.com/search?keywords=autoconf)
	* [Unzip](https://linux.die.net/man/1/unzip)
	* [Sox](http://manpages.ubuntu.com/manpages/bionic/man1/sox.1.html)
	* [Subversion](https://help.ubuntu.com/lts/serverguide/subversion.html)
	* [Python](https://www.python.org/)	
	* [Libpcre3](https://packages.debian.org/search?keywords=libpcre3/)

* **Graphics Processing Unit (GPU)**:

	* [Cuda](https://developer.nvidia.com/cuda-zone)

* **SWIG**:

	* [Swig](http://www.swig.org/)
	
* **Grapheme-to-Phoneme**:

	* [Sequitur-G2P](https://github.com/sequitur-g2p/sequitur-g2p)

* **Kaldi**:

	* [Numpy](https://www.numpy.org/)
	* [Beautifulsoup4](https://pypi.org/project/beautifulsoup4/)
	* [LXml](https://pypi.org/project/lxml/)
	* [Requests](https://pypi.org/project/requests/)
	* [Kaldi Gstreamer Server](https://github.com/alumae/kaldi-gstreamer-server)

* **Singularity**:

	* [Singularity](https://singularity.lbl.gov/)
	
### Installation

* **Libraries**:
	
	```bash
	$ sudo apt-get update
	$ sudo apt-get -r requirements.txt 
	```
	
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
	
	The the above installation is for _Ubuntu 16.04_. Refer below links for other versions.
	
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
	$ cd ../src
	$ sudo ./configure --use-cuda --cudatk-dir=/usr/local/cuda/ --cuda-arch=-arch=sm_70 --shared
	$ sudo extras/install_irstlm.sh
	$ make -j clean depend `nproc`
	$ make -j `nproc`
	```
	
	**_NOTE_**:
	The entire process can take **_3-4 hours_**, depending on the server configurations.
	
* **Swig**:	

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
	
	```bash
	$ git clone https://github.com/sequitur-g2p/sequitur-g2p.git
	$ pip3 install git+https://github.com/sequitur-g2p/sequitur-g2p@master
	$ make -j `nproc`
	```

## Data-Preprocessing for Training
The [official Kaldi's documentation](https://kaldi-asr.org/doc/data_prep.html) is the basis of a lot of this section. We need to keep data under asr-german/data/wav

- Files created:  
	- text  
	- utt2spk  
	- segments  
	- wav.scp  
	
## Training
## Some Training Results
Here are some of the results I obtained after training the model. The script [_recipe_v2/show_results.sh_](./recipe_v2/show_results.sh) was used to get these results. These results are based on _best_wer_ file generated by Kaldi.

**_Word Error Rate_ vs _Training Stages_**
<p align="center"><img src="./images/training_graph.png" width='54%' height='60%'></p>

**Percentage of _Deletion_, _Insertion_ and _Subsitution Error_ across different Training Stages**
<img align = "left" src="./images/error_graph-1.png" width='43%' height='45%'> <img float ="right" src="./images/error_graph-2.png" width='44%' height='45%'>

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

* **Kaldi Gstreamer Server**:
	
	[Kaldi Gstreamer Server](https://github.com/alumae/kaldi-gstreamer-server) is a real-time full-duplex speech recognition server, based on the Kaldi toolkit and the GStreamer framework and implemented in Python.
	
	```bash
	$ sudo apt-get update
	$ sudo apt-get -r requirements.txt 
	```

## Acknowledgments
* [Google Summer of Code 2019](https://summerofcode.withgoogle.com/)
* [Red Hen Lab](http://www.redhenlab.org/)
* [Kaldi](http://www.kaldi-asr.org)
* [Kaldi Help Group](https://groups.google.com/forum/#!forum/kaldi-help)
* [Singularity Help Group](https://groups.google.com/a/lbl.gov/forum/#!forum/singularity)