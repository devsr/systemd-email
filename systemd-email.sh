#!/bin/sh

CONFIG=/etc/systemd/x-email.conf

if [ -f "$CONFIG" ]; then
  . "$CONFIG"
fi

if [ -z "$MAILTO" ]; then
  MAILTO=root;
fi

if [ -n "$2" ]; then
  EXIT_CODE="$2"
else
  eval "$(systemctl show --property=ExecMainStatus $1)"
  EXIT_CODE=$ExecMainStatus
fi

if [ -n "$EXIT_CODE" ] && [ "$EXIT_CODE" -eq 0 ]; then
  echo "Exit Code: $EXIT_CODE - Not sending status email."
  exit 0;
fi


echo "Exit Code: $EXIT_CODE - Getting systemctl status: $1"
MSG_BODY=$(systemctl status --full --lines 100 "$1")
  
RET=0
if [ $RET -ne 0 ]; then
  echo "Failed: systemctl status: $1"
  exit $RET;
fi

if [ -z "$MSG_BODY" ]; then
  echo "Failed: systemctl status returned empty"
  exit 1;
fi

HOSTNAME=$(hostname -s)
if [ -z "$HOSTNAME" ]; then
  HOSTNAME="systemd"
fi

echo "Sending status email..."
sendmail "$MAILTO" <<EOF
Content-Type: text/plain; charset=utf-8
To: $MAILTO
Subject: [$HOSTNAME]: $1
$MSG_BODY
EOF
