#!/bin/bash -l

apt-get install xubuntu-desktop

add-apt-repository ppa:x2go/stable
apt-get update
apt-get install x2goserver x2goserver-xsession
