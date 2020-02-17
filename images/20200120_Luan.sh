#!/bin/bash
# -n noexec: only syntax check

#   Written by Guoyang 'Simon' Zheng <simonchgy@gmail.com>
#   Updated by S Pederson 2020-01-20

#   This script is designed to be run on instantiation for Ubuntu 18.04 (bionic beaver)

#   This automatic script will...
#   1) set up new user with password
#   2) set up ssh for the user with public key
#   3) setup gedit, sublime & LaTeX
#   4) download and install Miniconda
#   5) add Bioconda and necessary channels without R
#   6) install conda pakages
#   7) download and install R, RStudio Server & RStudio
#   8) set up Bioconductor and install R packages
#   9) general cleanups
#
#   * Check /tmp/biohub_init/ for logs before rebooting the vm


######################################################
###################### Customisation  ################
######################################################

# mandatory new user name
USER_NAME=a1696632

# mandatory password in plain text, useful when 'sudo' in the future
USER_PASS=${USER_NAME}

# specify if user is added to 'sudo' group ('yes' or 'no')
SUDO_PRIVILIGE=yes

# mandatory SSH public key.
SSH_PUBLIC_KEY='ssh-rsa hub.pub jbreen@LC02K51MKFFT1.ad.adelaide.edu.au'

# Ubuntu version
UBUNTU_VERS='bionic'

# R Studio Server (amd64) version check
RSS_VER=1.2.5033

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

# Set non-interactive mode
export DEBIAN_FRONTEND=noninteractive
# Also set the locales in case this becomes an issue
apt-get install -y language-pack-en 2>>$_logfile
locale-gen en_AU.UTF-8
dpkg-reconfigure locales


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

# enable password authentication
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
echo -e "* Restarting ssh *" >>$_logfile
systemctl restart ssh 2>>$_logfile

echo -e '****************** user setup finished ******************\n' | tee --append $_logfile


echo -e '********************* R begin *********************' | tee --append $_logfile
echo "* Installing R and fixes. Fixes come first ...... *" | tee --append $_logfile


# add CRAN entry to the apt sources. 
echo -e "Adding keyserver for R" | tee --append $_logfile
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9 
echo -e "Adding CRAN repository" | tee --append $_logfile
add-apt-repository "deb https://mirror.aarnet.edu.au/pub/CRAN/bin/linux/ubuntu/ ${UBUNTU_VERS}-cran35/" 2>>$_logfile
# install apt key and update repository
apt-get update -y 2>>$_logfile

echo -e "Installing dependencies" | tee --append $_logfile
apt-get install -y libxml2-dev libssl-dev libcurl4-openssl-dev libmariadb-client-lgpl-dev libssh2-1-dev 2>>$_logfile
echo -e "Installing R" | tee --append $_logfile
apt-get install -y git gdebi-core r-base-core r-base-dev 2>>$_logfile

# run Steve's R script to set up bioconductor
echo "* Starting to set up Bioconductor ...... *" | tee --append $_logfile
_R_BIOCONDUCTOR_INS='
install.packages("BiocManager")
pkgs <- c("tidyverse", "ggrepel", "AnnotationHub", "biomaRt", "Biostrings", "BSgenome",
          "GenomicRanges", "GenomicFeatures", "Rsubread", "Rsamtools", "rtracklayer",
          "Gviz", "Biobase", "edgeR", "limma", "Glimma", "xtable", "pander", "knitr",
          "rmarkdown", "scales", "corrplot", "pheatmap", "devtools", "networkD3", "igraph",
          "BiocGenerics", "BiocStyle", "checkmate", "ggdendro", "tinytex", "roxygen2",
          "plotly", "shiny", "shinyFiles", "ngsReports", "strandCheckR")
BiocManager::install(pkgs)
tinytex::install_tinytex()
'
/usr/bin/Rscript <( echo "$_R_BIOCONDUCTOR_INS" ) 2>>$_logfile
echo -e '* R: Bioconductor finished *\n' | tee --append $_logfile

# get RStudio Server
echo "* Starting to download RStudio Server ...... *" | tee --append $_logfile
wget https://download2.rstudio.org/rstudio-server-${RSS_VER}-amd64.deb -O $BASEDIR/rstudio-server.deb 2>>$_logfile
gdebi --non-interactive ./rstudio-server.deb 2>>$_logfile
rstudio-server verify-installation 2>>$_logfile
echo -e "* RStudio Server installation finished. Version: ${RSS_VER} *\n" >>$_logfile


echo -e '********************* R finished *********************\n' | tee --append $_logfile


##########################
########################## cleanup
##########################

apt autoremove && apt autoclean 2>>$_logfile

echo -e '*********************** End of auto-script ***********************\n' | tee --append $_logfile
echo "Script ran to the end.
PWD=$PWD
PATH=$PATH
USER_NAME=$USER_NAME
New User's Groups=$( groups $USER_NAME )" >$BASEDIR/auto-script-finished.log

date >> $_logfile
exit
