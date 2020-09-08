#!/bin/sh

YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[1;34m'
SET='\033[0m'

#Delete originale file
rm -rf /etc/ppp/peers/provider
rm -rf /etc/chatscripts/chat-connect
rm -rf /etc/chatscripts/chat-disconnect
rm -rf /usr/src/reconnect.sh
rm -rf /etc/systemd/system/reconnect.service


echo -n "${YELLOW}Please connecting to internet for downloading PPP tool and files? [Y/n] ${SET}"
read answer

if [ "$answer" != "${answer#[Nn]}" ] ;then
	echo "${RED}You cancel the installation...${SET}"
	exit 1;
fi


echo "${YELLOW}Downloading setup files${SET}"
wget --no-check-certificate  https://raw.githubusercontent.com/sixfab/Sixfab_PPP_Installer/master/ppp_installer/chat-connect -O chat-connect

if [ $? -ne 0 ]; then
    echo "${RED}Download failed, please connect to internet for downloading files...${SET}"
    exit 1; 
fi

wget --no-check-certificate  https://raw.githubusercontent.com/sixfab/Sixfab_PPP_Installer/master/ppp_installer/chat-disconnect -O chat-disconnect

if [ $? -ne 0 ]; then
    echo "${RED}Download failed${SET}"
    exit 1;
fi

wget --no-check-certificate  https://raw.githubusercontent.com/sixfab/Sixfab_PPP_Installer/master/ppp_installer/provider -O provider

if [ $? -ne 0 ]; then
    echo "${RED}Download failed${SET}"
    exit 1;
fi

echo "${YELLOW}ppp tool install${SET}"
apt-get install ppp

echo "${YELLOW}What is your carrier APN?${SET}"
read carrierapn 

#while [ 1 ]
#do
#	echo "${YELLOW}Does your carrier need username and password? [Y/n]${SET}"
#	read usernpass
#	
#	case $usernpass in
#		[Yy]* )  while [ 1 ] 
#        do 
#        
#        echo "${YELLOW}Enter username${SET}"
#        read username
#
#        echo "${YELLOW}Enter password${SET}"
#        read password
#        sed -i "s/noauth/#noauth\nuser \"$username\"\npassword \"$password\"/" provider
#        break 
#        done
#
#        break;;
#		
#		[Nn]* )  break;;
#		*)  echo "${RED}Wrong Selection, Select among Y or n${SET}";;
#	esac
#done

echo "${YELLOW}What is your device communication PORT? (ttyS0/ttyUSB3/etc.)${SET}"
read devicename 

mkdir -p /etc/chatscripts

mv chat-connect /etc/chatscripts/
mv chat-disconnect /etc/chatscripts/

mkdir -p /etc/ppp/peers
sed -i "s/#APN/$carrierapn/" provider
sed -i "s/#DEVICE/$devicename/" provider
mv provider /etc/ppp/peers/provider

if ! (grep -q 'sudo route' /etc/ppp/ip-up ); then
    echo "sudo route del default" >> /etc/ppp/ip-up
    echo "sudo route add default ppp0" >> /etc/ppp/ip-up
fi

#if [ $shield_hat -eq 2 ]; then
#	if ! (grep -q 'max_usb_current' /boot/config.txt ); then
#		echo "max_usb_current=1" >> /boot/config.txt
#	fi
#fi

while [ 1 ]
do
	echo "${YELLOW}Do you want to activate auto connect/reconnect service at R.Pi boot up? [Y/n] ${SET}"
	read auto_reconnect

	case $auto_reconnect in
		[Yy]* )    echo "${YELLOW}Downloading setup file${SET}"
			  
			wget --no-check-certificate https://raw.githubusercontent.com/sixfab/Sixfab_PPP_Installer/master/ppp_installer/reconnect_service -O reconnect.service
			  
			wget --no-check-certificate  https://raw.githubusercontent.com/sixfab/Sixfab_PPP_Installer/master/ppp_installer/reconnect_baseshield -O reconnect.sh
				
			wget --no-check-certificate  https://raw.githubusercontent.com/sixfab/Sixfab_PPP_Installer/master/ppp_installer/reconnect_basehat -O reconnect.sh

			  sed -i 3,9d reconnect.sh
			  mv reconnect.sh /usr/src/
			  sed -i "s/pi/root/" reconnect.service
			  mv reconnect.service /etc/systemd/system/
			  
			  systemctl daemon-reload
			  systemctl enable reconnect.service
			  
			  break;;
			  
	        [Nn]* )    echo "${YELLOW}To connect to internet run ${BLUE}\"sudo pon\"${YELLOW} and to disconnect run ${BLUE}\"sudo poff\" ${SET}"
			  break;;
	esac
done

read -p "Press ENTER key to reboot" ENTER
reboot
