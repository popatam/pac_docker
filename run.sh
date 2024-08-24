#!/bin/bash

usage() {
  echo "Usage: $0 {-outline <some_url> | -xray <some_url>} [domain1 domain2 ... domainN]"
  exit 1
}

if [ "$#" -lt 2 ]; then
  usage
fi

option="$1"
url="$2"
shift 2
domains=("$@")

PAC_FILE="/tmp/localproxy.pac"
SOCKS_PORT=1080
PAC_PORT=8999

parse_outline_config() {
  local outline_url="$1"
  if [ -z "$outline_url" ]; then
    echo "Error: $outline_url is empty."
    exit 1
  fi

  encoded_part=$(echo "$outline_url" | awk -F '://' '{print $2}' | awk -F '@' '{print $1}')
  decoded_part=$(echo "$encoded_part" | base64 -d)

  method=$(echo "$decoded_part" | awk -F ':' '{print $1}')
  password=$(echo "$decoded_part" | awk -F ':' '{print $2}')
  server=$(echo "$outline_url" | awk -F '@' '{print $2}' | awk -F ':' '{print $1}')
  server_port=$(echo "$outline_url" | awk -F '@' '{print $2}' | awk -F ':' '{print $2}' | awk -F '#' '{print $1}')

  json=$(
    cat <<EOF
{
    "server": "$server",
    "server_port": $server_port,
    "local_address": "0.0.0.0",
    "local_port": $SOCKS_PORT,
    "password": "$password",
    "timeout": 300,
    "method": "$method"
}
EOF
  )
  echo "$json" >/tmp/config.json
}

update_pac_file() {
  local formatted_domains

  cat /localproxy.pac.orig >$PAC_FILE

  if [ ${#domains[@]} -gt 0 ]; then
    formatted_domains=$(printf '"%s",' "${domains[@]}" | sed 's/,$//')
    sed -i "s/INSERT_HERE/$formatted_domains/" "$PAC_FILE"
  else
    sed -i "s/INSERT_HERE/" /localproxy.pac
  fi
}

update_pac_file

case "$option" in
-outline)
  parse_outline_config "$url" >/tmp/config.json
  while :; do {
    echo -ne "HTTP/1.0 200 OK\r\nContent-Length: $(wc -c </tmp/localproxy.pac)\r\n\r\n"
    cat $PAC_FILE
  } | nc -l -p $PAC_PORT; done &
  sslocal -c /tmp/config.json
  ;;
-xray)
  while :; do {
    echo -ne "HTTP/1.0 200 OK\r\nContent-Length: $(wc -c </tmp/localproxy.pac)\r\n\r\n"
    cat $PAC_FILE
  } | nc -l -p $PAC_PORT; done &
  xray-knife proxy -c "$url" -p $SOCKS_PORT -a 0.0.0.0
  ;;
*)
  usage
  ;;
esac
