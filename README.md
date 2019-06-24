# Automatic Speech Recognition (ASR) - German

_This is my [Google Summer of Code 2019](https://summerofcode.withgoogle.com/projects/#5623384702976000) Project with the [Distributed Little Red Hen Lab](http://www.redhenlab.org/)._

The aim of this project is to develop a working Speech to Text module for the Red Hen Lab’s current Audio processing pipeline. This system will be used to transcribe the Television news broadcast captured by Red Hen in Germany.

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

### Installation

* **Libraries**:
* Open terminal and type following commands.
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
	
	_https://docs.nvidia.com/cuda/cuda-installation-guide-linux/index.html_
	_https://developer.nvidia.com/cuda-downloads_

* **Kaldi**:
	* [Git Large File Storage](https://git-lfs.github.com/)

	
[Kaldi ASR](https://github.com/kaldi-asr/kaldi)
* Open terminal and type following commands.
	```bash
	$ git clone https://github.com/AASHISHAG/asr-german.git
	$ cd asr-german
	$ pip install -r requirements.txt 
	```
