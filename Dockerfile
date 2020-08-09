# ####################################################################
# Container based No-IP update client, based on Alpine linux and the 
# official No-IP linux client.
# For an externally configurable alternative I strongly suggest using 
# https://github.com/coppit/docker-no-ip instead.
# This version is intended as a personal learning exercise, as well 
# as hopefully resulting in a slightly more secure implementation; 
# I wasn't comfortable with using ENV or files to pass credentials, 
# and using a Docker Secrets was slightly overkill for my use case.
# On first deploy 'run -td' , and then exec an interactive shell and 
# execute 'noip2 -C' for an interactive setup.
#
 
# ####################################################################
# Build stage 
#
FROM alpine:latest As builder

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

# ####################################################################
# Run stage 
#
FROM alpine:latest

ARG NOIPCLIENTBIN=noip2
ARG NOIPCLIENTBINDEST=/usr/local/bin
ARG INDIR=/outbox
ARG CONFDIR=/usr/local/etc
ARG ENTRYPOINTFOLDER=/etc/dockerentrypoint

WORKDIR /
COPY --from=builder ${INDIR}/${NOIPCLIENTBIN} ${NOIPCLIENTBINDEST}/
RUN chmod 700 ${NOIPCLIENTBINDEST}/${NOIPCLIENTBIN} ; \
    mkdir ${CONFDIR} ; \ 
    mkdir ${ENTRYPOINTFOLDER} ;\
    noip2 -h ;

COPY shellscripts ${ENTRYPOINTFOLDER}
RUN chmod -R -v +x ${ENTRYPOINTFOLDER} ; 

# ENTRYPOINT has to be declared as literal - can't use ARG values.
ENTRYPOINT /etc/dockerentrypoint/dockerentrypointscript.sh
