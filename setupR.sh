#/bin/bash

# This script needs to be run as superuser

# Add the repo to source.list
echo "deb http://cran.rstudio.com/bin/linux/ubuntu xenial/" | tee -a /etc/apt/sources.list

# Setup the keyserver. Not sure if this runs from inside a script...
gpg --keyserver keyserver.ubuntu.com --recv-key E084DAB9
gpg -a --export E084DAB9 | sudo apt-key add -

# Install the latest version of R
apt-get update
apt-get install libcurl4-openssl-dev libssl-dev libxml2-dev
apt-get install r-base r-base-dev

# Installing R-Studio. Check the version number first 
RSVERS=1.1.383
wget https://download1.rstudio.org/rstudio-${RSVERS}-amd64.deb
gdebi --n rstudio-${RSVERS}-amd64.deb
rm rstudio-${RSVERS}-amd64.deb

# Setup RStudio Server
wget https://download2.rstudio.org/rstudio-server-${RSVERS}-amd64.deb
gdebi --n rstudio-server-${RSVERS}-amd64.deb
rm rstudio-server-${RSVERS}-amd64.deb
