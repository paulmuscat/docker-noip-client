#!/bin/sh
# ####################################################################
# Docker entrypoint subscript for noip update container. 
# Assumes running on Alpine with default build.
# Checks for existence of noip client config file: 
# If not found then directs user to log in and run configuration;
# If found, uses the client to dispaly the current config.
#
# echo "$(date -Is) ${HOSTNAME} ${0} is running..."
  CONFIGFILE=/usr/local/etc/no-ip2.conf 


  if [ -e ${CONFIGFILE} ] ; 
      then 
           echo "$(date -Is) ${HOSTNAME} Config file found at \
           ${CONFIGFILE} indicates noip client config has been \
           performed previously:" ; 
           noip2 -S ; 
           echo "Please log in with an interactive shell \
           and run 'noip2 -C' if you need to reconfigure the client"
      else 
           echo "$(date -Is) ${HOSTNAME} No config file found at \
           ${CONFIGFILE} - please log in with an interactive shell \
           and run 'noip2 -C' to configure client. Once the \
           configuration has been run the client can be invoked \
           manually and\\or the container can be stopped \
           (the client will be started automatically next time the \
           container is restarted)"  ; 
  fi 

