#!/bin/sh
# ####################################################################
# Docker entrypoint subscript for noip update container. 
# Assumes running on Alpine with default build.
# Assumes called from dockerentrypointscript.
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
  ENTRYPOINTFOLDER="${ENTRYPOINTFOLDER:-/etc/dockerentrypoint}"
  ENTRYPOINTSUBFOLDER="${ENTRYPOINTSUBFOLDER:-${ENTRYPOINTFOLDER}/dockerentrypointscript.d}"
  . "${ENTRYPOINTFOLDER}/dep_shared_values"
  . "${ENTRYPOINTFOLDER}/dep_shared_functions"

#  NOIPCONFIGFILE="/usr/local/etc/no-ip2.conf"
#  NOIPUSER="noipuser"
#  NOIPCLIENT="noip2"
#  NOIPBINARY="/usr/local/bin/${NOIPCLIENT}"
  MSG_UEXISTS="${NOIPUSER} already exists."
  MSG_UTRY="${NOIPUSER} not found: attempting to create as an unprivileged user."
  MSG_UCREATED="${NOIPUSER} created successfully."
  MSG_UFAILED="Something has gone wrong - failed to create user ${NOIPUSER}."
  MSG_NCONFIGFOUND="Configuration file found at ${NOIPCONFIGFILE}.
This indicates that ${NOIPCLIENT} configuration has been performed previously.
Please log in with an interactive shell and run '${NOIPCLIENT} -C' if you need to reconfigure the client.
The current cofiguration is as follows: "
  MSG_NCONFIGNOTFOUND="No config file found at ${NOIPCONFIGFILE}.
Please log in with an interactive shell and run '${NOIPCLIENT} -C' to configure client.
Once the configuration has been run the client can be invoked  manually and/or the container can be stopped.
(Once configured, the client will be started automatically when the container is restarted.)"

# ####################################################################
# Check if user we want to run as has been set up...
#
  if getent passwd | cut -d : -f1 | grep -iq ${NOIPUSER} ; then
	  loginfo "${MSG_UEXISTS}" ;
  else
	  loginfo "${MSG_UTRY}" ;
	  adduser -D -H ${NOIPUSER};
	  if getent passwd | cut -d : -f1 | grep -iq ${NOIPUSER} ; then
		  lognotice "${MSG_UCREATED}" ;
	  else
		  logerror "${MSG_UFAILED}" ;
	  fi
  fi

# ####################################################################
# Check if cofig file already exists: if it doesn't we need the user
# to log in to supply details; Prompt them to do so
#
  if [ -e ${NOIPCONFIGFILE} ] ; then
	   loginfo "${MSG_NCONFIGFOUND}" ;
	   (${NOIPCLIENT} -S) ;
	   if [ $(stat -c %U  ${NOIPCONFIGFILE}) != "${NOIPUSER}" ] ; then
		   chown ${NOIPUSER} ${NOIPCONFIGFILE} ;
	   fi
	   if [ $(stat -c %U ${NOIPBINARY} ) != "${NOIPUSER}" ] ; then
		   chown ${NOIPUSER} ${NOIPBINARY} ;
	   fi
  else
	   logwarning "${MSG_NCONFIGNOTFOUND}"  ;
  fi
