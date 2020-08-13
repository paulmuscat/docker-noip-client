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
  LOGFILE="${LOGFILE:-/var/log/messages}" 
  SYSLOGDCONFFILE="${SYSLOGDCONFFILE:-/etc/syslog.conf}"
  SYSLOGDAEMON="${SYSLOGDAEMON:-syslogd}"
  SYSLOGDPIPECONF="${SYSLOGDPIPECONF:-*.*                            |${LOGFILE}}"
  SYSLOGDFILECONF="${SYSLOGDFILECONF:-*.*                             ${LOGFILE}}"
  LOGTOPIPE="${LOGTOPIPE:-true}"

  SYSLOGISRUNNING="false"   
  ENTRYPOINTSUBFOLDER=$(dirname ${0})/dockerentrypointscript.d 
   

# ####################################################################
# Userland strings
#
  MSG_INITIALLOAD="is up and ${0} is running..."
  
  MSG_MOVEOLDLOG="Found existing ${LOGFILE} - renaming as ${LOGFILE}.old"

  MSG_LOGRUNNING="An instance of ${SYSLOGDAEMON} appears to already be running..."
  MSG_LOGNOTRUNNINGTRY="${SYSLOGDAEMON} does not seem to be running. Attempting to start ${SYSLOGDAEMON}."
  MSG_LOGRUNTRYSUCCESS="${SYSLOGDAEMON} is now running."
  MSG_LOGRUNTRYFAILURE="Something seens to have gone wrong there: ${SYSLOGDAEMON} is still not running!"

  MSG_SUBSCRIPTINITIAL="looking for scripts in ${ENTRYPOINTSUBFOLDER} and running any we find..."
  MSG_SUBSCRIPTFOUND="Found executable file:"  
  
  MSG_LOGTAILRUNNING="tail already running follow against"
  MSG_LOGTAILTRY="Executing tail -f against"
  
# ####################################################################
# If the logger daemon is running output to that. If we're going to 
# use a file, write directly to that - otherwise, if we're going to 
# output to a pipe, echo direct to the console. (Writing to a named 
# pipe that has nothing reading it will halt execution.) 
# In normal expected use it makes no difference but using the logger 
# where possible gives us the option of using the logging service's
# capacity to filter on severity and forward to network services, 
#

  logswitch(){
  # Call as "logswitch [severity#] message"
  # If the first value is an integer it is interpereted as the 
  # required severity; anything at ERRORLIMIT or less is copied
  # to stderr.  
  # If the syslog daemon is running, logs to syslog as user, 
  # informational. otherwise tries to write direct to the logfile
  # and failing that, echoes to the console. 
  # (see RFC 5424 for the magic numbers for severity).

	  SEVERITY="5" # default is notice
	  ERRORLIMIT="4" # warning
	  ECHOPREFIX="$(date -Is) ${HOSTNAME}"
	  # validate severity 0..7 (emergency..debug)
	  if echo "${1}" | grep -i -q '^[0-7]$' ;
		  then 
			  SEVERITY="${1}";
			  shift; 
	  fi
  
	  if [ "${SYSLOGISRUNNING}" = "true" ] ; #logger running
		  then
			  logger -p "${SEVERITY}" "${@}";
		  else
          # Important: only try to write to logfile directly if a 
          # real file, not a pipe!
		  if [ -f "${LOGFILE}" ] ; # is a regular file, exists
			  then
				  echo "${ECHOPREFIX} ${@}" >> "${LOGFILE}" ;
			   else   
			   # above error threshold stdout. (Below threhold goes 
			   # to stderr always anyway - no need to see it twice
			   if [ "${SEVERITY}" -gt "${ERRORLIMIT}" ] ;
				   then
					   echo "${ECHOPREFIX} ${@}" ;
			   fi
		  fi  
	  fi               
	  
	  if [ "${SEVERITY}" -le "${ERRORLIMIT}" ] ; 
	  # at or below error threshold always echo to stderr
		  then
			  echo "${ECHOPREFIX} ${@}" 1>&2;
	  fi      
  }
  
  # curried...  
  logerror(){
      logswitch "3" "${@}" 
  }
 
  lognotice(){
      logswitch "5" "${@}" 
  }
    
  loginfo(){
      logswitch "6" "${@}" 
  }

# ####################################################################  
  
  loginfo "${MSG_INITIALLOAD}" 
 
# ####################################################################
# Message log remains in default busybox location but replaced by a 
# named  pipe  - no point in storing the data in the container when 
# Docker will hold a copy.
# We need to expicitly tell busybox that the output object is a pipe 
# via the syslogd configuration or it will hang.
# You can comment out the next two lines to use a persistent file 
# to hold the logger output instead
#
 if [ "${LOGTOPIPE}" = "true" ]  ;
     then
         if [ ! -p "${LOGFILE}" ] ;
             then 
                 if [ -e "${LOGFILE}" ] ;
                     then 
                         mv "${LOGFILE}" "${LOGFILE}.old" ;
                         lognotice "${MSG_MOVEOLDLOG}" ;
                  fi                  
                  mkfifo ${LOGFILE} ;
         fi 
         echo "${SYSLOGDPIPECONF}" > "${SYSLOGDCONFFILE}" ; 
     else         
         if [ -e "${LOGFILE}" ] ;
            then 
                mv "${LOGFILE}" "${LOGFILE}.old" ;
                lognotice "${MSG_MOVEOLDLOG}" ;
        fi 
        echo "${SYSLOGDFILECONF}" > "${SYSLOGDCONFFILE}" ; 
 fi
    
# ####################################################################
# Check syslogd is already running in case script is invoked in a 
# context other than initial container startup.
#
  if  ps | grep -v grep | grep -v '\[' | grep -iq ${SYSLOGDAEMON} ; 
      then 
           SYSLOGISRUNNING="true";   
           loginfo "${MSG_LOGRUNNING}" ; 
      else 
           SYSLOGISRUNNING="false";
           lognotice "${MSG_LOGNOTRUNNINGTRY}" ; 
           syslogd ; 
           sleep 1;
           if ps | grep -v grep | grep -v '\[' | grep -iq ${SYSLOGDAEMON} ; 
               then
                    SYSLOGISRUNNING="true";
                    loginfo "${MSG_LOGRUNTRYSUCCESS}"
               else
                    logerror "${MSG_LOGRUNTRYFAILURE}" 
           fi
  fi 

# ####################################################################
# Run the subordinate scripts from the designated folder; any 
# script ending ".sh" will be run as root on startup. careful now.
# Outside the context of a container this would be a very bad idea.
#
  loginfo "${MSG_SUBSCRIPTINITIAL}" ; 
  for file in ${ENTRYPOINTSUBFOLDER}/*.sh; do 
      if [ -e "${file}" ] && [ -x "${file}" ] ; 
         then 
             loginfo "${MSG_SUBSCRIPTFOUND} ${file}..." ;     
             ("${file}") ; 
      fi 
  done 

# ####################################################################
# If we aren't already running tail -f against the syslogd output, 
# start it now. Using 'exec' replaces the currently running script, 
# which should normally be running as pid 1 - this is what Docker 
# tracks to determine whether to keep the container alive.
#
   if  ps | grep -v grep | grep -v '\[' | grep -iq "tail -f ${LOGFILE}" ;
      then 
           loginfo "${MSG_LOGTAILRUNNING} ${LOGFILE}..." ; 
      else 
           loginfo "${MSG_LOGTAILTRY} ${LOGFILE}..." ; 
           exec tail -f ${LOGFILE} ; 
  fi  

# ####################################################################
# Note: anything added beyond this point will only be executed if 
# this script is called outside the context of initial startup.
#
  

