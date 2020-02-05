#!/bin/bash

parsing_dir=$(mktemp -d "${TMPDIR:-/tmp/}$(basename $0).XXXXXXXXXXXX")
current_dir=$(pwd)

# Function that prints out help details
show_usage() {
printf "\nUsage: autoScan [Target] [Options]\n \n "
echo "OPTIONS:"
echo "   -h: Prints out usage and options"
echo "   -o: Output directory to save files to"
echo "   -u: Set target to a URL"
echo "   -i: Set target to an IP address"
printf "   -t: Forces scan to use default gateway\n \n "
}

# Creates flag variables
h_flag='false'
o_flag=''
u_flag=''
i_flag=''
t_flag='false'

# Sets flag value when called upon
while getopts 'ho:u:i:tv' flag; do
case "${flag}" in
h) h_flag='true' ;;
o) o_flag="${OPTARG}" ;;
u) u_flag="${OPTARG}" ;;
i) i_flag="${OPTARG}" ;;
t) t_flag='true' ;;
esac
done

# Prints usage guide if h flag is true
if [ $h_flag == true ]; then
show_usage
exit
fi

# Sets output directory if selected
if [ ! -z $o_flag ]; then
save_directory=$o_flag
else
save_directory=$(pwd)
fi

# Checks to see if an IP was given
if [ -z $u_flag ] && [ -z $i_flag ]; then
echo "Invalid, please provide a target with -i or -u"
exit
fi

# Function that checks if host is up
ip-check() {
ping -c 1 $verify_ip > $parsing_dir/host-check.txt 2>/dev/null
mapfile -t hostline < $parsing_dir/host-check.txt
verify=$(echo ${hostline[0]} | cut -d" " -f1)
if [ -z $verify ]; then
echo "Host is down or does not exist"
exit
fi
}

# Converts url to ip if u flag is given
if [ ! -z $u_flag ]; then
verify_ip=$u_flag
ip-check
nslookup $u_flag > $parsing_dir/nslookup.txt
cat $parsing_dir/nslookup.txt|grep -v "192.168."|grep "Address:"|cut -d" " -f2 > $parsing_dir/nslookup_ips.txt
mapfile -t ips <$parsing_dir/nslookup_ips.txt
ip=${ips[0]}
fi

# Sets ip if called upon
if [ ! -z $i_flag ]; then
verify_ip=$i_flag
ip-check
ip=$i_flag
fi

# Check to see if nmap and masscan is installed
apt list --installed > $parsing_dir/installed_packages.txt 2>/dev/null
nmap_check=$(cat $parsing_dir/installed_packages.txt | grep "nmap/" | cut -d" " -f1 | head -n 1)
masscan_check=$(cat $parsing_dir/installed_packages.txt | grep "masscan/" | cut -d" " -f1 | head -n 1)

# Installs nmap if its not installed
if [ -z $nmap_check ]; then
echo -e "\e[0;31m[+] \e[0mNmap not found!";
echo -e "\e[1;34m[+] \e[0mInstalling..."
apt install nmap -y >/dev/null 2>/dev/null
else
echo -e "\e[1;34m[+] \e[0mNmap has been detected"
fi

# Installs masscan if its not installed
if [ -z $masscan_check ]; then
echo -e "\e[0;31m[+] \e[0mMasscan not detected!"
echo -e "\e[1;34m[+] \e[0mInstalling"
apt install masscan -y >/dev/null 2>/dev/null
else
echo -e "\e[1;34m[+] \e[0mMasscan has been detected"
fi

# Check to see if you are connected to a vpn
ifconfig | grep "flags" | cut -d":" -f1 > $parsing_dir/htb_tunnel.txt
tun0_check=$(cat $parsing_dir/htb_tunnel.txt | grep "tun0")

# Uses vpn tunnel in masscan if detected
if [ $t_flag == false ]; then
if [ ! -z $tun0_check ]; then
interface="-e tun0 "
ping_interface="-I tun0"
echo -e "\e[1;34m[+] \e[0mVPN tunnel detected"
fi
fi

# Check to make sure VPN isnt interfereing
ping -c 1 $ping_interface $ip > $parsing_dir/ping_test.txt
vpn_check=$(cat $parsing_dir/ping_test.txt | grep "received" | cut -d" " -f4)
if [ $vpn_check == 0 ]; then
echo -e "\e[0;31m[+] \e[0mUnable to connect to host!"
echo "If you are using a VPN try using script with/without -t"
exit
fi

# Runs the masscan
echo -e "\e[1;34m[+] \e[0mStarting Scans..."
masscan $interface-p0-65535 --max-rate 500 $ip > $parsing_dir/masscan.txt 2>/dev/null
cat $parsing_dir/masscan.txt | cut -d" " -f4 | cut -d"/" -f1 > $parsing_dir/open_ports.txt
mapfile -t port < $parsing_dir/open_ports.txt
current=0

# Goes through the open ports and scans them
while [ ! -z ${port[current]} ]; do
echo -e "\e[0;32m[+] \e[0mOpen port discovered ${port[current]}"
nmap -A -p${port[current]} $ip > $save_directory/port${port[current]}.txt
let current++
done

echo -e "\e[1;34m[+] \e[0mFinished"
