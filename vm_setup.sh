#!/bin/bash

# NB: This must be run as superuser/root
# This is also specific for ubuntu 16.04

# Add new hub user and add that user to the hub group
useradd --shell /bin/bash --create-home --comment "UofA Bioinformatics Hub" hub
echo -e "hub:hub" | chpasswd
usermod -aG sudo hub
chown --recursive hub:hub /home/hub/

# Add the repo to source.list
echo "deb http://cran.rstudio.com/bin/linux/ubuntu xenial/" | tee -a /etc/apt/sources.list

# Setup the keyserver. Not sure if this runs from inside a script...
gpg --keyserver keyserver.ubuntu.com --recv-key E084DAB9
gpg -a --export E084DAB9 | sudo apt-key add -

# Install R base
apt-get update
apt-get install r-base r-base-dev

# Installing R-Studio. Check the version number first
apt-get install gdebi-core
wget https://download1.rstudio.org/rstudio-1.0.44-amd64.deb
gdebi -n rstudio-1.0.44-amd64.deb
rm rstudio-1.0.44-amd64.deb

# Setup RStudio Server
wget https://download2.rstudio.org/rstudio-server-1.0.44-amd64.deb
gdebi rstudio-server-1.0.44-amd64.deb
rm rstudio-server-1.0.44-amd64.deb

# You'll also need these dependencies for some of the R packages
apt-get update
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
apt-get -y install bedtools
apt-get -y install git
apt-get -y install unzip
apt-get -y install zlib1g-dev
apt-get -y install ipython-notebook
apt-get -y install ipython-notebook
apt-get -y install ipython-notebook
apt-get -y install language-pack-en-base
apt-get -y install virtualenv
apt-get -y install tabix
apt-get -y install hdf5-tools
apt-get -y install libhdf5-dev
apt-get -y install hdf5-helpers
apt-get -y install libhdf5-serial-dev
apt-get -y install git
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
apt-get -y install bzip2
apt-get -y install automake
apt-get -y install g++
apt-get -y install autoconf
apt-get -y install libncurses5-dev
apt-get -y install curl
apt-get -y install libgsl0-dev

# Fix locale
sudo dpkg-reconfigure locales

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
cd /opt/local
git archive --format=zip -9 --remote=git://genome-source.cse.ucsc.edu/kent.git beta src/userApps > userApps.zip \
  && unzip userApps.zip \
  && mv src/userApps . \
  && rmdir src \
  && rm userApps.zip

# Install homer
cd /opt/local
git clone https://bitbucket.org/dennishazelett/homer \
  && cd /home/user1/homer \
  && mv .inputrc .. \
  && rm Dockerfile contributors.txt .bash_profile \
  && PATH=$PATH:/home/user1/blat/:/home/user1/weblogo/ \
  && wget http://homer.salk.edu/homer/configureHomer.pl \
  && perl configureHomer.pl -install homer

# Install Salmon
cd /opt/local
wget -O salmon.tar.gz https://github.com/COMBINE-lab/salmon/releases/download/v0.6.0/SalmonBeta-0.6.0_DebianSqueeze.tar.gz \
    && tar zxvf salmon.tar.gz && mv SalmonBeta-0.6.1_DebianSqueeze Salmon

# Install Kallisto
wget https://github.com/pachterlab/kallisto/releases/download/v0.43.0/kallisto_linux-v0.43.0.tar.gz \
    && tar xvzf kallisto_linux-v0.43.0.tar.gz && mv kallisto_linux-v0.43.0 kallisto

# Install sambamba
cd /opt/local
git clone --recursive https://github.com/lomereiter/sambamba.git \
	&& cd /opt/local/sambamba \
	&& make sambamba-ldmd2-64

# Install
cd /opt/local
wget -c https://data.broadinstitute.org/igv/projects/downloads/IGV_2.3.90.zip
wget -c ftp://ftp.ccb.jhu.edu/pub/infphilo/hisat2/downloads/hisat2-2.0.5-Linux_x86_64.zip
wget -c https://github.com/broadinstitute/picard/releases/download/2.2.2/picard-tools-2.2.2.zip
wget -c https://ccb.jhu.edu/software/tophat/downloads/tophat-2.1.1.Linux_x86_64.tar.gz
wget -c http://cole-trapnell-lab.github.io/cufflinks/assets/downloads/cufflinks-2.2.1.Linux_x86_64.tar.gz
wget -c https://github.com/BenLangmead/bowtie2/releases/download/v2.2.6/bowtie2-2.2.6-linux-x86_64.zip
wget -c http://ftp-trace.ncbi.nlm.nih.gov/sra/sdk/2.6.2/sratoolkit.2.6.2-ubuntu64.tar.gz
wget -c http://ccb.jhu.edu/software/stringtie/dl/stringtie-1.3.2b.Linux_x86_64.tar.gz

unzip IGV_2.3.90.zip && mv IGV_2.3.90.zip IGV
unzip hisat2-2.0.5-Linux_x86_64.zip && mv hisat2-2.0.5-Linux_x86_64 hisat2
unzip picard-tools-2.2.2.zip && mv picard-tools-2.2.2  picard
unzip bowtie2-2.2.6-linux-x86_64.zip && mv bowtie2-2.2.6 bowtie2
tar zxvf tophat-2.1.1.Linux_x86_64.tar.gz && mv tophat-2.1.1.Linux_x86_64 tophat
tar zxvf cufflinks-2.2.1.Linux_x86_64.tar.gz && mv cufflinks-2.2.1.Linux_x86_64 cufflinks
tar zxvf sratoolkit.2.6.2-ubuntu64.tar.gz && mv sratoolkit.2.6.2-ubuntu64 sratoolkit
tar zxvf stringtie-1.3.2b.Linux_x86_64.tar.gz && mv stringtie-1.3.2b.Linux_x86_64 stringtie

# install dev bwa
git clone https://github.com/lh3/bwa.git && cd bwa && make

# Add new PATH variables
echo 'export PATH=${PATH}:'"/opt/local/IGV:/opt/local/bin:/opt/local/Salmon/bin:/opt/local/sambamba/build:/opt/local/kallisto:/opt/local/hisat2:/opt/local/bowtie2:/opt/local/tophat:/opt/local/cufflinks:/opt/local/bwa:/opt/local/sratoolkit:/opt/local/stringtie" >> ${HOME}/.bashrc
