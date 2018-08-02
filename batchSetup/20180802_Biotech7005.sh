#!/bin/bash

# This is a setup script to launch multiple instances, each with a unique user and password
# The default is to take a list of usernames and create instances with these as users.
# The passowrd will initially be set as the username, and each user will be asked to manually
# reset their password at the first login

# The basic instantiation script file will be taken from a master config file,
# then reauthored for each instance using the custom username.
# These will be stored temporarily in the ./tmp folder, then deleted on completion of the script

###############################################
#      THIS SCRIPT FAILS. DO NOT RUN          #
###############################################

ROOTDIR=/home/steveped/vm_admin
IMAGEDIR=${ROOTDIR}/images
TMPDIR=${ROOTDIR}/tmp
LOGFILE=${ROOTDIR}/logs/20180802_Biotech7005.log

# Set the common parameters
IMAGE="ubuntu-server-16.04-lts"
KEYNAME="hub"
FLAVOUR="m4.large"
NETWORK="uofa_internal"
SECURITY1="linux-server"
SECURITY2="rstudio"
BASESCRIPT=${IMAGEDIR}/2018_Biotech7005.sh # This will be rewritten multiple times
CLOUD="m.biotech"

echo "Starting instantiation" > ${LOGFILE}

# Now step through each ID and create an instance
for ID in a1018048
do

  cp ${BASESCRIPT} ${TMPDIR}/${ID}.sh
  sed -i "s/USER_NAME=.*/USER_NAME=${ID}/g" ${TMPDIR}/${ID}.sh
  echo "Creating Instance for ${ID}" | tee --append ${LOGFILE}

  echo "openstack --os-cloud=${CLOUD} server create \
   --image ${IMAGE} \
   --flavor ${FLAVOUR} \
   --key-name ${KEYNAME} \
   --file dest-filename=${TMPDIR}/${ID}.sh \
   --network ${NETWORK} \
   --security-group ${SECURITY1} \
   --security-group ${SECURITY2} \
   "Biotech7005_"${ID} 2>> ${LOGFILE}"

  exit

  echo "Instance created for ${ID}" | tee --append ${LOGFILE}
done

echo "Creating a list of instances" | tee --append ${LOGFILE}
openstack --os-cloud=${CLOUD} server list -f csv > instances.csv

echo "Removing temporary scripts" | tee --append ${LOGFILE}
#rm $TMPDIR/*sh
