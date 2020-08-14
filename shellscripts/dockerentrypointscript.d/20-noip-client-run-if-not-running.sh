#!/bin/sh
# ###################################################################
# Docker entrypoint subscript for noip update container.
# Assumes running on Alpine with default build.
# Checks for running noip client config file; if not found then
# attempts to run the client (if configured) as an unprivileged user
# and checks for success.
#
  ENTRYPOINTFOLDER="${ENTRYPOINTFOLDER:-/etc/dockerentrypoint}"
  ENTRYPOINTSUBFOLDER="${ENTRYPOINTSUBFOLDER:-${ENTRYPOINTFOLDER}/dockerentrypointscript.d}"
  . "${ENTRYPOINTFOLDER}/dep_shared_values"
  . "${ENTRYPOINTFOLDER}/dep_shared_functions"

  MSG_NCONFIGYET="Configuration file not found at ${NOIPCONFIGFILE}, so not attempting to run client."

# If it looks like config has already been done, check if the
# client is already running - try to start it if it isn't.
#
  if [ -e "${NOIPCONFIGFILE}" ] ; then
      selfstartifnotrunningandcheck "${NOIPCLIENT}" "${NOIPBINARY}" "3" ;
  # separate script should cover the else fork.
  else
     loginfo "${MSG_NCONFIGYET}"
  fi
