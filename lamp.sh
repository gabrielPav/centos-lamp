#!/bin/bash

# Check if user is root
if [ $(id -u) != "0" ]; then
    echo "Error: You must be root to run this script, please use root to install LEMP"
    exit 1
fi

clear
echo "==========================================================="
echo "LAMP web stack v1.1 for Linux CentOS 6.x, written by GP"
echo "==========================================================="
echo "A tool to auto-compile & install Apache+MySQL+PHP on Linux "
echo ""
echo "For more information please visit https://makewebfast.net"
echo "==========================================================="


###########################
# Check and update the OS #
###########################
clear
echo "========================"
echo "Updating CentOS System"
echo "========================"
yum -y update


###################
# Create new user #
###################

# Dummy Credentials
FTP_USERNAME=domain.com
FTP_GROUP=domain.com
FTP_USER_PASSWORD=ftp.password
MYSQL_ROOT_PASSWORD=mysql.password

mkdir -p /var/www/html

/usr/sbin/groupadd $FTP_GROUP
/usr/sbin/adduser -g $FTP_GROUP -d /var/www/html $FTP_USERNAME

echo $FTP_USER_PASSWORD | passwd --stdin $FTP_USERNAME

chown -R ${FTP_USERNAME}:${FTP_GROUP} /var/www
chmod 775 /var/www/html

# Limit FTP access only to /public_html directory
usermod --home /var/www/html $FTP_USERNAME
chown -R ${FTP_USERNAME}:${FTP_GROUP} /var/www
chmod 775 /var/www/html

# Set PHP session path
mkdir -p /var/lib/php/session
chown -R $FTP_USERNAME:$FTP_USERNAME /var/lib/php/session
chmod 775 /var/lib/php/session


#####################################
# Install Webtatic repo for PHP 5.6 #
#####################################
rpm -Uvh https://mirror.webtatic.com/yum/el6/latest.rpm


##################################
# Add the necessary dependencies #
##################################
yum -y install wget zip unzip gcc gcc-c++ make openssl openssl-devel git pcre-dev pcre-devel zlib-devel


##################
# Install Apache # 
##################
yum install -y httpd
chkconfig httpd on


###############################################
# install PHP-FPM with latest PHP 5.6 version #
###############################################

# Install all necessary PHP modules from Webtatic repo
# Wordpress dependencies: http://goo.gl/zMH3yg
cd
yum -y install php56w php56w-common php56w-cli php56w-gd php56w-imap php56w-mysqlnd php56w-odbc php56w-pdo php56w-xml php56w-mbstring php56w-mcrypt php56w-soap php56w-tidy php56w-ldap php56w-process php56w-snmp php56w-devel php56w-pear php56w-pspell php56w-pecl-imagick libmcrypt-devel

# Change some PHP variables
sed -i 's/max_execution_time = 30/max_execution_time = 90/g' /etc/php.ini
sed -i 's/memory_limit = 128M/memory_limit = 512M/g' /etc/php.ini
sed -i 's/display_errors = On/display_errors = Off/g' /etc/php.ini
sed -i 's/;date.timezone =/;date.timezone = UTC/g' /etc/php.ini
sed -i 's/;session.save_path = "\/tmp"/session.save_path = "\/var\/lib\/php\/session"/g' /etc/php.ini


######################
# install PHPMyAdmin #
######################
rpm -Uvh http://rpms.famillecollet.com/enterprise/remi-release-6.rpm
yum --enablerepo=remi,remi-test install -y phpMyAdmin


#####################
# install MySQL 5.6 #
#####################
cd
wget http://dev.mysql.com/get/mysql-community-release-el6-5.noarch.rpm
yum -y localinstall mysql-community-release-el6-*.noarch.rpm
yum -y install mysql-community-server
chkconfig mysqld on

# Replace / tune the MySQL configuration file
wget https://raw.githubusercontent.com/gabrielPav/centos-lemp/master/conf/mysql/my.cnf -O /etc/my.cnf

service mysqld start
sleep 5

# Secure MySQL installation
yum -y install expect

# Use expect
SECURE_MYSQL=$(expect -c "

set timeout 10
spawn mysql_secure_installation

expect \"Enter current password for root (enter for none):\"
send \"$MYSQL\r\"

expect \"Change the root password?\"
send \"y\r\"

expect \"New password:\"
send \"$MYSQL_ROOT_PASSWORD\r\"
 
expect \"Re-enter new password:\"
send \"$MYSQL_ROOT_PASSWORD\r\"

expect \"Remove anonymous users?\"
send \"y\r\"

expect \"Disallow root login remotely?\"
send \"y\r\"

expect \"Reload privilege tables now?\"
send \"y\r\"

expect eof
")

echo "$SECURE_MYSQL"

yum -y remove expect

sleep 5
service mysqld stop


################################
# Install and configure VSFTPD #
################################

# Install VSFTPD
yum -y install ftp vsftpd
chkconfig vsftpd on
service vsftpd start

# Configure VSFTPD
sed -i 's/anonymous_enable=YES/anonymous_enable=NO/g' /etc/vsftpd/vsftpd.conf
sed -i 's/local_enable=NO/local_enable=YES/g' /etc/vsftpd/vsftpd.conf
sed -i 's/#chroot_local_user=YES/chroot_local_user=YES/g' /etc/vsftpd/vsftpd.conf

service vsftpd restart


########################
# Restart key services #
########################
clear
echo "================"
echo  "Start MySQL."
echo "================"
service mysqld start
echo "==============="
echo  "Start Apache."
echo "==============="
service httpd start
echo "================="
sleep 5

chown -R ${FTP_USERNAME}:${FTP_GROUP} /var/www/html

# Remove the installation files
rm -rf /root/mysql-community-release-el6-5.noarch.rpm

clear
echo "========================================"
echo "LAMP Installation Complete!"
echo "========================================"
