#!/bin/bash -l

# Add new student user and add that user to the sudo group
useradd --shell /bin/bash --create-home --comment "UofA Bioinformatics Hub" hub
echo -e "hub:hub" | chpasswd
usermod -aG sudo hub
chown --recursive hub:hub /home/hub/

# Add new PATH variables
echo 'export PATH="${PATH}:/opt/local/IGV:/opt/local/bin:/opt/local/bcftools:/opt/local/samtools:/opt/local/Salmon-latest_linux_x86_64/bin:/opt/local/sambamba/build:/opt/local/kallisto:/opt/local/hisat2:/opt/local/bowtie2:/opt/local/tophat:/opt/local/cufflinks:/opt/local/bwa:/opt/local/sratoolkit:/opt/local/stringtie:/opt/local/ucsc-tools"' >> ${HOME}/.bashrc
