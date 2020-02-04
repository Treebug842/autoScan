#!/bin/bash

ip=${1}
if [ -z $ip ]; then echo "Invalid, please provide ip address!"
exit; fi
apt list --installed > /opt/install_check.txt 2>/dev/null
nmap_check=$(cat /opt/install_check.txt | grep "nmap/" | cut -d" " -f1)
masscan_check=$(cat /opt/install_check.txt | grep "masscan/" | cut -d" " -f1)
rm /opt/install_check.txt

if [ -z $nmap_check ]; then echo -e "\e[0;31m[+] \e[0mNmap not found!";
echo -e "\e[1;34m[+] \e[0mInstalling..."; apt install nmap -y >/dev/null 2>/dev/null
else echo -e "\e[1;34m[+] \e[0mNmap has been detected"; fi

if [ -z $masscan_check ]; then echo -e "\e[0;31m[+] \e[0mMasscan not detected!"
echo -e "\e[1;34m[+] \e[0mInstalling"; apt install masscan -y >/dev/null 2>/dev/null
else echo -e "\e[1;34m[+] \e[0mMasscan has been detected"; fi

ifconfig | grep "flags" | cut -d":" -f1 > /opt/temp.txt
tun0_check=$(cat /opt/temp.txt|grep "tun0")
if [ -z $tun0_check ]; then interface=wlan0; else
interface=tun0; echo -e "\e[1;34m[+] \e[0mVPN tunnel detected"; fi
echo -e "\e[1;34m[+] \e[0mStarting Scans..." && rm /opt/temp.txt
masscan -e $interface -p0-65535 --max-rate 500 $ip > /opt/scan_temp.txt 2>/dev/null
cat /opt/scan_temp.txt | cut -d" " -f4 | cut -d"/" -f1 > /opt/scan_temp2.txt
mapfile -t port < /opt/scan_temp2.txt
current=0 && rm /opt/scan_temp.txt
while [ ! -z ${port[current]} ]; do
echo -e "\e[0;32m[+] \e[0mOpen port discovered ${port[current]}"
nmap -A -p${port[current]} $ip >  port${port[current]}.txt
let current++; done
rm /opt/scan_temp2.txt
echo -e "\e[1;34m[+] \e[0mFinished"
