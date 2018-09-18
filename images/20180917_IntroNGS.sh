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
USER_NAME='trainee'

# mandatory password in plain text, useful when 'sudo' in the future
USER_PASS='trainee'

# specify if user is added to 'sudo' group ('yes' or 'no')
SUDO_PRIVILIGE=no

# mandatory SSH public key.
SSH_PUBLIC_KEY='ssh-rsa hub.pub jbreen@LC02K51MKFFT1.ad.adelaide.edu.au'

# aditional conda packages separeted by SPACE
CONDA_PKGS='freebayes cutadapt bcftools'

# optional miniconda installation directory. leave empty to use the default "~/miniconda"
CONDA_DIR=''


######################################################
####################### housekeeping #################
######################################################


BASEDIR="/tmp/biohub_init"
_logfile="$BASEDIR/auto-script.log"
_USER_HOME="/home/$USER_NAME"
CONDA_PKGS_DEF='bwa bowtie2 sambamba star hisat2 samtools subread igv bedtools fastqc picard'
# make base
if [[ ! -d $BASEDIR ]]; then mkdir -p $BASEDIR; fi
cd $BASEDIR

date >$_logfile
echo -e '********************** Start of auto-script *********************\n' | tee --append $_logfile

# by default, miniconda resides in home
if [[ -z $CONDA_DIR ]]; then
    CONDA_DIR="$_USER_HOME/miniconda"
    echo "* CONDA DIR remains default: $CONDA_DIR *" >> $_logfile
else
    echo "* CONDA DIR is customised as: $CONDA_DIR *" >> $_logfile
fi

# The console-setup wants a response, so run this beforehand to prevent a hang
echo "console-setup   console-setup/charmap47 select  UTF-8" > encoding.conf
debconf-set-selections encoding.conf
rm encoding.conf
apt-get update &>>$_logfile
apt-get upgrade -y &>>$_logfile


####################################################
########################  main  ####################
####################################################

echo -e '********************* prep begin *********************' | tee --append $_logfile
# complete apt functionality, needed for adding repos
dpkg -s software-properties-common 2>>$_logfile
if [[ $? != 0 ]]; then
    apt-get install -y software-properties-common &>>$_logfile
fi
killall dpkg
# if ssh-server is not pre-installed, do install
dpkg -s openssh-server 2>>$_logfile
if [[ $? != 0 ]]; then
    apt-get install -y openssh-server &>>$_logfile
fi
killall dpkg

apt-get install -y git-core gdebi-core &>>$_logfile
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

# install xubuntu-desktop and other configurations for the workshop
echo -e "* Setting up xubuntu *" >>$_logfile
apt-get install -y xubuntu-desktop &>>$_logfile
rm /etc/network/if-up.d/avahi-autoipd
add-apt-repository -y ppa:x2go/stable &>>$_logfile
apt-get update &>>$_logfile
apt-get install -y x2goserver x2goserver-xsession 2>>$_logfile
# This next line seemed to fix the login problem
apt-get install -y xfce4-session 2>>$_logfile
echo 'export GSETTINGS_SCHEMA_DIR=/usr/share/gconf/schemas:/usr/share/glib-2.0/schemas' >> /etc/profile
echo 'export XDG_DATA_DIRS=/usr/share/xubuntu:/usr/share/xfce4:/usr/local/share/:/usr/share/' >> /etc/profile

# Setup gedit and add a desktop icon
echo -e "* Installing gedit *" >>$_logfile
apt-get install -y gedit &>>$_logfile
# Not sure why this doesn't work
echo "[Desktop Entry]
Version=1.0
Type=Application
Name=Text Editor
Comment=
Exec=/usr/bin/gedit
Icon=accessories-text-editor
Path=
Terminal=false
StartupNotify=false" > /home/$USER_NAME/Desktop/gedit.desktop
chmod +x /home/$USER_NAME/Desktop/gedit.desktop

echo -e '****************** user setup finished ******************\n' | tee --append $_logfile



echo -e '********************* Bioconda begin *********************' | tee --append $_logfile
# download and install Miniconda
echo "* Starting to download Miniconda ...... *" | tee --append $_logfile
wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh -O $BASEDIR/miniconda.sh 2>>$_logfile
echo "* Miniconda Downloaded *" | tee --append $_logfile
# install as user for permission reason
su $USER_NAME -c "bash ./miniconda.sh -b -p $CONDA_DIR" 2>>$_logfile
echo -e "\n# added by manual installation of Miniconda on $( date )\nexport PATH=\"$CONDA_DIR/bin:\$PATH\"" >> $_USER_HOME/.bashrc
export PATH=$CONDA_DIR/bin:$PATH
echo "* Miniconda Installed *" | tee --append $_logfile

# make sure r is not in channels
conda config --remove channels r 2>>$_logfile
# add bioconda channels
conda config --add channels defaults 2>>$_logfile
conda config --add channels conda-forge 2>>$_logfile
conda config --add channels bioconda 2>>$_logfile
echo "* Bioconda channels added *" | tee --append $_logfile
# update conda
echo "* Conda update started...... *" | tee --append $_logfile
conda update --yes conda 2>>$_logfile
echo "*Conda updated *" | tee --append $_logfile

#  install tools in current environment
echo "* Starting to install Conda pakages. This can take a very long time. *" | tee --append $_logfile
conda install --yes $CONDA_PKGS_DEF 2>>$_logfile
echo "* Default Conda pakages installed. *" | tee --append $_logfile
conda install --yes $CONDA_PKGS 2>>$_logfile
echo "* Additional Conda pakages installed if any. *" | tee --append $_logfile
echo "* Conda package(s) installed *" | tee --append $_logfile
echo -e '****************** Bioconda finished ******************\n' | tee --append $_logfile

echo -e '***************Installing Sabre***************' | tee --append $_logfile
# zlib is required to be instaled first
wget https://zlib.net/zlib-1.2.11.tar.gz 2>>$_logfile
tar xzvf zlib-1.2.11.tar.gz 
cd zlib-1.2.11/
./configure 2>> $_logfile
make install 2>> $_logfile 
git clone https://github.com/najoshi/sabre.git
cd sabre
make
cp sabre $CONDA_DIR/bin
chown -hR $USER_NAME:$USER_NAME $CONDA_DIR/bin/sabre
cd ..
rm -rf sabre
echo -e '****************** Sabre Installation Finished ******************\n' | tee --append $_logfile


echo -e '***************Setting Up Data For the Session***************' | tee --append $_logfile
wget https://big-sa.github.io/BASH-Intro-2018/files/BDGP6_genes.gtf
mv BDGP6_genes.gtf /home/$USER_NAME/
chown $USER_NAME:$USER_NAME /home/$USER_NAME/BDGP6_genes.gtf

mkdir -p ${_USER_HOME}/Refs/Celegans

WGS_DIR="/home/$USER_NAME/WGS/01_rawData/fastq"
mkdir -p ${WGS_DIR}
# For some reason, this will not save to the correct path when specified using ${WGS_DIR}. Below is the best solution to a weird problem
wget -c https://universityofadelaide.box.com/shared/static/nqf2ofb28eao26adxxillvs561w7iy5s.gz -O subData.tar.gz 2>>$_logfile
mv subData.tar.gz ${WGS_DIR}/
tar xzvf ${WGS_DIR}/subData.tar.gz
rm ${WGS_DIR}/subData.tar.gz 2>>$_logfile
mv /home/${USER_NAME}/WGS/01_rawData/fastq/chr* ${_USER_HOME}/Refs/Celegans 2>>$_logfile
## Should put a file check here...

MULTI_DIR="/home/$USER_NAME/multiplexed/01_rawData/fastq"
mkdir -p ${MULTI_DIR}
wget -c https://universityofadelaide.box.com/shared/static/0w0fgnm94w18ixh1z0dkmh5e0xht1ajf.gz -O multiplexed.tar.gz 2>>$_logfile
mv multiplexed.tar.gz ${MULTI_DIR}/
tar xzvf ${MULTI_DIR}/multiplexed.tar.gz
rm ${MULTI_DIR}/multiplexed.tar.gz 2>>$_logfile

echo -e '****************** Data Setup Finished ******************\n' | tee --append $_logfile



##########################
########################## cleanup
##########################

apt-get autoremove && apt-get autoclean 2>>$_logfile

echo -e '*********************** End of auto-script ***********************\n' | tee --append $_logfile
echo "Script ran to the end.
PWD=$PWD
PATH=$PATH
USER_NAME=$USER_NAME
CONDA_PKGS_DEF=$CONDA_PKGS_DEF
CONDA_PKGS=$CONDA_PKGS
CONDA_DIR=$CONDA_DIR
New User's Groups=$( groups $USER_NAME )" >$BASEDIR/auto-script-finished.log

date >> $_logfile
exit
