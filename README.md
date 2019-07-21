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

* **Graphics Processing Unit (GPU)**:

	* [Cuda](https://developer.nvidia.com/cuda-zone)

* **Kaldi**:

	* [Numpy](https://www.numpy.org/)
	* [Beautifulsoup4](https://pypi.org/project/beautifulsoup4/)
	* [LXml](https://pypi.org/project/lxml/)
	* [Requests](https://pypi.org/project/requests/)
	
* **SWIG**:

	* [Swig](http://www.swig.org/)
	
* **Grapheme-to-Phoneme**:

	* [Sequitur-G2P](https://github.com/sequitur-g2p/sequitur-g2p)

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
	
	* [_Cuda-Installation-Guide-Linux_](https://docs.nvidia.com/cuda/cuda-installation-guide-linux/index.html)
	
	* [_Cuda-Downloads_](https://developer.nvidia.com/cuda-downloads)

* **Kaldi**:
	
	**._STEP 1:_**

	```bash
	$ git clone https://github.com/AASHISHAG/asr-german.git
	$ cd asr-german
	$ pip3 install -r requirements.txt
	$ cd ..
	```
	
	**_STEP 2:_**

	```bash
	$ git clone https://github.com/kaldi-asr/kaldi.git kaldi-trunk --origin golden
	$ cd kaldi-trunk
	```
	
	**_STEP 3:_**

	```bash
	$ cd tools
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
	$ pip3 install git+https://github.com/sequitur-g2p/sequitur-g2p@master
	$ git clone https://github.com/sequitur-g2p/sequitur-g2p.git
	$ make -j `nproc`
	```
