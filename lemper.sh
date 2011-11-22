#!/bin/bash

echo "how much MB RAM do you have?"
read ram
echo "updating apt source"
apt-get update
echo "adding dotdeb repo"
echo "deb http://packages.dotdeb.org stable all" >> /etc/apt/sources.list
echo "deb-src http://packages.dotdeb.org stable all" >> /etc/apt/sources.list
echo "getting gpg key"
wget http://www.dotdeb.org/dotdeb.gpg
cat dotdeb.gpg | apt-key add -
apt-get update

echo "Install Nginx, PHP-FPM, MySQL, APC"
apt-get install nginx-full php5-fpm php5 mysql-server php5-apc php5-mysql php5-xsl php5-xmlrpc php5-sqlite php5-snmp php5-curl

echo "calculating apc settings value"
apc_shm_size=$(perl -e "print 512/1024*$ram")
echo "calculating mysql settings value"
mysql_key_buffer=$(perl -e "print 16/1024*$ram")
mysql_max_allowed_packet=$mysql_key_buffer
mysql_query_cache_size=$(perl -e "print 128/1024*$ram")

echo "creating my.cnf"
sed "s/mysql_key_buffer/$mysql_key_buffer/g" my.cnf.txt | sed "s/mysql_query_cache_size/$mysql_query_cache_size/g" | sed "s/mysql_max_allowed_packet/$mysql_max_allowed_packet/g" > my.cnf
echo "creating apc.ini"
sed "s/apc_shm_size/$apc_shm_size/g" apc.ini.txt > apc.ini
echo "moving apc.ini"
mv -f apc.ini /etc/php5/conf.d/apc.ini

echo "appending mysql extension to php.ini"
echo "extension = mysql.so" >> /etc/php5/fpm/php.ini
echo "extension_dir = /usr/lib/php5/20090626+lfs/" >> /etc/php5/fpm/php.ini

echo "moving my.cnf"
mv -f my.cnf /etc/mysql/my.cnf

echo "restarting services"
/etc/init.d/nginx start
/etc/init.d/mysql restart
/etc/init.d/php5-fpm restart

echo "LEMPER script finished"