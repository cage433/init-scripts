if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

echo "deb http://repository.spotify.com stable non-free" >> /etc/apt/sources.list
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 94558F59
apt-get update && sudo apt-get install spotify-client
