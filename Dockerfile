FROM alpine:3.19

# install packages
RUN apk upgrade --no-cache \
        && apk add --no-cache \
        amavis clamav-daemon clamav-libunrar gpg-agent unzip p7zip perl-io-socket-ssl razor spamassassin \
        s6 setpriv \
	# clamav should log to syslog
	&& echo "LogSyslog yes" >>/etc/clamav/clamd.conf \
	&& echo "LogSyslog yes" >>/etc/clamav/freshclam.conf 

# add the custom configurations
COPY rootfs/ /

# quarantine folder for mails
VOLUME /var/amavis/quarantine

# spamassassin rules (cache them)
VOLUME /var/amavis/.spamassassin

# razor identity
VOLUME /var/amavis/.razor

CMD [ "/entrypoint.sh" ]

