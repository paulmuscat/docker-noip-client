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
  ENTRYPOINTFOLDER="${ENTRYPOINTFOLDER:-/etc/dockerentrypoint}"
  ENTRYPOINTSUBFOLDER="${ENTRYPOINTSUBFOLDER:-${ENTRYPOINTFOLDER}/dockerentrypointscript.d}"
  . "${ENTRYPOINTFOLDER}/dep_shared_values"
  . "${ENTRYPOINTFOLDER}/dep_shared_functions"
  SYSLOGISRUNNING="false"

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
 if [ "${LOGTOPIPE}" = "true" ]  ; then
	 if [ ! -p "${LOGFILE}" ] ; then
		 if [ -e "${LOGFILE}" ] ; then
			 mv "${LOGFILE}" "${LOGFILE}.old" ;
			 lognotice "${MSG_MOVEOLDLOG}" ;
		  fi
		  mkfifo ${LOGFILE} ;
	 fi
	 echo "${SYSLOGDPIPECONF}" > "${SYSLOGDCONFFILE}" ;
 else
	if [ -e "${LOGFILE}" ] ; then
		mv "${LOGFILE}" "${LOGFILE}.old" ;
		lognotice "${MSG_MOVEOLDLOG}" ;
	fi
	echo "${SYSLOGDFILECONF}" > "${SYSLOGDCONFFILE}" ;
 fi

# ####################################################################
# Check syslogd is already running in case script is invoked in a
# context other than initial container startup, otherwise start it.
if  selfstartifnotrunningandcheck "${SYSLOGDAEMON}" "${SYSLOGDAEMON}" "3" ; then
       SYSLOGISRUNNING="true"
else
       SYSLOGISRUNNING="false"
fi

# ####################################################################
# Run the subordinate scripts from the designated folder; any
# script ending ".sh" will be run as root on startup. careful now.
# Outside the context of a container this would be a very bad idea.
#
  loginfo "${MSG_SUBSCRIPTINITIAL}" ;
  export ENTRYPOINTFOLDER ENTRYPOINTSUBFOLDER SYSLOGISRUNNING LOGFILE ;
  for file in ${ENTRYPOINTSUBFOLDER}/*.sh; do
      if [ -e "${file}" ] && [ -x "${file}" ] ; then
		 loginfo "${MSG_SUBSCRIPTFOUND} $(basename ${file})..." ;
		 ("${file}") ;
      fi
  done

# ####################################################################
# If we aren't already running tail -f against the syslogd output,
# start it now. Using 'exec' replaces the currently running script,
# which should normally be running as pid 1 - this is what Docker
# tracks to determine whether to keep the container alive.
#
#  if  ps | grep -vi -e 'grep' -e '\['  | grep -iq "tail -f ${LOGFILE}" ; then
#	   loginfo "${MSG_LOGTAILRUNNING} ${LOGFILE}..." ;
#  else
#	   loginfo "${MSG_LOGTAILTRY} ${LOGFILE}..." ;
#	   exec tail -f ${LOGFILE} ;
#  fi
  selfstartifnotrunningandcheck "tail -f ${LOGFILE}"  "exec tail -f ${LOGFILE}" "0" ;

# ####################################################################
# Note: anything added beyond this point will only be executed if
# this script is called outside the context of initial startup.
#