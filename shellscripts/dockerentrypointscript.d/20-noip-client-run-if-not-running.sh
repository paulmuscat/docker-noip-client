#!/bin/sh
# ####################################################################
# Docker entrypoint subscript for noip update container. 
# Assumes running on Alpine with default build.
# Checks for running noip client config file; if not found then 
# attempts to run the client (if configured) and checks for success.
#
# echo "$(date -Is) ${HOSTNAME} ${0} is running..."
  CONFIGFILE=/usr/local/etc/no-ip2.conf 
  CLIENTNAME=noip2

  if ps | grep -v grep | grep -iq ${CLIENTNAME} ; 
      then 
           echo "$(date -Is) ${HOSTNAME} An instance of the \
           noip update client appears to be running already.";
      else if [ -e ${CONFIGFILE} ] ;
               then 
                   echo "$(date -Is) ${HOSTNAME} Noip client \
                          does not appear to be running. \
                          Attempting to start noip client..." ; 
                   ${CLIENTNAME} ;
                   sleep 4;
                   if ps | grep -v grep | grep -iq ${CLIENTNAME} ; 
                       then
                           echo "$(date -Is) ${HOSTNAME} Noip \
                                 client now running."
                       else
                           echo "$(date -Is) ${HOSTNAME} Something \
                                 seens to have gone wrong there: \
                                 Noip client is still not running."
                   # separate script should cover the else fork. 
                   fi
           fi

  fi

