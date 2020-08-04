## Container based noip update client
# for an externally configurable alternative see https://github.com/coppit/docker-no-ip
# however this is intended as a simpler, slightly more secure version;
# I didn't want to have to use ENV or files to pass credentials, 
# and using a Docker Secrets was slightly overkill for my use case.
# On first deploy 'run -td' , and then exec an interactive shell and 
# execute 'noip2 -C' for an interactive setup
# then 'noip2 -d' to start the daemon running
 
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
RUN mkdir ${OUTDIR}
RUN cp ${NOIPCLIENTBIN} ${OUTDIR}

FROM alpine:latest
ARG NOIPCLIENTBIN=noip2
ARG NOIPCLIENTBINDEST=/usr/local/bin
ARG INDIR=/outbox
ARG CONFDIR=/usr/local/etc
ARG MESSAGELOG=/var/log/messages

COPY --from=builder ${INDIR}/${NOIPCLIENTBIN} ${NOIPCLIENTBINDEST}/
RUN chmod 700 ${NOIPCLIENTBINDEST}/${NOIPCLIENTBIN}
RUN mkdir ${CONFDIR}
RUN ln -sf /dev/stdout ${MESSAGELOG}
WORKDIR /

RUN syslogd
RUN noip2 -h


