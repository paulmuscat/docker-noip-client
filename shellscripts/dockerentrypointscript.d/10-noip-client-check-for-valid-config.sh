#!/bin/sh
# ####################################################################
# Docker entrypoint subscript for noip update container. 
# Assumes running on Alpine with default build.
# Performs user config if necessary and then checks for existence of 
# noip client config file, and fixes any ownership issues - running
# config as root will otherwise cause problems.
# User setup could be offloaded to the dockerfile, but neater to keep
# everything together here, I think, and allows for these scripts to 
# be reused in non-container contexts. 
# If expected config file not found then directs user to log in and 
# run configuration;
# If found, uses the client to display the current config.
# Note - by default Alpine use busybox for standard posix functions
# runs as root, and has no sudo.
# Obviously if you set NOIPUSER to root, it will run as root instead. 
#
# echo "$(date -Is) ${HOSTNAME} ${0} is running..."
  CONFIGFILE=/usr/local/etc/no-ip2.conf 
  NOIPUSER=noipuser
  NOIPCLIENT=noip2
  NOIPBINARY=/usr/local/bin/${NOIPCLIENT}

  if getent passwd | cut -d : -f1 | grep -iq ${NOIPUSER} ;
      then
          echo "$(date -Is) ${HOSTNAME} ${NOIPUSER} already exists" ;
      else
          echo "$(date -Is) ${HOSTNAME} ${NOIPUSER} not found: \
                 attempting to create unprivileged user" ;
          adduser -D -H ${NOIPUSER};

          if getent passwd | cut -d : -f1 | grep -iq ${NOIPUSER} ;
              then
                  echo "$(date -Is) ${HOSTNAME} ${NOIPUSER} created"
              else
                  echo "$(date -Is) ${HOSTNAME} something has gone \
                         wrong - failed to create ${NOIPUSER}" 
          fi
  fi

  if [ -e ${CONFIGFILE} ] ; 
      then 
           echo "$(date -Is) ${HOSTNAME} Config file found at \
           ${CONFIGFILE} indicates noip client config has been \
           performed previously:" ; 
           (${NOIPCLIENT} -S) ; 
           echo "Please log in with an interactive shell \
           and run '${NOIPCLIENT} -C' if you need to reconfigure the client"

           if [ $(stat -c %U  ${CONFIGFILE}) != "${NOIPUSER}" ] ;
               then 
                   chown ${NOIPUSER} ${CONFIGFILE} ;
           fi

           if [ $(stat -c %U ${NOIPBINARY} ) != "${NOIPUSER}" ] ;
               then 
                   chown ${NOIPUSER} ${NOIPBINARY} ;
           fi
      else 
           echo "$(date -Is) ${HOSTNAME} No config file found at \
           ${CONFIGFILE} - please log in with an interactive shell \
           and run '${NOIPCLIENT} -C' to configure client. Once the \
           configuration has been run the client can be invoked \
           manually and\\or the container can be stopped \
           (the client will be started automatically next time the \
           container is restarted)"  ; 
  fi 

