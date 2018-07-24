# Helpful Raspberry Pi-Related Bash Scripts

This is a start of the collection of helpful raspberry pi setup scripts.

## initial_setup.sh
This script should be run on a clean image.  It will perform the following tasks:
* Disable avahi-daemon and cups services.
* Initialize a simple iptables firewall and store its configuration in /etc/firewall.

  - **Note: by default the firewall will block all IPV6 traffic. If you need to ajust IPV6 firewall settings, use ip6tables command, then save your new rules in /etc/firewall/ip6tables.rules**
  
* Add persistence to the firewall above by wrapping it into a system.d service and enabling it on boot.

