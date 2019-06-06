#!/bin/bash

# Script to generate a ssh key pair and run a webserver to share the public key within a period of time
# Simple automation for setup root ssh equivalence on a brand new OCP cluster
# This code to be run as root on the admin node as one time execution when it is built 
# Use at your own risk

# https://github.com/brito-rafa/ocp-tools

# Dependencies: python and SimpleHTTPServer module

# Parameters
# set your ssh key name if you do not want the default
# script will only create the key if it does not exist
SSH_KEY_NAME=~/".ssh/id_rsa"

# How long this script will serve the pub key (in seconds) - one day is 86400.
# If set to 0 or variable unset, script will never kill webserver
#AVAILABLE_KEY_TIME="0" # do not kill webserver
#AVAILABLE_KEY_TIME="86400"
AVAILABLE_KEY_TIME="60"

# http port (nodes will need to know this port to collect the pubkey)
HTTP_PORT=6666

# non-privilege user to run the webserver. If not set, webserver will run as root
# needs to be coded
#NON_PRIV_USER=whatever

# temp directory for the webserver (please never serve the public key on the same directory of the private key)
TEMP_DIR=/tmp/adminpubkey


# check if we are running as root. If not, exit
if [ "$EUID" -ne 0 ]; then
  echo "This script needs to be executed as root"
  exit 1
fi

# generate the key if it does not exist
if [ ! -f $SSH_KEY_NAME ]; then
  ssh-keygen -N '' -f $SSH_KEY_NAME
fi

# setup the directory and copy key
mkdir -p $TEMP_DIR
cp -p ${SSH_KEY_NAME}.pub $TEMP_DIR

# start webserver in background as a non privileged user (TBD)
cd $TEMP_DIR
python -m SimpleHTTPServer $HTTP_PORT &
export WEBPID=$!

# Kill webserver only if parameter AVAILABLE_KEY_TIME is not "0"
if [ ! ${AVAILABLE_KEY_TIME} = "0" ]; then
  $(sleep $AVAILABLE_KEY_TIME; kill $WEBPID) &
fi


########## on the nodes, as root, run the following. replace "admin-node" for the ip or hostname of the admin node
# HTTP_PORT=6666
# SSH_KEY_PUBNAME="id_rsa.pub"
# curl http://admin-node:${HTTP_PORT}/${SSH_KEY_PUBNAME} >> ~/.ssh/authorized_keys
# chmod 0600 ~/.ssh/authorized_keys
##########
