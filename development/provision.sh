#!/usr/bin/env bash

# Install all tools required for development on Ubuntu 20.04 (run as root user)

SOURCE_CODE_DIR="/home/vagrant/osmhu-website"

# unattended install
# source: https://serverfault.com/questions/500764/dpkg-reconfigure-unable-to-re-open-stdin-no-file-or-directory
export DEBIAN_FRONTEND=noninteractive


echo "Updating packages..."
if ! apt-get -qq update > /dev/null; then
	echo "ERROR! Failed to update packages. Exiting" >&2
	exit 1
fi


echo "Installing MySQL..."
debconf-set-selections <<< "mysql-server mysql-server/root_password password root"
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password root"
if ! apt-get install -qq mysql-server mysql-client > /dev/null; then
	echo "ERROR! Failed to install MySQL. Exiting" >&2
	exit 1
fi


echo "Installing PostgreSQL..."
if ! apt-get install -qq postgresql-12 postgis postgresql-12-postgis-scripts > /dev/null; then
	echo "ERROR! Failed to install PostgreSQL. Exiting" >&2
	exit 1
fi


echo "Installing database importer tool (osm2pgsql)..."
if ! apt-get install -qq osm2pgsql > /dev/null; then
	echo "ERROR! Failed to install osm2pgsql. Exiting" >&2
	exit 1
fi


echo "Installing apache2 and PHP..."
if ! apt-get install -qq apache2 php7.4 libapache2-mod-php php7.4-mysql php7.4-pgsql > /dev/null; then
	echo "ERROR! Failed to install apache2 and PHP. Exiting" >&2
	exit 1
fi


echo "Enabling required apache2 modules..."
if ! command -v a2enmod &> /dev/null; then
	echo "ERROR! a2enmod command could not be found. Exiting" >&2
	exit 1
fi
a2enmod -q include # server side includes
a2enmod -q rewrite # support rewrite rules
a2enmod -q ssl # HTTPS


echo "Creating symlinks for apache2 site configs..."
HTTP_SITE_CONFIG="${SOURCE_CODE_DIR}/development/apache2/osmhu-http.conf"
if [ ! -r ${HTTP_SITE_CONFIG} ]; then
	echo "ERROR! Apache2 site config not found at ${HTTP_SITE_CONFIG}" >&2
	if [ "${SOURCE_CODE_DIR}" == "/home/vagrant/osmhu-website" ]; then
		echo "Vagrant virtual machines should have the repository synced at /home/vagrant/osmhu-website, check this synchronization." >&2
	fi
	echo "Exiting" >&2
	exit 1
fi
ln -s "${HTTP_SITE_CONFIG}" /etc/apache2/sites-available/osmhu-http.conf
ln -s "${SOURCE_CODE_DIR}/development/apache2/osmhu-ssl.conf" /etc/apache2/sites-available/osmhu-ssl.conf


echo "Disabling default apache2 site config..."
if ! command -v a2dissite &> /dev/null; then
	echo "ERROR! a2dissite command could not be found. Exiting" >&2
	exit 1
fi
a2dissite -q 000-default.conf


echo "Enabling osmhu http apache2 site config..."
if ! command -v a2ensite &> /dev/null; then
	echo "ERROR! a2ensite command could not be found. Exiting" >&2
	exit 1
fi
a2ensite -q osmhu-http


echo "Installing PhpMyAdmin for graphical db editing..."
if ! apt-get install -qq debconf-utils > /dev/null; then
	echo "ERROR! Failed to install debconf-utils. Exiting" >&2
	exit 1
fi
echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/app-pass password root" | debconf-set-selections
echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | debconf-set-selections
if ! apt-get install -qq phpmyadmin > /dev/null; then
	echo "ERROR! Failed to install phpmyadmin. Exiting" >&2
	exit 1
fi


echo "Enabling apache2 autostart..."
systemctl enable --quiet apache2


echo "Restarting apache2 to apply changes..."
systemctl reload apache2
systemctl restart apache2


echo "Installing Node.js for frontend development..."
if ! apt-get install -qq build-essential > /dev/null; then
	echo "ERROR! Failed to install build-essential. Exiting" >&2
	exit 1
fi
if ! apt-get install -qq curl > /dev/null; then
	echo "ERROR! Failed to install curl. Exiting" >&2
	exit 1
fi
# https://github.com/nodesource/distributions/blob/master/README.md#manual-installation
if ! curl -sSL https://deb.nodesource.com/gpgkey/nodesource.gpg.key | APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=DontWarn apt-key --quiet add -; then
	echo "ERROR! Failed to fetch Node.js installer key using curl. Exiting" >&2
	exit 1
fi
VERSION=node_14.x
DISTRO="$(lsb_release -s -c)"
echo "deb https://deb.nodesource.com/$VERSION $DISTRO main" | tee /etc/apt/sources.list.d/nodesource.list > /dev/null
echo "deb-src https://deb.nodesource.com/$VERSION $DISTRO main" | tee -a /etc/apt/sources.list.d/nodesource.list > /dev/null
if ! apt-get update > /dev/null; then
	echo "ERROR! Failed to update apt package list after adding Node.js sources. Exiting" >&2
	exit 1
fi
if ! apt-get install -qq nodejs > /dev/null; then
	echo "ERROR! Failed to install Node.js. Exiting" >&2
	exit 1
fi


echo "Installing known stable npm version..."
if ! command -v npm &> /dev/null; then
	echo "ERROR! npm command could not be found. Exiting" >&2
	exit 1
fi
npm install --silent --global npm@latest-6


echo "Installing git for version control..."
if ! apt-get install -qq git > /dev/null; then
	echo "ERROR! Failed to install git. Exiting" >&2
	exit 1
fi


echo "Installing htop..."
if ! apt-get install -qq htop > /dev/null; then
	echo "ERROR! Failed to install htop. Exiting" >&2
	exit 1
fi


echo "Installing fswatch for running commands on file change..."
if ! apt-get install -qq fswatch > /dev/null; then
	echo "ERROR! Failed to install fswatch. Exiting" >&2
	exit 1
fi
