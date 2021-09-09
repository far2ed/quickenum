#!/bin/bash

# Simple script that launches nmap scans (Top 1000, then Full Half-Open Scan, then Banners Scan).
# We'll use the name of the target to create directory to store the results ouput
# It will also launch a gobuster scan if services found returned an HTTP response
# Ultimately it will launch a UDP port scan, don't hesitate to cancel it if you feel like it is not needed
# usage ./quickenum.sh [Target IP address]

if [ $# -eq 0 ]; then
    echo "Usage ./quickenum.sh [Target IP address]"
    exit 1
fi

if [ $(id -u) -ne 0 ]; then
    echo "This script should be launched as root to avoid ICMP issues"
    exit 1
fi

#RED='\033[0;31m'
#NC='\033[0m' # No Color

mkdir $1 2>/dev/null

echo -e "\n\nShell script that automates nmap and gobuster scans\n\n"

echo -e "\n\n#################################################################\n\n"
echo -e "Top 1000 ports TCP Connect nmap scan\n\n"
echo -e "#################################################################\n\n"

sudo nmap -v -sC -sV -Pn $1 -oN $1/top-1000-$1.txt

echo -e "\n\n#################################################################\n\n"
echo -e "Full SynStealth nmap scan\n\n"
echo -e "#################################################################\n\n"

sudo nmap -v -sS -p- -Pn $1 -oN $1/full-scan-$1.txt

echo -e "\n\n#################################################################\n\n"
echo -e "Sorting open ports from the full-scan output file\n\n"
echo -e "#################################################################\n\n"

cat $1/full-scan-$1.txt | grep open | cut -d '/' -f 1 > $1/open_ports-$1.txt
cat $1/open_ports-$1.txt

echo -e "\n\n#################################################################\n\n"
echo -e "Banner scan on open ports\n\n"
echo -e "#################################################################\n\n"

sudo nmap -v -sC -sV -p $(tr '\n' , < $1/open_ports-$1.txt) $1 -oN $1/banners-$1.txt

echo -e "\n\n#################################################################\n\n"
echo -e "Sorting open ports that returned an HTTP response from the banners scan\n\n"
echo -e "#################################################################\n\n"

cat $1/banners-$1.txt | grep open | grep http | cut -d '/' -f 1 > $1/http_ports-$1.txt 
cat $1/http_ports-$1.txt
#echo -e "{RED}$(cat $1/http_ports-$1.txt){NC})"

echo -e "\n\n#################################################################\n\n"
echo -e "Gobuster scan on the ports that responsed with an HTTP response\n\n"
echo -e "#################################################################\n\n"

for http_port in $(cat $1/http_ports-$1.txt):
    do
        gobuster dir -w /usr/share/wordlists/dirbuster/directory-list-1.0.txt	--url http://$1:$http_port -o $1/gobuster-$1:$http_port.txt
    done

echo -e "\n\n#################################################################\n\n"
echo -e "Full UDP nmap scan\n\n"
echo -e "#################################################################\n\n"

sudo nmap -v -sU -p- $1 -oN $1/udp-scan-$1.txt -Pn
