#!/bin/ash

# exit when any command fails
set -o errexit -o pipefail

# configuration
: "${APP_UMASK:=027}"
: "${APP_UID:=502}"
: "${APP_GID:=502}"
: "${APP_USER:=amavis}"
: "${APP_GROUP:=amavis}"
: "${APP_HOME:=/var/amavis}"
: "${APP_CONF:=/etc/amavisd.conf}"
: "${APP_EXTRA_CONF:=/etc/amavisd-extra.conf}"
: "${APP_CLAMAV_CONF_DIR:=/etc/clamav}"
: "${APP_CLAMAV_HOME_DIR:=/var/lib/clamav}"
: "${APP_CLAMAV_LOG_DIR:=/var/log/clamav}"
: "${APP_SPAMASSASSIN_CONF_DIR:=/etc/mail/spamassassin}"
: "${APP_SPAMASSASSIN_HOME_DIR:=/var/lib/spamassassin}"

# export configuration
export APP_UMASK APP_UID APP_GID APP_USER APP_GROUP APP_HOME APP_CONF APP_EXTRA_CONF APP_CLAMAV_CONF_DIR APP_CLAMAV_HOME_DIR APP_CLAMAV_LOG_DIR APP_SPAMASSASSIN_CONF_DIR APP_SPAMASSASSIN_HOME_DIR

# invoked as root, add user and prepare container
if [ "$(id -u)" -eq 0 ]; then
  echo ">> removing default user and group (amavis)"
  if getent passwd "$APP_USER" >/dev/null; then deluser "$APP_USER"; fi
  if getent group "$APP_GROUP" >/dev/null; then delgroup "$APP_GROUP"; fi

  echo ">> removing default user and group (clamav)"
  if getent passwd clamav >/dev/null; then deluser clamav; fi
  if getent group clamav >/dev/null; then delgroup clamav; fi

  echo ">> adding unprivileged user (uid: $APP_UID / gid: $APP_GID)"
  addgroup -g "$APP_GID" "$APP_GROUP"
  adduser -HD -h "$APP_HOME" -s /sbin/nologin -G "$APP_GROUP" -u "$APP_UID" -k /dev/null "$APP_USER"

  echo ">> fixing owner of $APP_HOME, $APP_CONF, $APP_CLAMAV_CONF_DIR"
  install -dm 0750 -o "$APP_USER" -g "$APP_GROUP" /run/clamav
  install -dm 0750 -o "$APP_USER" -g "$APP_GROUP" "$APP_HOME"
  chown -R "$APP_USER":"$APP_GROUP" "$APP_HOME" "$APP_CLAMAV_CONF_DIR" "$APP_CLAMAV_HOME_DIR" "$APP_SPAMASSASSIN_CONF_DIR" "$APP_SPAMASSASSIN_HOME_DIR" "$APP_CLAMAV_LOG_DIR" /etc/s6
  chown root:"$APP_GROUP" "$APP_CONF" 
  [[ -e "$APP_EXTRA_CONF" ]] && chown root:"$APP_GROUP" "$APP_EXTRA_CONF"

  if [[ ! -e /var/amavis/.razor/identity ]]; then
    echo ">> create razor identity"
    razor-admin -create
    razor-admin -register
  fi

  echo ">> create link for syslog redirection"
  install -dm 0750 -o "$APP_USER" -g "$APP_GROUP" /run/syslogd
  ln -s /run/syslogd/syslogd.sock /dev/log

  # drop privileges and re-execute this script unprivileged
  echo ">> dropping privileges"
  export HOME="$APP_HOME" USER="$APP_USER" LOGNAME="$APP_USER" PATH="/usr/local/bin:/bin:/usr/bin"
  exec /usr/bin/setpriv --reuid="$APP_USER" --regid="$APP_GROUP" --init-groups --inh-caps=-all "$0" "$@"
fi

# tighten umask for newly created files / dirs
echo ">> changing umask to $APP_UMASK"
umask "$APP_UMASK"

echo ">> starting application"
exec /bin/s6-svscan /etc/s6

# vim: set ft=bash ts=2 sts=2 expandtab:

