## Container based noip update client
# for an externally configurable alternative see https://github.com/coppit/docker-no-ip
# however this is intended as a simpler, slightly more secure version;
# I didn't want to have to use ENV or files to pass credentials, 
# and using a Docker Secrets was slightly overkill for my use case.
# On first deploy 'run -td' , and then exec an interactive shell and 
# execute 'noip2 -C' for an interactive setup
 
# ##########################################
FROM alpine:latest As builder
# ##########################################

ARG OUTDIR=/outbox 
ARG NOIPCLIENTURL=https://www.noip.com/client/linux/noip-duc-linux.tar.gz 
ARG NOIPCLIENTTAR=noip-2.1.9-1
ARG NOIPCLIENTBIN=noip2
ARG NOIPCLIENTBINDEST=/usr/local/bin

WORKDIR /tmp
RUN apk --no-cache add make gcc musl-dev
RUN wget -O - ${NOIPCLIENTURL} |  tar x -z
WORKDIR /tmp/${NOIPCLIENTTAR}
RUN make
RUN mkdir ${OUTDIR} ; \
    cp ${NOIPCLIENTBIN} ${OUTDIR} ;

# ##########################################
FROM alpine:latest
# ##########################################
ARG NOIPCLIENTBIN=noip2
ARG NOIPCLIENTBINDEST=/usr/local/bin
ARG INDIR=/outbox
ARG CONFDIR=/usr/local/etc
ARG MESSAGELOG=/var/log/messages
ARG ENTRYPOINTSCRIPT=/entrypoint.sh

WORKDIR /
COPY --from=builder ${INDIR}/${NOIPCLIENTBIN} ${NOIPCLIENTBINDEST}/

RUN chmod 700 ${NOIPCLIENTBINDEST}/${NOIPCLIENTBIN} ; \
    mkdir ${CONFDIR} ; \
    noip2 -h ;

# ##########################################
# building an entrypoint script the hard way - avoiding copy to keep everything in the one dockerfile
RUN echo '#!/bin/sh' > ${ENTRYPOINTSCRIPT}
RUN echo '' >> entrypoint.sh ; \
    echo 'CONFIGFILE=/usr/local/etc/no-ip2.conf' >> entrypoint.sh ; \
    echo 'LOGFILE=/var/log/messages' >> entrypoint.sh ; \
    echo '' >> entrypoint.sh ; \
    echo 'echo ...started container... > ${LOGFILE}' >> entrypoint.sh ; \
    echo '' >> entrypoint.sh ; \
    echo 'noip2 -h' >> entrypoint.sh ; \
    echo '' >> entrypoint.sh ; \
    echo 'if [ -e ${CONFIGFILE} ]  ; ' >> entrypoint.sh ; \
    echo '   then echo config done previously ; noip2 -S ; ' >> entrypoint.sh ; \
    echo '   else echo please log in with an interactive shell and run noip2 -C to configure client ; ' >> entrypoint.sh ; \
    echo 'fi' >> entrypoint.sh ; \
    echo 'if  ps | grep -v grep | grep -i syslogd  ; ' >> entrypoint.sh ; \
    echo '    then echo syslogd already running... ; ' >> entrypoint.sh ; \
    echo '    else echo starting syslogd; syslogd -O ${LOGFILE} ; ' >> entrypoint.sh ; \
    echo 'fi' >> entrypoint.sh ; \
    echo 'if  ps | grep -v grep | grep -i noip2 ; ' >> entrypoint.sh ; \
    echo '    then echo noip client already running... ; ' >> entrypoint.sh ; \
    echo '    else if [ -e ${CONFIGFILE} ] ; ' >> entrypoint.sh ; \
    echo '         then echo starting noip client...; noip2; ' >> entrypoint.sh ; \
    echo '         fi ; ' >> entrypoint.sh ; \
    echo 'fi' >> entrypoint.sh ; \
    echo 'if  ps | grep -v grep | grep -i tail ; ' >> entrypoint.sh ; \
    echo '    then echo tail already running... ; ' >> entrypoint.sh ; \
    echo '    else echo starting tail as pid 1; ' >> entrypoint.sh ; \
    echo '    exec tail -f /var/log/messages  ; ' >> entrypoint.sh ; \
    echo 'fi  # no run expected beyond this point normally' >> entrypoint.sh ; \  
    chmod +x ${ENTRYPOINTSCRIPT} ; 

RUN ls -l
RUN cat ${ENTRYPOINTSCRIPT}

ENTRYPOINT ${ENTRYPOINTSCRIPT}
