#!/bin/bash

version="2.1.0"
targz="Magento-CE-$version.tar.gz"

# MAGEID and token from your Magento account
. ./secrets

echo "Updating repos"
apt-get update

mkdir -p /downloadedApps
cd /downloadedApps

if [ ! -f $targz ]; then
  echo "Downloading Magento..."
  wget -cN --progress=bar:force "https://$MAGEID:$token@www.magentocommerce.com/products/downloads/file/$targz"
fi

echo "Installing Apache"
apt-get -y install apache2

echo "Installing PHP"
apt-get -y install php7.0-common php7.0-gd php7.0-mcrypt php7.0-curl php7.0-intl php7.0-xsl php7.0-mbstring php7.0-zip php7.0-iconv php7.0-cli php7.0 php-pear libapache2-mod-php7.0 php7.0-mysql php7.0-curl php7.0-json

echo "Installing MySQL"
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password root'
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password root'
apt-get -y install mysql-server mysql-client

echo "CREATE DATABASE magento;" | mysql --user=root --password=root

echo "Configuring Apache"
a2enmod rewrite

mkdir -p /var/www/html/magento

cat << EOF > /etc/apache2/sites-available/magento.conf
<VirtualHost *:80>
	DocumentRoot /var/www/html/magento
	<Directory /var/www/html/magento/>
    Require all granted
		Options Indexes FollowSymLinks MultiViews
		AllowOverride All
	</Directory>
</VirtualHost>
EOF

a2ensite magento.conf
a2dissite 000-default.conf
systemctl reload apache2

echo "Configuring PHP"
sed -i 's/memory_limit = .*$/memory_limit = 1G/' /etc/php/7.0/apache2/php.ini
sed -i 's/memory_limit = .*$/memory_limit = 1G/' /etc/php/7.0/cli/php.ini
sed -i 's/^;date.timezone =/date.timezone = America\/New_York/' /etc/php/7.0/apache2/php.ini
sed -i 's/^;date.timezone =/date.timezone = America\/New_York/' /etc/php/7.0/cli/php.ini

echo "Creating magento user"
useradd magento
usermod -g www-data magento

cd /var/www/html/magento
if [ ! -f LICENSE.txt ]; then
  echo "Extracting Magento"
  tar xzf /downloadedApps/$targz
  find var vendor pub/static pub/media app/etc -type f -exec chmod g+w {} \;
  find var vendor pub/static pub/media app/etc -type d -exec chmod g+ws {} \;
  chown -R magento:www-data .
  chmod u+x bin/magento
fi

echo "Restarting Apache"
systemctl restart apache2

echo "Setting up Magento"
cd /var/www/html/magento/bin
sudo -u magento ./magento setup:install --admin-firstname="Super" --admin-lastname="User" --admin-email="a@z.com" --admin-user="admin" --admin-password="password1" --db-name="magento" --db-host="localhost" --db-user="root" --db-password="root"
echo '' | sudo -u magento ./magento setup:config:set --backend-frontname="admin"

cat << EOF > magento.crontab.tmp
* * * * * /usr/bin/php /var/www/html/magento/bin/magento cron:run > /dev/null
* * * * * /usr/bin/php /var/www/html/magento/update/cron.php > /dev/null
* * * * * /usr/bin/php /var/www/html/magento/bin/magento setup:cron:run > /dev/null
EOF
crontab -u magento magento.crontab.tmp
rm magento.crontab.tmp

echo ''
echo '=== Admin ==='
echo '     URL: http://localhost:8210/admin'
echo 'username: admin'
echo 'password: password1'
echo ''
echo 'Script finished.'
