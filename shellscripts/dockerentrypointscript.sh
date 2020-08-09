#!/bin/sh 
# ####################################################################
# Docker entrypoint script. 
# Assumes running on Alpine with default build.
# Ensures syslogd is running and writing to message log.
# Runs through any scripts placed in the designated subfolder.
# Finally runs "tail -f" against the logfile - this keeps the 
# container alive until killed, and ensures any logged messages 
# are available to Docker.
#

  LOGFILE=/var/log/messages 
  SYSLOGDCONFFILE=/etc/syslog.conf
  ENTRYPOINTSUBFOLDER=$(dirname ${0})/dockerentrypointscript.d 
  SYSLOGDCONF="*.*                            |${LOGFILE}"
  
  echo "$(date -Is) ${HOSTNAME} is up and ${0} is running..." 
 
# ####################################################################
# Message log remains in default busybox location but replaced by a 
# named  pipe  - no point in storing the data in the container when 
# Docker will hold a copy.
# We need to expicitly tell busybox that the output object is a pipe 
# via the syslogd configuration or it will hang.
# You can comment out the next two lines to use a persistent file 
# to hold the logger output instead
#
    mkfifo ${LOGFILE} ; 
    echo "${SYSLOGDCONF}" > "${SYSLOGDCONFFILE}" ; 


# ####################################################################
# Check syslogd is already running in case script is invoked in a 
# context other than initial container startup.
#
  if  ps | grep -v grep | grep -iq syslogd ; 
      then 
           echo "$(date -Is) ${HOSTNAME} An instance of syslogd \
                  appears to already be running..." ; 
      else 
           echo "$(date -Is) ${HOSTNAME} Syslogd does not seem to be \
                  running. Attempting to start syslogd" ; 
           syslogd ; 
           sleep 1;
           if ps | grep -v grep | grep -iq syslogd ; 
               then
                    echo "$(date -Is) ${HOSTNAME} Syslogd is now \
                           running."
               else
                    echo "$(date -Is) ${HOSTNAME} Something \
                          seens to have gone wrong there: \
                          Syslogd is still not running!"
           fi
  fi 

# ####################################################################
# Run the subordinate scripts from the designated folder; any 
# script ending ".sh" will be run as root on startup. careful now.
# Outside the context of a container this would be a very bad idea.
#
  echo "$(date -Is) ${HOSTNAME} looking for scripts in \
         ${ENTRYPOINTSUBFOLDER} and running any we find..." ; 
  for file in ${ENTRYPOINTSUBFOLDER}/*.sh; do 
      if [ -e "${file}" ] && [ -x "${file}" ] ; 
         then 
             echo "$(date -Is) ${HOSTNAME} Found ${file}"... ;     
             ("${file}") ; 
      fi 
  done 

# ####################################################################
# If we aren't already running tail -f against the syslogd output, 
# start it now. Using 'exec' replaces the currently running script, 
# which should normally be running as pid 1 - this is what Docker 
# tracks to determine whether to keep the container alive.
#
   if  ps | grep -v grep | grep -iq "tail -f ${LOGFILE}" ; 
      then 
           echo "$(date -Is) ${HOSTNAME} tail already following \
                  ${LOGFILE}..." ; 
      else 
           echo "$(date -Is) ${HOSTNAME} Executing tail -f against \
                   ${LOGFILE}..." ; 
           exec tail -f ${LOGFILE} ; 
  fi  

# ####################################################################
# Note: anything added beyond this point will only be executed if 
# this script is called outside the context of initial startup.
#
  

