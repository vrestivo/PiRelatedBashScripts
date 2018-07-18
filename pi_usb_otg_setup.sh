#!/bin/bash

# address specification for ip command
USB_ADDR="192.168.10.250/255.255.255.0"

# address specification for ifconfig command
IPADDR="192.168.10.250"
NMASK="255.255.255.0"

# highlighting settings
RED='\033[0;31m'
NC='\033[0m'

FW_MSG="\n${RED}/sbin/iptables${NC} is required for this script to work\n\
Please install iptables or set 'FW' variable\n\
to point to your current iptables location\n"

IP_UTIL_MSG="Cannot find ${RED}$IPCMD${NC} or ${RED}$IFCONFIG${NC}\n\
to set Pi's ip address"

FW=/sbin/iptables
IPCMD=/sbin/ip
IFCONFOG=/sbin/ifconfig
FWDFLAG=/proc/sys/net/ipv4/ip_forward
IFCMD=""
SSH_PORT=22

# check if ran as a root
ID=$(id -u)
if [ $ID -ne 0 ] ; then
  echo "You must be root to use this script!"
  exit -1
fi

# check if pi is connected
DEV=$(ip link | grep enp | cut -f2 -d: | tr -d [:blank:])
if [ -z $DEV ] ; then
  echo "Pi is not detected.  Check your device Connection"
  exit -1;
fi

# check if iptables is present
if [ ! -x $FW ] ; then
  echo $FW_MSG
  exit -1
fi 

# check for utilities to set ip address
if [ -x $IPCMD ] ; then 
  IFCMD="$IPCMD a add $USB_ADDR dev $DEV"
elif [ -x $IFCONFIG ] ; then
  IFCMD="$IFCONFIG $DEV $IPADDR netmask $NMASK"
else
  echo $IP_UTIL_MSG
  exit -1
fi

# set Pi's ip address
echo $IFCMD

echo "enabling port forwarding..."
echo 0 > $FWDFLAG
iptables -I INPUT -i $DEV -j ACCEPT
iptables -I OUTPUT -p tcp --dport $SSH_PORT -j ACCEPT
iptables -I FORWARD -i $DEV -j ACCEPT
iptables -I FORWARD -o $DEV -j ACCEPT

# show firewall summary
echo -e "\n###\tSETTINGS SUMMARY\t###"
echo -e "IPV4 ip_forward flag setting: $(cat $FWDFLAG)\n"
echo -e "\tFIREWALL SETTINGS"
iptables -L -n -v --line-numbers
iptables -t nat -L -n -v --line-numbers
