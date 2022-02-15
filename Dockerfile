FROM alpine:3.15

# install packages
RUN apk upgrade --no-cache \
        && apk add --no-cache \
        amavis clamav-daemon clamav-libunrar unzip p7zip perl-db perl-io-socket-ssl razor spamassassin \
        s6 setpriv \
	# clamav should log to syslog
	&& echo "LogSyslog yes" >>/etc/clamav/clamd.conf \
	&& echo "LogSyslog yes" >>/etc/clamav/freshclam.conf 

# add the custom configurations
COPY rootfs/ /

CMD [ "/entrypoint.sh" ]

