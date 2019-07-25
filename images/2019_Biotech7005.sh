#!/bin/bash
# -n noexec: only syntax check

#   Written by Guoyang 'Simon' Zheng <simonchgy@gmail.com>
#   Updated by S Pederson 2019-07-24

#   This script is designed to be run on instantiation for Ubntu 18.04 (Bionic beaver)

#   This automatic script will...
#   1) set up new user with password
#   2) set up ssh for the user with public key
#   3) download and install Miniconda
#   4) add Bioconda and necessary channels without R
#   5) install conda packages
#   6) install sabre & other packages
#   7) download and install R, RStudio Server
#   8) set up Bioconductor and install R packages
#   9) general cleanups
#
#   * Check /tmp/biohub_init/ for logs before rebooting the vm


######################################################
###################### Customisation  ################
######################################################

# mandatory new user name
USER_NAME=biotech7005

# mandatory password in plain text, useful when 'sudo' in the future
USER_PASS=${USER_NAME}

# specify if user is added to 'sudo' group ('yes' or 'no')
SUDO_PRIVILIGE=yes

# mandatory SSH public key.
SSH_PUBLIC_KEY='ssh-rsa hub.pub jbreen@LC02K51MKFFT1.ad.adelaide.edu.au'

# aditional conda packages separated by SPACE
CONDA_PKGS='adapterremoval2 bcftools cutadapt freebayes gblocks jalview mafft mrbayes muscle'

# R Studio Server (amd64) version check. the lastest was 1.1.453 by 18JUN18.
RSS_VER=1.2.1335

# optional miniconda installation directory. leave empty to use the default "~/miniconda"
CONDA_DIR=''

# optional R script to be run after RStudio server with Bioconductor is ready.
R_SCRIPT=''

######################################################
############## Tidy other variables ##################
######################################################
BASEDIR="/tmp/biohub_init"
_logfile="$BASEDIR/auto-script.log"
_USER_HOME="/home/$USER_NAME"
CONDA_PKGS_DEF='bedtools bowtie2 bwa fastqc hisat2 igv kallisto picard sambamba samtools star subread'


## Packages for Bioconductor installation
_R_BIOCONDUCTOR_INS='
install.packages("BiocManager")
pkgs <- c("tidyverse", "ggrepel", "AnnotationHub", "biomaRt", "Biostrings", "BSgenome",
          "DESeq2", "GenomicRanges", "GenomicFeatures", "Rsubread", "Rsamtools", "rtracklayer",
          "Gviz", "Biobase", "edgeR", "limma", "Glimma", "xtable", "pander", "knitr",
          "rmarkdown", "lme4", "multcomp", "scales", "corrplot", "pheatmap", "devtools",
          "BiocGenerics", "BiocStyle", "checkmate", "ggdendro", "plotly", "shiny", "ShortRead", 
          "viridis", "viridisLite", "zoo", "shinyFiles", "ngsReports")
BiocManager::install(pkgs)
'

## make directory for logs
if [[ ! -d $BASEDIR ]]; then mkdir -p $BASEDIR; fi
cd $BASEDIR
date >$_logfile

# by default, miniconda resides in home
if [[ -z $CONDA_DIR ]]; then
    CONDA_DIR="$_USER_HOME/miniconda"
    echo "* CONDA DIR remains default: $CONDA_DIR *" >> $_logfile
else
    echo "* CONDA DIR is customised as: $CONDA_DIR *" >> $_logfile
fi

######################################################
####################### housekeeping #################
######################################################

export DEBIAN_FRONTEND=noninteractive
export LANGUAGE=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
locale-gen en_US.UTF-8
dpkg-reconfigure locales

apt-get update >> $_logfile
apt-get upgrade -y >> $_logfile

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
add-apt-repository 'deb https://mirror.aarnet.edu.au/pub/CRAN/bin/linux/ubuntu/ bionic-cran35/' 2>>$_logfile
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
passwd -e $USER_NAME 
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



echo -e '********************* Bioconda begin *********************' | tee --append $_logfile
# download and install Miniconda
echo "* Starting to download Miniconda ...... *" | tee --append $_logfile
wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh -O $BASEDIR/miniconda.sh 2>>$_logfile
echo "* Miniconda Downloaded *" | tee --append $_logfile
# install as user for permission reasons
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
conda config --add channels maxibor 2>>$_logfile # Required for adapterremoval
conda config --add channels biocore 2>>$_logfile # Required for mafft
echo "* Bioconda channels added *" | tee --append $_logfile
# update conda
echo "* Conda update started...... *" | tee --append $_logfile
conda update --yes conda 2>>$_logfile
echo "*Conda updated *" | tee --append $_logfile

#  install tools in current environment
echo "* Starting to install Conda packages. This can take a very long time. *" | tee --append $_logfile
conda install --yes $CONDA_PKGS_DEF 2>>$_logfile
echo "* Default Conda packages installed. *" | tee --append $_logfile
conda install --yes $CONDA_PKGS 2>>$_logfile
echo "* Additional Conda packages installed if any. *" | tee --append $_logfile
echo "* Conda package(s) installed *" | tee --append $_logfile
# Cleanup after install
echo -e "Removing tarballs" | tee --append $_logfile
conda clean --all 2>>$_logfile

echo -e '****************** Bioconda finished ******************\n' | tee --append $_logfile

# Sabre needs to be installed outside conda as the conda version does not behave correctly
echo -e '********************* sabre installation  *********************' | tee --append $_logfile
cd /opt
wget https://github.com/najoshi/sabre/archive/master.zip
unzip master.zip
mv sabre-master sabre
cd sabre
make 2>>$_logfile
cd /usr/local/bin
ln -s /opt/sabre/sabre ./sabre
echo -e '****************** sabre finished ******************\n' | tee --append $_logfile

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
apt-get install -y libxml2-dev libssl-dev libcurl4-openssl-dev libmariadb-client-lgpl-dev libssh2-1-dev seaview lftp 2>>$_logfile

apt-get install -y r-base-core r-base-dev 2>>$_logfile

# run Steve's R script to set up bioconductor
echo "* Starting to set up Bioconductor ...... *" | tee --append $_logfile

/usr/bin/Rscript <( echo "$_R_BIOCONDUCTOR_INS" ) 2>>$_logfile
echo -e '* R: Bioconductor finished *\n' | tee --append $_logfile

# get RStudio Server
echo "* Starting to download RStudio Server ...... *" | tee --append $_logfile
wget https://download2.rstudio.org/server/trusty/amd64/rstudio-server-${RSS_VER}-amd64.deb -O $BASEDIR/rstudio.deb 2>>$_logfile
gdebi --non-interactive ./rstudio.deb 2>>$_logfile
apt-get install -f 2>>$_logfile
rstudio-server verify-installation 2>>$_logfile
echo -e "* RStudio Server installation finished. Version: ${RSS_VER} *\n" >>$_logfile

# run user script
echo -e '* R: user script start *\n' | tee --append $_logfile
/usr/bin/Rscript <( echo "$R_SCRIPT") 2>>$_logfile
echo -e '* R: user script finished *\n' | tee --append $_logfile
echo -e '********************* R finished *********************\n' | tee --append $_logfile

# echo -e '****************** Installing iPython Notebook ******************\n' | tee --append $_logfile
# apt-get install -y ipython ipython-notebook  2>>$_logfile
# echo -e '*********************  iPython Notebook finished *********************\n' | tee --append $_logfile


# echo -e '********************* gophernotes begin *********************' | tee --append $_logfile
# echo "* Starting to set up gophernotes ...... *" | tee --append $_logfile

# apt-get install -y pkg-config 2>>$_logfile

# echo "deb http://download.opensuse.org/repositories/network:/messaging:/zeromq:/release-stable/xUbuntu_18.04/ ./" >> /etc/apt/sources.list
# wget https://download.opensuse.org/repositories/network:/messaging:/zeromq:/release-stable/xUbuntu_18.04/Release.key -O- | sudo apt-key add
# apt-get install libzmq3-dev

# wget https://dl.google.com/go/go1.12.7.linux-amd64.tar.gz
# tar -C /usr/local -xzf go1.12.7.linux-amd64.tar.gz 2>>$_logfile
# echo 'export PATH=$PATH:$HOME/bin:/usr/local/go/bin' >> ${_USER_HOME}/.bashrc
# echo 'export GOPATH=$HOME' >> ${_USER_HOME}/.bashrc

# # This seems to fix some of the issues with installing Jupyter
# apt-get install -y python3-pip locales 2>>$_logfile
# pip3 install jupyter 2>>$_logfile

# export PATH=$PATH:$HOME/bin:/usr/local/go/bin
# export GOPATH=${_USER_HOME}
# go version 2>>$_logfile
# go get -v github.com/gopherdata/gophernotes 2>>$_logfile
# mkdir -p ${_USER_HOME}/.local/share/jupyter/kernels/gophernotes
# cp $GOPATH/src/github.com/gopherdata/gophernotes/kernel/* ${_USER_HOME}/.local/share/jupyter/kernels/gophernotes

# chown -hR $USER_NAME:$USER_NAME ${_USER_HOME}

# # Are we still getting an error here if we specify the corect path?
# ${_USER_HOME}/bin/gophernotes 2>>$_logfile
# # I seem to get an error
# ## // warning: could not find package "github.com/cosmos72/gomacro" in $GOPATH = "/home/biotech7005", assuming package is located in "/home/biotech7005/src/github.com/cosmos72/gomacro"


# echo -e '********************* gophernotes finished *********************\n' | tee --append $_logfile


echo -e '***************Setting Up Data For the Session***************' | tee --append $_logfile

mkdir $_USER_HOME/data
echo <<EOF > /usr/local/bin/sync_data
#!/bin/bash
/bin/sleep $(/usr/bin/expr $RANDOM % 60)
lftp -e "lcd ~/data; mirror -c; exit" http://10.150.9.38/biotech/data/
EOF

echo '0-59 * * * * /usr/local/bin/sync_data' | crontab -u $USER_NAME -

# NGS_DIR="/home/$USER_NAME/NGS_Practical/01_rawData/fastq"
# mkdir -p $NGS_DIR
# wget -c https://universityofadelaide.box.com/shared/static/nqf2ofb28eao26adxxillvs561w7iy5s.gz -O "$NGS_DIR/subData.tar.gz" 2>>$_logfile
# tar xzvf $NGS_DIR/subData.tar.gz
# rm $NGS_DIR/subData.tar.gz
# mv /home/$USER_NAME/NGS_Practical/01_rawData/fastq/chr* /home/$USER_NAME/NGS_Practical
# ## Should put a file check here...

# wget -c https://universityofadelaide.box.com/shared/static/0w0fgnm94w18ixh1z0dkmh5e0xht1ajf.gz -O "$NGS_DIR/multiplexed.tar.gz" 2>>$_logfile
# tar xzvf $NGS_DIR/multiplexed.tar.gz
# rm $NGS_DIR/multiplexed.tar.gz

# # The permissions for the NGS_Practical folder need to be reset for the USER
# chown -hR $USER_NAME:$USER_NAME $_USER_HOME/NGS_Practical


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
