#!/bin/bash

# NB: This must be run as superuser/root
# This is also specific for ubuntu 16.04

# Fix locale
apt-get -y install language-pack-en

# Add the repo to source.list
echo "deb http://cran.rstudio.com/bin/linux/ubuntu xenial/" | tee -a /etc/apt/sources.list

# Setup the keyserver. Not sure if this runs from inside a script...
gpg --keyserver keyserver.ubuntu.com --recv-key E084DAB9
gpg -a --export E084DAB9 | sudo apt-key add -

# Install R base
apt-get -y update
apt-get -y install r-base
apt-get -y install r-base-dev
apt-get -y install libcurl4-openssl-dev
apt-get -y install libpng12-dev
apt-get -y install libmysqlclient-dev
apt-get -y install build-essentials
apt-get -y install libssl-dev
apt-get -y install libxml2-dev
apt-get -y install openjdk-9-jre-headless
apt-get -y install python2.7
apt-get -y install python-pip
apt-get -y install python-dev
apt-get -y install python3-pip
apt-get -y install ipython
apt-get -y install ipython-notebook
apt-get -y install zip
apt-get -y install wget
apt-get -y install pigz
apt-get -y install bzip2
apt-get -y install bedtools
apt-get -y install git
apt-get -y install unzip
apt-get -y install zlib1g-dev
apt-get -y install ipython-notebook
apt-get -y install virtualenv
apt-get -y install tabix
apt-get -y install hdf5-tools
apt-get -y install libhdf5-dev
apt-get -y install hdf5-helpers
apt-get -y install libhdf5-serial-dev
apt-get -y install apt-utils
apt-get -y install cmake
apt-get -y install ncbi-blast+
apt-get -y install ncbi-blast+-legacy
apt-get -y install clustalo
apt-get -y install mafft
apt-get -y install raxml
apt-get -y install mothur-mpi
apt-get -y install muscle
apt-get -y install cd-hit
apt-get -y install rdp-classifier
apt-get -y install rtax
apt-get -y install jellyfish
apt-get -y install plink1.9
apt-get -y install ldc
apt-get -y install automake
apt-get -y install g++
apt-get -y install autoconf
apt-get -y install libncurses5-dev
apt-get -y install curl
apt-get -y install libgsl0-dev
apt-get -y install texlive
apt-get -y install xauth
apt-get -y install gdebi-core

# Installing R-Studio. Check the version number first - Might not need this
RSVERS=1.1.383
wget https://download1.rstudio.org/rstudio-${RSVERS}-amd64.deb
gdebi --n rstudio-${RSVERS}-amd64.deb
rm rstudio-${RSVERS}-amd64.deb

# Setup RStudio Server
wget https://download2.rstudio.org/rstudio-server-${RSVERS}-amd64.deb
gdebi --n rstudio-server-${RSVERS}-amd64.deb
rm rstudio-server-${RSVERS}-amd64.deb

# Update pip
pip completion --bash >> ~/.bashrc
pip install --upgrade pip

# Setup an area for our custom programs
mkdir /opt/local; mkdir /opt/local/bin

# Install samtools/bcftools
cd /opt/local
git clone --branch=develop git://github.com/samtools/htslib.git
git clone --branch=develop git://github.com/samtools/bcftools.git
git clone --branch=develop git://github.com/samtools/samtools.git
cd bcftools; make; make prefix=/opt/local/bin install
cd ../samtools; make; make prefix=/opt/local/bin install

# Install UCSC kent utilities
mkdir /opt/local/ucsc-tools; cd /opt/local/ucsc-tools
rsync -aP rsync://hgdownload.cse.ucsc.edu/genome/admin/exe/linux.x86_64/ ./

# Install Salmon
SALMONVERS=0.8.2
cd /opt/local
wget -O salmon.tar.gz https://github.com/COMBINE-lab/salmon/releases/download/v${SALMONVERS}/Salmon-${SALMONVERS}_linux_x86_64.tar.gz \
    && tar zxvf salmon.tar.gz

# Install Kallisto
KALLISTVERS=0.43.1
wget https://github.com/pachterlab/kallisto/releases/download/v${KALLISTVERS}/kallisto_linux-v${KALLISTVERS}.tar.gz \
    && tar xvzf kallisto_linux-v${KALLISTVERS}.tar.gz && mv kallisto_linux-v${KALLISTVERS} kallisto

# Install sambamba
cd /opt/local
git clone --recursive https://github.com/lomereiter/sambamba.git \
	&& cd /opt/local/sambamba \
	&& make sambamba-ldmd2-64

# Install
cd /opt/local
IGVERS=2.4.2
wget -c https://data.broadinstitute.org/igv/projects/downloads/IGV_${IGVERS}.zip
unzip IGV_${IGVERS}.zip && mv IGV_${IGVERS}.zip IGV

HISAT2VERS=2.1.0
wget -c ftp://ftp.ccb.jhu.edu/pub/infphilo/hisat2/downloads/hisat2-${HISAT2VERS}-source.zip
unzip hisat2-${HISAT2VERS}-Linux_x86_64.zip && mv hisat2-${HISAT2VERS}-Linux_x86_64 hisat2

PICVERS=2.13.2
wget -c https://github.com/broadinstitute/picard/archive/${PICVERS}.zip
unzip picard-${PICVERS}.zip && mv picard-${PICVERS}.zip picard

wget -c https://ftp-trace.ncbi.nlm.nih.gov/sra/sdk/current/sratoolkit.current-ubuntu64.tar.gz
tar zxvf sratoolkit.current-ubuntu64.tar.gz && mv sratoolkit.current-ubuntu64 sratoolkit

STRINGVERS=1.3.3b
wget -c http://ccb.jhu.edu/software/stringtie/dl/stringtie-${STRINGVERS}.Linux_x86_64.tar.gz
tar zxvf stringtie-${STRINGVERS}.Linux_x86_64.tar.gz && mv stringtie-${STRINGVERS}.Linux_x86_64 stringtie

# NO LONGER REQUIRED
#wget -c https://ccb.jhu.edu/software/tophat/downloads/tophat-2.1.1.Linux_x86_64.tar.gz
#wget -c http://cole-trapnell-lab.github.io/cufflinks/assets/downloads/cufflinks-2.2.1.Linux_x86_64.tar.gz
#wget -c https://github.com/BenLangmead/bowtie2/releases/download/v2.2.6/bowtie2-2.2.6-linux-x86_64.zip
#unzip bowtie2-2.2.6-linux-x86_64.zip && mv bowtie2-2.2.6 bowtie2
#tar zxvf tophat-2.1.1.Linux_x86_64.tar.gz && mv tophat-2.1.1.Linux_x86_64 tophat
#tar zxvf cufflinks-2.2.1.Linux_x86_64.tar.gz && mv cufflinks-2.2.1.Linux_x86_64 cufflinks

# clean up
rm /opt/local/*.tar.gz
rm /opt/local/*.zip

# install dev bwa
git clone https://github.com/lh3/bwa.git && cd bwa && make

# reupdate
apt-get -y update
apt-get -y upgrade

# restart
reboot
