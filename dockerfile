## Container based noip update client
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

COPY --from=builder ${INDIR}/${NOIPCLIENTBIN} ${NOIPCLIENTBINDEST}/
RUN chmod 700 ${NOIPCLIENTBINDEST}/${NOIPCLIENTBIN}
RUN mkdir ${CONFDIR}
WORKDIR /

RUN noip2 -h



