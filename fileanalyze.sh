#!/bin/bash
export PATH=$PATH:/usr/games

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


#the script requires a sudo user this function will check if user==root
function rootcheck(){
    USER=$(whoami)
    
    if [ "$USER" == "root" ] #if sudo 
    then
        echo -e "${LIGHT_BLUE}###################################################${NC}"
echo -e "${YELLOW}$(figlet 'Analyzer')${NC}"
echo -e "${LIGHT_BLUE}###################################################${NC}"

        echo -e "${GREEN}Your User is admin great!${NC}"
    else #if not sudo 
        clear
   echo -e "${RED}╔════════════════════════════════════════╗${NC}"
    echo -e "${RED}║                                        ║${NC}"
    echo -e "${RED}║         !!! ACCESS DENIED !!!          ║${NC}"
    echo -e "${RED}║                                        ║${NC}"
    echo -e "${RED}║   This script requires ROOT access!    ║${NC}"
    echo -e "${RED}║                                        ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════╝${NC}"
    echo -e "${YELLOW}Rerun with: ${UNDERLINE}sudo $0${NC}"
        sleep 1
        exit # If the user is not root, the 'exit' command will throw the user out from the script
    fi
}

function toolcheck(){ #checking if the user has all the tools 
    # List of required tools
    
    echo -e "${YELLOW}Checking for required tools...${NC}"
    sleep 2 
    for tool in strings binwalk bulk_extractor foremost cowsay #tool check 
    do
        check=$(command -v $tool)
        if [ -z "$check" ]
        then
            echo -e "${YELLOW}[${RED}✗${YELLOW}] $tool is NOT installed${NC}"
            echo -e "${RED}Installing missing tools${NC}"
       sudo apt-get update &> /dev/null
       sudo apt-get install $tool -y &> /dev/null # missing tool install 
	    echo -e "${YELLOW}[${GREEN}✓${NC}${YELLOW}] $tool is installed${NC}"
        else
         echo -e "${YELLOW}[${GREEN}✓${NC}${YELLOW}] $tool is installed${NC}"
          fi
    done
}

function filecheck() #check if file exist
{
    read -p $'\e[1;33mInsert a file to analyze (full path): \e[0m' MAIN_FILE
    if [ -f "$MAIN_FILE" ]
    then
        echo -e "${GREEN}The file does exist!${NC}" #if file is valid 
    else
        echo -e "${RED}The file does not exist, try again...${NC}" #if file is not valid 
        sleep 2
        clear #clears the screen
        filecheck
    fi
}
function carving()
{
    read -p $'\e[1;33mInsert a name of a new folder to save the data:\e[0m' MAIN_FOLDER
    	echo -e "${LIGHT_BLUE}"
cowsay -f tux "Analyzing the file :"
echo -e "Be aware this process may take a few minutes"
echo -e "${NC}"
    
    
    mkdir $MAIN_FOLDER #Under this folder all the data will be saved
    
    chmod 777 $MAIN_FOLDER
    bulk_extractor $MAIN_FILE -o $MAIN_FOLDER/bulk_data &>/dev/null
    foremost $MAIN_FILE -t all -o $MAIN_FOLDER/foremost_data &>/dev/null 
    #binwalk -e $MAIN_FILE -C $MAIN_FOLDER/binwalk_data --run-as=root &>/dev/null #optinal will pull out alot of gb 
   mkdir -p "$MAIN_FOLDER/binwalk_data"
   binwalk "$MAIN_FILE" > "$MAIN_FOLDER/binwalk_data/analysis.txt"
   #Strings cant create its own folder, so we will do it for him
    mkdir $MAIN_FOLDER/strings_data
    strings $MAIN_FILE | grep -i password > $MAIN_FOLDER/strings_data/password.txt #strings password
    strings $MAIN_FILE | grep -i mail > $MAIN_FOLDER/strings_data/mail.txt  #strings mail 
    strings $MAIN_FILE | grep -i exe > $MAIN_FOLDER/strings_data/exe.txt  #strings  exe
    strings $MAIN_FILE | grep -i http > $MAIN_FOLDER/strings_data/http.txt  #strings http  
     chmod -R 777 $MAIN_FOLDER #gives full perm to main folder 

}
function pcapcheck ()
{
 pcap=$(find $MAIN_FOLDER/bulk_data -name *.pcap) #checks if pcap file is alive 
if [ -z "$pcap" ]
then 
echo -e "${RED}there is no pcap file${NC}"
else 
echo -e "${GREEN}pcap file found!${NC}"  #if pcap found 
echo -e "${YELLOW}the Location of the pcap file:${NC}"
echo -e "${YELLOW}$pcap${NC}"

fi
}

function vol ()
{
read -p $'\e[1;33mIs your main file a memory (y/n)\e[0m' choice 
if [ "$choice" == "y" ]
then 
#install vol and  run it 
   	echo -e "${LIGHT_BLUE}"
cowsay -f hellokitty "Getting volatility to analyze the file :"
echo -e "${NC}"

wget -q https://github.com/volatilityfoundation/volatility/releases/download/2.6.1/volatility_2.6_lin64_standalone.zip 
unzip -qj volatility_2.6_lin64_standalone.zip volatility_2.6_lin64_standalone/volatility_2.6_lin64_standalone 
rm volatility_2.6_lin64_standalone.zip
mv volatility_2.6_lin64_standalone vol
sudo chmod 777 vol 
 echo -e "${LIGHT_BLUE}"
cowsay -f hellokitty "Analyzing the mem file:"
echo -e "${NC}"

 PROFILE=$(./vol -f $MAIN_FILE imageinfo 2>/dev/null | grep 'Suggested' | awk '{print $4}' | awk -F',' '{print $1}')
echo -e "${YELLOW}Your mem profile is:${NC}" $PROFILE
  mkdir $MAIN_FOLDER/Volatility_data
./vol -f $MAIN_FILE --profile=$PROFILE pslist > $MAIN_FOLDER/Volatility_data/pslist.txt 2>/dev/null #Extract processes
./vol -f $MAIN_FILE --profile=$PROFILE hivelist > $MAIN_FOLDER/Volatility_data/hivelist.txt 2>/dev/null #Extract registry list
./vol -f $MAIN_FILE --profile=$PROFILE netscan > $MAIN_FOLDER/Volatility_data/nestscan.txt 2>/dev/null  #Extract netscan list
./vol -f $MAIN_FILE --profile=$PROFILE cmdline > $MAIN_FOLDER/Volatility_data/cmdline.txt 2>/dev/null  #Extract cmdline list 

rm vol


else 
echo -e "${YELLOW}Nevermind${NC}"

fi
}
function sum () # this is gona sum up everthing
{
echo "###################################################" >> $MAIN_FOLDER/report.txt
figlet 'Results' >> $MAIN_FOLDER/report.txt
echo "###################################################" >> $MAIN_FOLDER/report.txt

echo -e "${GREEN}###################################################${NC}" 
echo -e "${GREEN}$(figlet 'Scan Completed!')${NC}"
echo -e "${GREEN}###################################################${NC}"
echo -e "${GREEN}All extracted data has been saved to:$MAIN_FOLDER${NC}" 
echo ""
echo "Summary of extracted data:" >> $MAIN_FOLDER/report.txt
echo "1. bulk_extractor data: $MAIN_FOLDER/bulk_data" >> $MAIN_FOLDER/report.txt #bulkdata location 
echo "2. foremost data: $MAIN_FOLDER/foremost_data" >> $MAIN_FOLDER/report.txt #foremost location 
echo "3. binwalk data: $MAIN_FOLDER/binwalk_data" >> $MAIN_FOLDER/report.txt #binwalk location 
echo "4. strings data: $MAIN_FOLDER/strings_data" >> $MAIN_FOLDER/report.txt #string location 
  
    if [ -d "$MAIN_FOLDER/Volatility_data" ]
    then
        echo -e "5.Volatility data:$MAIN_FOLDER/Volatility_data" >> $MAIN_FOLDER/report.txt
     fi

exe=$(find $MAIN_FOLDER -name *.exe | wc -l) #total exe 
fore=$(find $MAIN_FOLDER/foremost_data -type f | wc -l) #total foremost file 
bulk=$(find $MAIN_FOLDER/bulk_data -type f | wc -l) #total bulkdata file 
echo "Total exe files found: $exe" >> $MAIN_FOLDER/report.txt
echo "The number of files in the foremost_data folder: $fore" >> $MAIN_FOLDER/report.txt
  echo "The number of files in the bulk_data folder: $bulk" >> $MAIN_FOLDER/report.txt
   
   # pcap location 
if [ ! -z "$pcap" ]; then
    echo "the Location of the pcap file: $pcap" >> $MAIN_FOLDER/report.txt
fi
   echo -e "${GREEN}A summary of the analysis can be found in $MAIN_FOLDER/report.txt${NC}"
  echo -e "${GREEN}You can now review the extracted files in the folder!${NC}"
  echo -e "${LIGHT_BLUE}Scan completed at: $(date)${NC}"
if [ -d "$MAIN_FOLDER/Volatility_data" ]
then
echo "Your mem profile is:" $PROFILE >> $MAIN_FOLDER/report.txt
fi
echo "" >> $MAIN_FOLDER/report.txt
echo -e "Scan completed at: $(date)" >> $MAIN_FOLDER/report.txt

}
rootcheck #checks if user is sudo 
toolcheck #checks if user has all the tools 
filecheck #gets a file from the user and checks if its a valid 1 
carving # analyze the file and get the data out 
pcapcheck # checking for pcap file wireshark
vol #checking for mem file if file is mem will vol analyze it 
sum #print out a summary txt and will let the user know the scirpt has finshed 
