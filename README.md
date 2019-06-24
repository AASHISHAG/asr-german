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

* **Kaldi**:
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


### Installing
[Kaldi ASR](https://github.com/kaldi-asr/kaldi)
* Open terminal and type following commands.
	```bash
	$ git clone https://github.com/AASHISHAG/asr-german.git
	$ cd asr-german
	$ pip install -r requirements.txt 
	```
