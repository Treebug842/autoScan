# autoScan

autoScan is made for debian based operating systems (raspberry pi OS's wont work). Its somewhat slow, but considering it scans all ports id give it a pass. When the script starts it will check in nmap and 
masscan is installed, if they arnt then they will be installed. As for the basis of what it actually runs, it first performs a massscan 
on all 65535 ports and finds the one that are open. The actually command being run is...
```
masscan -e (Network Interface) -p0-65535 --max-rate 500 (IP Address)
```
Then it automatically does a more in depth scan on each of the ports that it discovered. The command for that is...
```
nmap -A -p(Port) -oA (Directory/File) (IP Address)
```
As you can see it is very basic, the only thing it has to offer is convinience, its much faster than typing it all, and it automatically
converts urls to ip addresses with the -u flag (masscan dosnt like urls). 

For convinience I suggest moving the script into the /bin directory so it can be run as a command

# Usage

autoScan [Options]

- -h &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; Prints out the usage guide (pretty simple) 
- -t &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; Forces scan to use default gateway (a vpn gateway will take priority) 
- -u [URL] &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; Sets the ytarget to a url 
- -i [IP Address] &nbsp; &nbsp; &nbsp; Sets the target to a IP address 
- -o [Directory/File] &nbsp; &nbsp; &nbsp; &nbsp; Directory to save results (default is current dir) 

  I also feel like the -t flag needs to be explained. What it does is force the scans to operate through the default gateway (instead of a vpn). I made this tool with Hack the Box in mind, so if you are connecte to the HTB network it will automatically use the vpn gaetway. If you specify the gateway with -t then any HTB boxes will not work (or other devices located on VPN Networks) but if you use the vpn gateway then you cannot scan things that are not apart of that network. So be mindful of which option you choose.
  
