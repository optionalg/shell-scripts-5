#!/bin/bash
###############################################################
#
# Nagios Auto-install script
#
# Maintainer: Imran Bhullar <imran.bhullar@gmail.com>
#
# This Script is tested on Centos/RHEL 5.x and 6.2.
# Please note that this is first beta release and might have some bugs
# We recommend you to try it on test instances before deploying it on
# Production machines.
#
# ChangeLog
#
# Nil
#
# 0.99	02.09.2012  Imran Bhullar <imran.bhullar@gmail.com>
#  * Initial Release
#
###############################################################
##Functions defined to do various taks##

detect_ip () {	##This function is used to detect the IP Address for Nagios Web Console Access##
echo "Please enter the name of your primary interface e,g. eth0,eth1 etc"
read int_name
        primaryaddr=`/sbin/ifconfig $int_name|grep 'inet addr'|cut -d: -f2|cut -d" " -f1`
        if [ $primaryaddr ]; then
echo $primaryaddr
        else
echo "Please enter the name of some other network interface"
read int_name
        primaryaddr=`/sbin/ifconfig $int_name|grep 'inet addr'|cut -d: -f2|cut -d" " -f1`
        if [ $primaryaddr ]; then
echo $primaryaddr
        else
echo "Unable to get IP information from $int_name using 127.0.0.1 as default IP"
        primaryaddr=`/sbin/ifconfig lo|grep 'inet addr'|cut -d: -f2|cut -d" " -f1`
echo $primaryaddr
fi
fi
}

#####################################################################
contacts="/usr/local/nagios/etc/objects/contacts.cfg"
index="/var/www/html/index.html"
log=/root/nagios-install.log
# Script Must Run as root
if [[ $EUID -ne 0 ]]; then
	echo "This script must be run as root" 1>&2
	exit 1
fi

echo "#####################################################"
echo "Adding user/groups needed for nagios"
echo "#####################################################"
sleep 20;
echo "Adding user named nagios"
useradd nagios && echo "done"
echo "Adding group named nagcmd"
groupadd nagcmd && echo "done"
echo "updaing group information for user nagios"
usermod -a -G nagcmd nagios && echo "done"

echo "#####################################################"
echo "Downloading/Installing required applications"
echo "#####################################################"
sleep 20;
yum update
yum install -y httpd php gcc glibc glibc-common gd gd-devel make mysql mysql-devel net-snmp wget; 

cd /usr/local/src

wget http://prdownloads.sourceforge.net/sourceforge/nagios/nagios-3.4.1.tar.gz
wget http://prdownloads.sourceforge.net/sourceforge/nagiosplug/nagios-plugins-1.4.16.tar.gz

tar vxzf nagios-3.4.1.tar.gz
tar vxzf nagios-plugins-1.4.16.tar.gz
cd nagios
echo "Going to Compile nagios & nagios plugins from Source !!"
sleep 10;
./configure --with-command-group=nagcmd
make all
make install; make install-init; make install-config; make install-commandmode; make install-webconf
cp -R contrib/eventhandlers/ /usr/local/nagios/libexec/
chown -R nagios:nagios /usr/local/nagios/libexec/eventhandlers
cd ..
cd nagios-plugins-1.4.16
./configure --with-nagios-user=nagios --with-nagios-group=nagios

make
make install
chkconfig --add nagios
chkconfig --level 3 nagios on
chkconfig --level 3 httpd on

echo "#####################################################"
echo "Updating the Email Address for Nagios Admin"
echo "#####################################################"
echo "Please enter the nagios admin email."
read admin
echo "Updating the nagios admin's email address"; sed -ie "s/nagios@localhost/$admin/g" $contacts && echo "Done"


echo "#####################################################"
echo "STARTING APACHE AND CHECKING PORT"
echo "#####################################################"
sleep 10;
/etc/init.d/httpd start > /dev/null
/etc/init.d/httpd reload

m=$(/bin/netstat -aunt | grep -vE '^Active|Proto' | grep "80" | awk '{ print $4}' | cut -d: -f4)

echo "Found Port# $m"

if [ "$m" -eq "80" ];
        then
        echo "APACHE UP AND RUNNING :)"
        else
        echo "APACHE DEAD :("
fi
echo "#####################################################"
echo "Updating Firewall Rules"
echo "#####################################################"

iptables -I INPUT -p tcp -s detect_ip --dport 80 -j ACCEPT
iptables -I INPUT -p tcp -s 127.0.0.1 --dport 80 -j ACCEPT
echo "Firewall rules updated successfully !!"
echo "#####################################################"
echo "STARTING NAGIOS AND CONFIGURING ACCESS"
echo "#####################################################"

/etc/init.d/nagios start > /dev/null
/etc/init.d/nagios reload

echo " Please enter the Password for the Nagios admin, username is nagiosadmin."
username=nagiosadmin
cd /usr/local/nagios
htpasswd -c /usr/local/nagios/etc/htpasswd.users $username

chown apache:apache /usr/local/nagios/etc/htpasswd.users
chmod 600 /usr/local/nagios/etc/htpasswd.users

echo "#####################################################"
echo "CHECKING FOR INDEX.HTML"
echo "#####################################################"

if [ -f $index ]
        then
        echo "Index.html Exists"
        else
        touch $index
        chown apache:apache $index
	chmod 755 $index
fi


/etc/init.d/nagios restart > /dev/null 2>&1
echo Nagios installed Successfully, enjoy !!
