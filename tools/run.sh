#!/usr/bin/env bash
#
# Run jekyll serve and then launch the site

prod=false
command="bundle exec jekyll s -l"
host="127.0.0.1"
port="4000"

help() {
  echo "Usage:"
  echo
  echo "   bash /path/to/run [options]"
  echo
  echo "Options:"
  echo "     -H, --host [HOST]    Host to bind to."
  echo "     -p, --production     Run Jekyll in 'production' mode."
  echo "     -P, --port [PORT]        Port to bind to."
  echo "     -h, --help           Print this help information."
}

while (($#)); do
  opt="$1"
  case $opt in
  -H | --host)
    host="$2"
    shift 2
    ;;
  -p | --production)
    prod=true
    shift
    ;;
  -P | --port)
    port="$2"
    shift 2
    ;;
  -h | --help)
      help
      exit 0
      ;;
  *)
    echo -e "> Unknown option: '$opt'\n"
    help
    exit 1
    ;;
  esac
done

command="$command -H $host --port $port"

if $prod; then
  command="JEKYLL_ENV=production $command"
fi

if [ -e /proc/1/cgroup ] && grep -q docker /proc/1/cgroup; then
  command="$command --force_polling"
fi

echo -e "\n> $command\n"
eval "$command"
