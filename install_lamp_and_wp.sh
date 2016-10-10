#!/bin/bash
# Install LAMP stack on CentOS 7

ip_address=$(ip -f inet addr show eth0 | grep -Po 'inet \K[\d.]+')

echo "Starting My (Verbose) LAMP/WP automated install script"
echo "one moment please..."
sleep 2

echo "Disabling SELinux.."
setenforce 0

echo "Cleaning up repos"
yum clean all

echo "Performing updates"
yum -y update


echo "Installing httpd..."
sleep 2
yum install -y httpd

sleep 2

echo "Starting httpd service..."
systemctl start httpd.service
sleep 2

echo "Enabling httpd.service..."
sleep 2
systemctl enable httpd.service
sleep 2

echo "Getting IP Address (saving to svr_pub_ip.txt)..."
sleep 2
ip addr show eth0 | grep inet | awk '{ print $2; }' | sed 's/\/.$//' >> ip_addr.txt
echo "Done.. ipv4/ipv6 Address saved to $(pwd)/ip_addr.txt"
sleep 2

echo "Installing MariaDB (MySQL) [mariadb-server mariadb]"
sleep 2
yum install mariadb-server mariadb -yy
sleep 2

echo "Starting MariaDB(MySql) [mariadb]..."
systemctl start mariadb

sleep 2

echo "Entering MySQL Secure Installation Setup..."
sleep 2
mysql_secure_installation
sleep 10

echo "Enabling MariaDB [mariadb.service]..."
systemctl enable mariadb.service

echo "Installing PHP [php php-mysql]..."
sleep 2
yum install php php-mysql -yy

sleep 2
echo "Restarting httpd.service.."
systemctl restart httpd.service

sleep 2

echo "Creating /var/www/html/info.php.. go to http://$ip_address/info.php to test."
echo "<?php phpinfo(); ?>" > /var/www/html/info.php
echo "Done.."
sleep 2

echo "Starting FirewallD service..."
service firewalld start
sleep 2

echo "Updating Firewall settings..."
sleep 2
firewall-cmd --permanent --zone=public --add-service=http
firewall-cmd --permanent --zone=public --add-service=https
firewall-cmd --reload


echo "Go to http://$ip_address/info.php now.."
sleep 20

echo "Removing /var/www/html/info.php in just a few seconds due to security concerns.."
sleep 15

rm -f /var/www/html/info.php
echo "/var/www/html/info.php has been removed!"
sleep 2


echo "Creating wordpress database..."
sleep 2
echo "Please enter your mariadb root password: "
read mysqlroot
echo "Please enter your mariadb wordpressuser password: "
read mysqluserpass

mysql -u root -p$mysqlroot -e "CREATE DATABASE wordpress;"

mysql -u root -p$mysqlroot -e "CREATE USER wordpressuser@localhost IDENTIFIED BY '$mysqluserpass';"

mysql -u root -p$mysqlroot -e "GRANT ALL PRIVILEGES ON wordpress.* TO wordpressuser@localhost IDENTIFIED BY '$mysqluserpass';"

mysql -u root -p$mysqlroot -e "FLUSH PRIVILEGES;"

echo "Done.."
sleep 2

echo "Installing PHP Module..."
yum -y install php-fpm php-gd php-ldap php-odbc php-pear php-xml php-xmlrpc php-mbstring php-snmp php-soap curl
sleep 2

echo "Restarting Apache.."
service httpd restart

sleep 2

echo "Downloading Latest Version of Wordpress..."
wget http://wordpress.org/latest.tar.gz

sleep 2

tar xzvf latest.tar.gz
sleep 2

echo "Installing WP.."
sleep 2
rsync -avP ~/wordpress/ /var/www/html/

mkdir /var/www/html/wp-content/uploads

chown -R apache:apache /var/www/html/*

cp /var/www/html/wp-config-sample.php /var/www/html/wp-configs.php

wppath="/var/www/html/"

echo "Configuring $wppath/wp-config.php"
sleep 2

sed s/database_name_here/wordpress/ $wppath/wp-configs.php > $wppath/wp-config.php

sed s/username_here/wordpressuser/ $wppath/wp-config.php > $wppath/wp-configs.php

sed s/password_here/$mysqluserpass/ $wppath/wp-configs.php > $wppath/wp-config.php

rm -f $wppath/wp-configs.php

echo "Done.."

echo "Fixing Permissions and final tidying..."
sleep 2
chown -R apache:apache /var/www/html/*

cd /var/www/html/

find . -type f -exec chmod 644 {} +
find . -type d -exec chmod 775 {} +
chmod 660 wp-config.php
chown -R apache:apache /var/www/html/*

echo "Done.."
sleep 2

service httpd restart

echo "Wordpress/LAMP Stack installation for CentOS 7x is complete!"

echo "Go to http://$ip_address/ to configure your WordPress Page.."
