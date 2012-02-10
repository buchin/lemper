#!/bin/bash

echo "how much MB RAM do you have?"
read ram
echo "where do you want varnish to store its cache (malloc or file)?"
read varnish_cache_location

echo 'please specify varnish cache size (1G, 50%, etc)?'
read varnish_cache_size

read ram
echo "updating apt source"
apt-get update
echo "adding dotdeb repo"
echo "deb http://packages.dotdeb.org stable all" >> /etc/apt/sources.list
echo "deb-src http://packages.dotdeb.org stable all" >> /etc/apt/sources.list
echo "getting gpg keys"
wget http://www.dotdeb.org/dotdeb.gpg
cat dotdeb.gpg | apt-key add -

curl http://repo.varnish-cache.org/debian/GPG-key.txt | apt-key add -
echo "deb http://repo.varnish-cache.org/debian/ $(lsb_release -s -c) varnish-3.0" >> /etc/apt/sources.list.d/varnish.list 

apt-get update

echo "Install Nginx, PHP-FPM, MySQL, APC, zip, unzip, varnish"
apt-get install nginx-full php5-fpm php5 mysql-server php5-apc php5-mysql php5-xsl php5-xmlrpc php5-sqlite php5-snmp php5-curl zip unzip varnish

echo "calculating apc settings value"
apc_shm_size=$(perl -e "print 512/1024*${ram}")
echo "calculating mysql settings value"
mysql_key_buffer=$(perl -e "print 16/1024*${ram}")
mysql_max_allowed_packet=${mysql_key_buffer}
mysql_query_cache_size=$(perl -e "print 128/1024*${ram}")

echo "creating my.cnf"
sed 's/mysql_key_buffer/'${mysql_key_buffer}'/g;s/mysql_query_cache_size/'${mysql_query_cache_size}'/g;s/mysql_max_allowed_packet/'${mysql_max_allowed_packet}'/g' my.cnf.txt  > my.cnf
echo "creating apc.ini"
sed 's/apc_shm_size/'${apc_shm_size}'/g' apc.ini.txt > apc.ini
echo "creating varnish default command"
sed 's/varnish_cache_location/'${varnish_cache_location}'/g;s/varnish_cache_size/'${varnish_cache_size}'/g' varnish.txt  > varnish

echo "moving apc.ini"
mv -f apc.ini /etc/php5/conf.d/apc.ini

echo "moving nginx.conf"
cp nginx.conf.txt nginx.conf
mv -f nginx.conf /etc/nginx/nginx.conf


echo "appending mysql extension to php.ini"
echo "extension = mysql.so" >> /etc/php5/fpm/php.ini

if [ -d "/usr/lib/php5/20090626+lfs/" ]; then
	echo "extension_dir = /usr/lib/php5/20090626+lfs/" >> /etc/php5/fpm/php.ini
fi
if [ -d "/usr/lib/php5/20090626/" ]; then
	echo "extension_dir = /usr/lib/php5/20090626/" >> /etc/php5/fpm/php.ini
fi


echo "moving my.cnf"
mv -f my.cnf /etc/mysql/my.cnf

echo "moving varnish"
mv -f default.vcl /etc/varnish/default.vcl
mv -f varnish /etc/default/varnish



echo "restarting services"
/etc/init.d/nginx start
/etc/init.d/mysql restart
/etc/init.d/php5-fpm restart
/etc/init.d/varnish restart

echo "LEMPER script finished"