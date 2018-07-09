#!/bin/bash
# -n noexec: only syntax check

#   Written by Guoyang 'Simon' Zheng <simonchgy@gmail.com>
#   Updated by S Pederson 2018-07-04

#   This script is designed to be run on instantiation for Ubntu 16.04 (Xenial xerxus)

#   This automatic script will...
#   1) set up new user with password
#   2) set up ssh for the user with public key
#   3) download and install Miniconda
#   4) add Bioconda and necessary channels without R
#   5) install conda pakages
#   6) download and install R, RStudio Server
#   7) set up Bioconductor and install R packages
#   8) general cleanups
#
#   * Check /tmp/biohub_init/ for logs before rebooting the vm

##  These packages are installed by default (hard-coded):
##
## Conda
##  {
##  bwa bowtie2 sambamba star hisat2 samtools subread igv bedtools fastqc picard
##  }
##
## R
##  {
##  "reshape2", "ggrepel", "readxl", "AnnotationHub", "biomaRt", "Biostrings", "BSgenome",
##  "DESeq2", "GenomicRanges", "GenomicFeatures", "Rsubread", "Rsamtools", "rtracklayer",
##  "Gviz", "ggbio", "Biobase", "edgeR", "limma", "Glimma", "xtable", "pander", "knitr",
##  "rmarkdown", "lme4", "multcomp", "scales", "stringr", "corrplot", "pheatmap", "devtools", "tidyverse",
##  "BiocGenerics", "BiocStyle", "checkmate", "ggdendro", "lubridate", "magrittr",
##  "plotly", "shiny", "ShortRead", "viridis", "viridisLite", "zoo", "shinyFiles"
##  }

######################################################
###################### Customisation  ################
######################################################

# mandatory new user name
USER_NAME='integrape'

# mandatory password in plain text, useful when 'sudo' in the future
USER_PASS='grenacheSucks'

# specify if user is added to 'sudo' group ('yes' or 'no')
SUDO_PRIVILIGE=yes

# mandatory SSH public key.
SSH_PUBLIC_KEY='ssh-rsa hub.pub jbreen@LC02K51MKFFT1.ad.adelaide.edu.au'


# R Studio Server (amd64) version check. the lastest was 1.1.453 by 18JUN18.
RSS_VER=1.1.453

# optional R script to be run after RStudio server with Bioconductor is ready.
R_SCRIPT=''



######################################################
####################### housekeeping #################
######################################################

BASEDIR="/tmp/biohub_init"
_logfile="$BASEDIR/auto-script.log"
_USER_HOME="/home/$USER_NAME"

# make base
if [[ ! -d $BASEDIR ]]; then mkdir -p $BASEDIR; fi
cd $BASEDIR

date >$_logfile
echo -e '********************** Start of auto-script *********************\n' | tee --append $_logfile



####################################################
########################  main  ####################
####################################################

echo -e '********************* prep begin *********************' | tee --append $_logfile
# complete apt functionality, needed for adding repos
dpkg -s software-properties-common 2>>$_logfile
if [[ $? != 0 ]]; then
    apt-get install -y software-properties-common 2>>$_logfile
fi
killall dpkg
# if ssh-server is not pre-installed, do install
dpkg -s openssh-server 2>>$_logfile
if [[ $? != 0 ]]; then
    apt-get install -y openssh-server 2>>$_logfile
fi
killall dpkg

# add CRAN entry to the apt sources. (Ubuntu Bionic 18.04)
add-apt-repository 'deb https://mirror.aarnet.edu.au/pub/CRAN/bin/linux/ubuntu/ xenial-cran35/' 2>>$_logfile
# install apt key and update repository
gpg --keyserver keyserver.ubuntu.com --recv-key E084DAB9 2>>$_logfile
gpg -a --export E084DAB9 | apt-key add - 2>>$_logfile
apt-get update -y 2>>$_logfile
apt-get install -y git-core gdebi-core 2>>$_logfile
echo -e '********************* prep finished *********************\n' | tee --append $_logfile



echo -e '********************* user set-up begin ********************' | tee --append $_logfile
# add new user
adduser --quiet --gecos '' --disabled-password --add_extra_groups $USER_NAME
echo $USER_NAME:$USER_PASS | chpasswd
# grant sudo privilege
case $SUDO_PRIVILIGE in
    yes )
    adduser --quiet $USER_NAME sudo
    echo "* User "$USER_NAME" is added to 'sudo' group *" >> $_logfile
    ;;
    no )
    echo
    ;;
esac

# set up SSH
# backup if any pre-existing config
echo -e "* Backing up previous ssh config *" >>$_logfile
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup_before_openssh-server 2>>$_logfile
chmod a-w /etc/ssh/sshd_config.backup_before_openssh-server 2>>$_logfile
echo -e "* If 'cp' and 'chmod' could not find files as shown above this line, openssh-server was not installed until this script. *" >>$_logfile

# set up ssh key
echo -e "* Setting up new ssh config *" >>$_logfile
mkdir -p $_USER_HOME/.ssh
cat > $_USER_HOME/.ssh/authorized_keys <<<"$SSH_PUBLIC_KEY"
# -rwx------
chmod 700 $_USER_HOME/.ssh
# -rw-------
chmod 600 $_USER_HOME/.ssh/authorized_keys
# hand back the ownership to the user
chown -hR $USER_NAME:$USER_NAME $_USER_HOME/.ssh


echo -e '****************** user setup finished ******************\n' | tee --append $_logfile

echo -e '********************* R begin *********************' | tee --append $_logfile
echo "* Installing R and fixes. Fixes come first ...... *" | tee --append $_logfile

# fixes for errors are infered from the console log, as also exists in Nectar's vm:
#
#   $ cat /var/log/cloud-init-output.log | grep 'deb:'
#     * deb: libssl-dev (Debian, Ubuntu, etc)
#     * deb: libcurl4-openssl-dev (Debian, Ubuntu, etc)
#     * deb: libmariadb-client-lgpl-dev (Debian, Ubuntu 16.04)
#     ...
#
# which are supposedly from these error prompts during R compilation(?):
#
#   ... ...
#   ------------------------- ANTICONF ERROR ---------------------------
#   Configuration failed because openssl was not found. Try installing:
# -> * deb: libssl-dev (Debian, Ubuntu, etc)
#    * rpm: openssl-devel (Fedora, CentOS, RHEL)
#    * csw: libssl_dev (Solaris)
#    * brew: openssl@1.1 (Mac OSX)
#   If openssl is already installed, check that 'pkg-config' is in your
#   PATH and PKG_CONFIG_PATH contains a openssl.pc file. If pkg-config
#   is unavailable you can set INCLUDE_DIR and LIB_DIR manually via:
#   R CMD INSTALL --configure-vars='INCLUDE_DIR=... LIB_DIR=...'
#   --------------------------------------------------------------------
#   ... ...
#
#
apt-get install -y libxml2-dev libssl-dev libcurl4-openssl-dev libmariadb-client-lgpl-dev libssh2-1-dev 2>>$_logfile

apt-get install -y r-base-core r-base-dev 2>>$_logfile

# run Steve's R script to set up bioconductor
echo "* Starting to set up Bioconductor ...... *" | tee --append $_logfile
_R_BIOCONDUCTOR_INS='
source("https://bioconductor.org/biocLite.R")
pkgs <- c("reshape2", "ggrepel", "readxl", "AnnotationHub", "biomaRt", "Biostrings", "BSgenome",
          "DESeq2", "GenomicRanges", "GenomicFeatures", "Rsubread", "Rsamtools", "rtracklayer",
          "Gviz", "ggbio", "Biobase", "edgeR", "limma", "Glimma", "xtable", "pander", "knitr",
          "rmarkdown", "multcomp", "scales", "stringr", "corrplot", "pheatmap", "devtools", "tidyverse",
          "BiocGenerics", "BiocStyle", "checkmate", "ggdendro", "lubridate", "magrittr",
          "plotly", "shiny", "ShortRead", "viridis", "viridisLite", "zoo", "shinyFiles")
biocLite(pkgs)
biocLite("UofABioinformaticsHub/ngsReports")
biocValid(fix = TRUE)
'
/usr/bin/Rscript <( echo "$_R_BIOCONDUCTOR_INS" ) 2>>$_logfile
echo -e '* R: Bioconductor finished *\n' | tee --append $_logfile

# get RStudio Server
echo "* Starting to download RStudio Server ...... *" | tee --append $_logfile
wget https://download2.rstudio.org/rstudio-server-${RSS_VER}-amd64.deb -O $BASEDIR/rstudio.deb 2>>$_logfile
gdebi --non-interactive ./rstudio.deb 2>>$_logfile
rstudio-server verify-installation 2>>$_logfile
echo -e "* RStudio Server installation finished. Version: ${RSS_VER} *\n" >>$_logfile

# run user script
echo -e '* R: user script start *\n' | tee --append $_logfile
/usr/bin/Rscript <( echo "$R_SCRIPT") 2>>$_logfile
echo -e '* R: user script finished *\n' | tee --append $_logfile
echo -e '********************* R finished *********************\n' | tee --append $_logfile


##########################
########################## cleanup
##########################

apt-get autoremove && apt-get autoclean 2>>$_logfile

echo -e '*********************** End of auto-script ***********************\n' | tee --append $_logfile
echo "Script ran to the end.
PWD=$PWD
PATH=$PATH
USER_NAME=$USER_NAME
New User's Groups=$( groups $USER_NAME )" >$BASEDIR/auto-script-finished.log

date >> $_logfile
exit
