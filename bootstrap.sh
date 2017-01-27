#!/bin/bash

version="1.9.1.0"

echo "Updating repos"
apt-get update

mkdir -p /download
cd /download

if [ ! -f $version.tar.gz ]; then
  echo "Downloading Magento..."
  wget "https://github.com/OpenMage/magento-mirror/archive/$version.tar.gz"
fi

echo "Installing Apache"
apt-get -y install apache2

echo "Installing PHP"
apt-get -y install php5 libcurl3 php5-curl php5-gd php5-mcrypt php5-mysql

echo "Installing MySQL"
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password root'
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password root'
apt-get -y install mysql-server mysql-client

echo "CREATE DATABASE magento;" | mysql --user=root --password=root

echo "Configuring Apache"
a2enmod rewrite
php5enmod mcrypt
php5enmod pdo_mysql

sed -i 's/^Listen .*$/Listen 8191/' /etc/apache2/ports.conf

mkdir -p /var/www/html/magento

cat << EOF > /etc/apache2/sites-available/magento.conf
<VirtualHost *:8191>
	DocumentRoot /var/www/html/magento
	<Directory /var/www/html/magento/>
		Options Indexes FollowSymLinks MultiViews
		AllowOverride All
	</Directory>
</VirtualHost>
EOF

a2ensite magento.conf
a2dissite 000-default.conf
service apache2 restart

echo "Configuring PHP"
sed -i 's/memory_limit = .*$/memory_limit = 1G/' /etc/php5/apache2/php.ini
sed -i 's/^;date.timezone =/date.timezone = America\/New_York/' /etc/php5/apache2/php.ini


cd /var/www/html/magento
if [ ! -f LICENSE.txt ]; then
  echo "Extracting Magento"
  tar xzf /download/$version.tar.gz --strip-components=1
  chown -R www-data:www-data .
fi

echo "Restarting Apache"
service apache2 restart

cat << EOF > magento.crontab.tmp
* * * * * /bin/sh /var/www/html/magento/cron.sh
EOF
crontab magento.crontab.tmp
rm magento.crontab.tmp

echo ''
echo '=== Continue setup at ==='
echo '     URL: http://localhost:8191/'
echo 'database: magento'
echo ' db user: root'
echo ' db pass: root'
echo ''
echo 'Script finished.'
