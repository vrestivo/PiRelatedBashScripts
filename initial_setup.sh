#!/bin/bash

# simple initial setup script will do the following:
#
# 1) disable avahi-daemon and cups services
# 2) initialize a simple iptables firewall and store
#    its configuration in /etc/firewall
# 3) add persistence to the firewall above by
#    wrapping it into a system.d service

FW=/sbin/iptables
FW6=/sbin/ip6tables
SYS=/bin/systemctl
FWDIR=/etc/firewall
FWSCRIPT=$FWDIR/firewall.sh
FWRULES=$FWDIR/iptables.rules
FW6RULES=$FWDIR/ip6tables.rules
FWSVC=iptables.service
FWSVCFILE=/etc/systemd/system/$FWSVC
AVAHI=avahi-daemon.service
CUPS=cups.service

if [ $(id -u) -ne 0 ] ; then
  echo "You must be root to run this"
  exit -1
fi

if [ -x $SYS ] ; then
  echo "Masking avahi-daemon service"
  $SYS mask $AVAHI 
  $SYS disable $AVAHI
  echo "Disabling cups service"
  $SYS stop $CUPS
  $SYS disable $CUPS
  echo Done!
fi

if [ -x $FW ] ; then
  echo "Setting up IPV4 firewall"
  ### input rules
  $FW -F
  $FW -P INPUT DROP
  $FW -A INPUT -j DROP
  $FW -I INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
  $FW -I INPUT -i lo -j ACCEPT
  $FW -I INPUT -p tcp --dport 22 -j ACCEPT
  ### forward rules
  $FW -P FORWARD DROP
  $FW -A FORWARD -j DROP
  ### output rules
  $FW -P OUTPUT DROP
  $FW -A OUTPUT -j DROP
  $FW -I OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
  $FW -I OUTPUT -p tcp --dport 22 -j ACCEPT
  $FW -I OUTPUT -p icmp --icmp echo-request -j ACCEPT
  $FW -I OUTPUT -o lo -j ACCEPT
  $FW -I OUTPUT -p tcp --dport 67 -j ACCEPT
  $FW -I OUTPUT -p udp --dport 67 -j ACCEPT
  $FW -I OUTPUT -p tcp --dport 53 -j ACCEPT
  $FW -I OUTPUT -p udp --dport 53 -j ACCEPT
  $FW -I OUTPUT -p tcp --dport 80 -j ACCEPT
  $FW -I OUTPUT -p tcp --dport 443 -j ACCEPT
fi

# block ipv6 traffic
if [ -x $FW6 ] ; then
  echo "Setting up IPV6 firewall"
  ### input rules
  $FW6 -F
  $FW6 -P INPUT DROP
  $FW6 -A INPUT -j DROP
  $FW6 -I INPUT -i lo -j ACCEPT
  ### forward rules
  $FW6 -P FORWARD DROP
  $FW6 -A FORWARD -j DROP
  ### output rules
  $FW6 -P OUTPUT DROP
  $FW6 -A OUTPUT -j DROP
  $FW6 -I OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
  $FW6 -I OUTPUT -o lo -j ACCEPT
fi

echo "Storing firewall configuration"
if [ ! -d $FWDIR ] ; then
  mkdir -p $FWDIR
fi
$FW-save > $FWRULES                                 
$FW6-save > $FW6RULES

echo "#!/bin/bash" > $FWSCRIPT
echo "$FW-restore < $FWRULES" >> $FWSCRIPT
echo "$FW6-restore < $FW6RULES" >> $FWSCRIPT
chmod u+x $FWSCRIPT

### create iptables.service systemd file
echo "[Unit]" > $FWSVCFILE
echo -e "Before=networking.service\n" >> $FWSVCFILE
echo "[Service]" >> $FWSVCFILE
echo "Type=oneshot" >> $FWSVCFILE
echo "RemainAfterExit=yes" >> $FWSVCFILE
echo -e "ExecStart=$FWSCRIPT\n" >> $FWSVCFILE
echo "[Install]" >> $FWSVCFILE
echo "WantedBy=multi-user.target" >> $FWSVCFILE

$SYS enable $FWSVC
$SYS start $FWSVC

