#!/bin/bash
##
## Script de BASH para automatizar la configuración de la red
##
##

source /root/rasp/functions.cfg

# --------------------------------------------------------------------------------------------------------------


#dir_copy=`pwd` ;
static_hn=$(hostnamectl --static) ;

# Calcular el número de interfaces ether y wlan, estén o no configuradas (= dongles de red conectados). --------
if_old_arr=($(networkctl | awk '$3~/ether/||$3~/wlan/' | awk '{print $2}')) ;
num_if_old="${#if_old_arr[@]}" ;
num_if_old0=$((${num_if_old} - 1)) ;


# Hacer también un array en el que se indique para estas mismas interfaces si están conectadas o no ------------
#for i in $(0 ${num_if_old0}) ; do
#  networkctl status ${if_old_arr[$i]} |
#  grep -e "${if_old_arr[$i]}" 
#  if [] ; then
#      
#  fi
#done

get_eth_orig ;

# Meto en un un array las interfaces que ya tiene configuradas -------------------------------------------------
if_old_conf_arr=( $(networkctl | awk '($5~/configured/||$5~/configuring/)&&($3~/ether/||$3~/wlan/)' | awk '{print $2}') ) ;
num_if_old_conf="${#if_old_conf_arr[@]}" ;
num_if_old_conf0=$((${num_if_old_conf} - 1)) ;


# Ver si la interfaz if_eth_orig está configurada o no y cambiar consecuentemente el número de interfaces
# configuradas
#if_eth_orig_q=$(networkctl | grep -e "${if_eth_orig}" | awk '{print $5}') ;
#if [ "$if_eth_orig_q" == "configured" ] ; then
#    num_if_old_conf=$((${num_if_old_conf} - 1)) ;
#fi

wpa_s=0;
if [[ -n $(pacman -Qs wpa_supplicant) ]] ; then
    wpa_s=1;
fi

# Eliminación y/o cambio de configuración de las interfaces que ya se encuentran instaladas --------------------
backtitle_var="Configuración de interfaces de red" ;
touch /etc/udev/rules.d/10-network.rules ;
if_new_conf_arr=() ;
num_if_new_conf=$num_if_old_conf ;
num_if_new_conf0=$num_if_old_conf0 ;
for i in $(seq 0 ${num_if_old0}) ; do
    if_old_mac_addr=$(networkctl status ${if_old_arr[$i]} | awk '$1~/HW/&&$2~/Address:/' | awk '{print $3}') ;
    if_old_driver=$(networkctl status ${if_old_arr[$i]} | awk '$1~/Driver:/' | awk '{print $2}') ;
    if_old_type=$(networkctl status ${if_old_arr[$i]} | awk '$1~/Type:/' | awk '{print $2}') ;
    if [[ "${if_old_arr[$i]}" == *"${if_eth_orig}"* ]] ; then
        verb_eth0="y corresponde a la interfaz ethernet de red de su Raspberry Pi 2; no a una
                  conectada por USB" ;
      else
        verb_eth0="" ;
    fi
    if [[ -n $(networkctl | awk '($5~/configured/||$5~/configuring/)&&($3~/ether/||$3~/wlan/)' | awk '{print $2}') ]] ; then
        verb_conf=", que se encuentra configurada" ;
      else
        verb_conf=", que no se encuentra configurada" ;
    fi
    if_choice=$(dialog  --backtitle "$backtitle_var" \
                        --title     "Configuración de interfaces de red" --clear \
                        --menu      "Ahora mismo se encuentra instalada la interfaz ${if_old_arr[$i]} en
                                    su sistema${verb_conf}${verb_eth0}. Seleccione qué desea hacer." 0 0 0 \
                "Dejar la interfaz tal y como está"     "aaaa"  \
                "Eliminar la interfaz"                  "bbbb"  \
                "Cambiar el designador de la interfaz"  "cccc"  3>&1 1>&2 2>&3) ;
    case $if_choice in
      "Dejar la interfaz tal y como está")
        ;;
      "Eliminar la interfaz")
        dialog  --backtitle "$backtitle_var" \
                --title     "Eliminación de interfaz de red" --clear \
                --msgbox    "Se eliminará entonces la interfaz ${if_old_arr[$i]}" 0 0 ;
        rm /etc/systemd/network/${if_old_arr[$i]}.{link,network} ;
        sed -i "/NAME=\"${if_old_arr[$i]}\"/d" /etc/udev/rules.d/10-network.rules ;;
        # systemctl disable network-wireless@${if_old_arr[$i]}.service 
      "Cambiar el designador de la interfaz")
        if_new_conf_arr[$i]=$(dialog  --backtitle "$backtitle_var" \
                                      --title     "Cambio del designador de la interfaz" --clear \
                                      --inputbox  "¿Cómo desea que se llame ahora la interfaz 
                                                  ${if_old_arr[$i]}?" 0 0 3>&1 1>&2 2>&3) ;
        rm /etc/systemd/network/${if_old_arr[$i]}.{link,network}
        sed -i "/NAME=\"${if_old_arr[$i]}\"/d" /etc/udev/rules.d/10-network.rules
        # Comprobar que el nombre no esté usado ni se vaya a usar
        chck_rgx net_if if_new_conf_arr[$i] de_red ;
#        if_new_conf_mac_addr=$(networkctl status ${if_old_conf_arr[$i]} | awk '$1~/HW/&&$2~/Address:/' | awk '{print $3}') ;
#        if_new_conf_driver=$(networkctl status ${if_old_conf_arr[$i]} | awk '$1~/Driver:/' | awk '{print $2}') ;
#        if_new_conf_type=$(networkctl status ${if_olf_conf_arr[$i]} | awk '$1~/Type:/' | awk '{print $2}') ;
        printf "[Match]\n" > /etc/systemd/network/${if_new_conf_arr[$i]}.link ;
        printf "MACAddress=${if_old_mac_addr}\n" >> /etc/systemd/network/${if_new_conf_arr[$i]}.link ;
        printf "Driver=${if_old_driver}\n" >> /etc/systemd/network/${if_new_conf_arr[$i]}.link ;
        printf "# Path=pci-0000:02:00.0-*\n" >> /etc/systemd/network/${if_new_conf_arr[$i]}.link ;
        printf "Type=${if_old_type}\n" >> /etc/systemd/network/${if_new_conf_arr[$i]}.link ;
        printf "Virtualization=no\n" >> /etc/systemd/network/${if_new_conf_arr[$i]}.link ;
        printf "Host=${static_hn}\n" >> /etc/systemd/network/${if_new_conf_arr[$i]}.link ;
        printf "# Architecture=x86-64\n" >> /etc/systemd/network/${if_new_conf_arr[$i]}.link ;
        printf "\n" >> /etc/systemd/network/${if_new_conf_arr[$i]}.link ;
        printf "[Link]\n" >> /etc/systemd/network/${if_new_conf_arr[$i]}.link ;
        printf "Name=${if_new_conf_arr[$i]}\n" >> /etc/systemd/network/${if_new_conf_arr[$i]}.link ;
        printf "# MTUBytes=1480\n" >> /etc/systemd/network/${if_new_conf_arr[$i]}.link ;
        printf "# BitsPerSecond=10M\n" >> /etc/systemd/network/${if_new_conf_arr[$i]}.link ;
        printf "# WakeOnLan=magic\n" >> /etc/systemd/network/${if_new_conf_arr[$i]}.link ;
        printf "MACAddress=${if_old_mac_addr}" >> /etc/systemd/network/${if_new_conf_arr[$i]}.link ;
        printf "[Match]\n" > /etc/systemd/network/${if_new_conf_arr[$i]}.network ;
        printf "Name=${if_new_conf_arr[$i]}\n" >> /etc/systemd/network/${if_new_conf_arr[$i]}.network ;
        printf "Host=${static_hn}\n" >> /etc/systemd/network/${if_new_conf_arr[$i]}.network ;
        printf "\n" >> /etc/systemd/network/${if_new_conf_arr[$i]}.network ;
        printf "[Network]\n" >> /etc/systemd/network/${if_new_conf_arr[$i]}.network ;
        printf "DHCP=ipv4\n" >> /etc/systemd/network/${if_new_conf_arr[$i]}.network ;
        printf "\n" >> /etc/systemd/network/${if_new_conf_arr[$i]}.network ;
        printf "[DHCP]\n" >> /etc/systemd/network/${if_new_conf_arr[$i]}.network ;
        printf "# RouteMetric=" >> /etc/systemd/network/${if_new_conf_arr[$i]}.network ;
        printf "SUBSYSTEM==\"net\", ACTION==\"add\", " >> /etc/udev/rules.d/10-network.rules ;
        printf "ATTR{address}==\"${if_old_mac_addr}\", " >> /etc/udev/rules.d/10-network.rules ;
        printf "NAME=\"${if_new_conf_arr[$i]}\"" >> /etc/udev/rules.d/10-network.rules ;;
        # systemctl disable network-wireless@${if_old_arr[$i]}.service 
    esac 

#  if_old_type=$(networkctl status ${if_old_conf_arr[$i]} | awk '$1~/Type:/' | awk '{print $2}') ;
#  if_old_driver=$(networkctl status ${if_old_conf_arr[$i]} | awk '$1~/Driver:/' | awk '{print $2}') ;
  if [ "$if_old_type" == "wlan" ] || [ "$if_old_driver" == "rtl8192cu" ] ; then
      if [ $wpa_s -ne 1 ] ; then
          dialog  --backtitle "$backtitle_var" \
                  --title     "Configuración de interfaces de red" --clear \
                  --msgbox    "Ahora se instalará el software WPA Supplicant para que pueda conectarse a redes
                              wifi." 0 0 ;
          pacman -S wpa_supplicant ;
          while [[ -z $(pacman -Qs wpa_supplicant) ]] ; do
            dialog  --backtitle "$backtitle_var" \
                    --title     "Configuración de interfaces de red" --clear \
                    --msgbox    "No ha sido posible instalar el paquete wpa_supplicant. Se volverá a intentar
                                después de que pinche en OK." 0 0 ;
            pacman -S wpa_supplicant ;
          done
          wpa_s=1;
          mv network/network-wireless@.service /etc/systemd/system/ ;
          rm /etc/wpa_supplicant/wpa_supplicant.conf ;
      fi
      touch /etc/wpa_supplicant/wpa_supplicant-${if_old_arr[$i]}.conf ;
      cat network/wpa_supplicant-skel.conf > /etc/wpa_supplicant/wpa_supplicant-${if_new_conf_arr[$i]}.conf ;
      dialog  --backtitle "$backtitle_var" \
              --title     "Configuración de interfaces de red" --clear \
              --msgbox    "Le recuerdo que tendrá que crear un fichero
                          /etc/wpa_supplicant/wpa_supplicant-${if_new_conf_arr[$i]} para poder conectar la
                          interfaz ${if_new_conf_arr[$i]} a la red que desee." 0 0 ;
      dialog  --backtitle "$backtitle_var" \
              --title     "Configuración de interfaces de red" --clear \
              --yesno     "¿Desea hacer que se conecte automáticamente con la interfaz
                          ${if_new_conf_arr[$i]} a una red wifi?" 0 0 ;
      response=$? ;
      while [ "$response" == "0" ] ; do
        printf "Introduzca el ESSID de dicha red: " ;
        read essid ;
        printf "Introduzca ahora la passphrase: " ;
        read passphrase ;
        # Regex: cuidado con los símbolos raros como #. Ahora no me da problemas en eso. Quizás es porque he
        # configurado el idioma del teclado.
        wpa_passphrase $essid $passphrase >> /etc/wpa_supplicant/wpa_supplicant-${if_new_conf_arr[$i]}.conf ;
        dialog  --backtitle "$backtitle_var" \
                --title     "Configuración de interfaces de red" --clear \
                --yesno     "¿Desea introducir los datos de otra red a la que quiera conectarse con la
                            interfaz ${if_new_conf_arr[$i]}?" 0 0 ;
        response=$? ;
      done
      # En un futuro, se eliminará esta parte.
      dialog  --backtitle "$backtitle_var" \
              --title     "Configuración de interfaces de red" --clear \
              --yesno     "¿Desea copiar mi fichero para conexión a redes wifi?" 0 0 ;
      response=$? ;
      if [ "$response" == "0" ] ; then
        cat network/wpa_supplicant-zfur.conf > /etc/wpa_supplicant/wpa_supplicant-${if_new_conf_arr[$i]}.conf ;
      fi
      dialog  --backtitle "$backtitle_var" \
              --title     "Configuración de interfaces de red" --clear \
              --yesno     "¿Desea habilitar el servicio wifi de red para la interfaz ${if_new_conf_arr[$i]}?" 0 0 ;
      response=$? ;
      if [ "$response" == "0" ] ; then
          systemctl enable network-wireless@${if_new_conf_arr[$i]}.service ;
      fi
  fi

done
# Sólo si se reinicia ahora
#echo "$num_if_new" > num-if-new ;
#echo "$num_if_new0" > num-if-new0 ;


# Creo que se puede reload las interfaces de red sin reiniciar, pero no soy capaz
# vea http://unix.stackexchange.com/questions/39370/how-to-reload-udev-rules-without-reboot
# Si no soy capaz, sería mejor reiniciar


# Suponemos que hemos reiniciado todo el sistema o hemos reiniciado sólo las interfaces de red

# Sólo si se ha reiniciado
#num_if_new=$(cat num-if-new) ;
#num_if_new0=$(cat num-if-new0) ;

# Meto en un un array las interfaces que ya tiene configuradas -------------------------------------------------
# Está antes tb. Quizás se pueda eliminar la de antes
if_new_conf_arr=( $(networkctl | awk '($5~/configured/||$5~/configuring/)&&($3~/ether/||$3~/wlan/)' | awk '{print $2}') ) ;
num_if_new_conf="${#if_new_conf_arr[@]}" ;
num_if_new_conf0=$((${num_if_new_conf} - 1)) ;

get_eth_orig ;

# Comprobar si queda instalada la interfaz ethernet original ---------------------------------------------------
if_eth_orig_q=$(networkctl | grep -e "${if_eth_orig}" | awk '{print $5}') ;
if [ "$if_eth_orig_q" == "configured" ] ; then
    tope=5;
  else
    tope=4;
fi


# Instalación de interfaces adicionales ------------------------------------------------------------------------
backtitle_var="Instalación de interfaces de red adicionales" ;
dialog  --backtitle "$backtitle_var" \
        --title     "Instalación de interfaces de red adicionales" --clear \
        --yesno     "¿Desea instalar alguna otra interfaz?" 0 0 ;
response=$? ;
while [ "$response" == "0" ] && [ $num_if_newconf0 -le $tope ] ; do
  networkctl | awk '{print $2}' > if_before ;
  dialog  --backtitle "$backtitle_var" \
          --title     "Configuración de interfaces de red" --clear \
          --msgbox    "Conecte ahora a un puerto USB de su Raspberry Pi 2 el dongle que desea instalar en su
                      sistema. Conecte sólo uno; si quiere añadir varios, deberá ir conectándolos uno a
                      uno." 0 0 ;
  networkctl | awk '{print $2}' > if_after ;
  if_new=$(grep -v -F -x -f if_before if_after) ;
  # Comprobar que se ha añadido efectivamente una nueva interfaz; si se han añadido más o ninguna, bucle
  if_new_type=$(networkctl status $if_new | awk '$1~/Type:/' | awk '{print $2}') ;
  if_new_mac_addr=$(networkctl status $if_new | awk '$1~/HW/&&$2~/Address:/' | awk '{print $3}') ;
  if_new_driver=$(networkctl status $if_new | awk '$1~/Driver:/' | awk '{print $2}') ;
  dialog  --backtitle "$backtitle_var" \
          --title     "Configuración de interfaces de red" --clear \
          --yesno     "Ahora mismo, el designador de esta interfaz es ${if_new}. ¿Desea cambiarlo?" 0 0 ;
  response=$? ;
  if [ "$response" == "0" ] ; then
      if_new=$(dialog --backtitle "$backtitle_var" \
                      --title     "Configuración de interfaces de red" --clear \
                      --inputbox  "¿Cuál desea que sea ahora el designador?" 0 0 3>&1 1>&2 2>&3) ;
      # Comprobar que el nombre no esté usado ni se vaya a usar
      chck_rgx net_if if_new de_red ;
      printf "SUBSYSTEM==\"net\", ACTION==\"add\", ATTR{address}==\"${if_new_mac_addr}\", NAME=\"${if_new}\"" >> /etc/udev/rules.d/10-network.rules ;
  fi
  if [ "$if_new_type" == "wlan" ] ; then
      if [ $wpa_s -ne 1 ] ; then
          dialog  --backtitle "$backtitle_var" \
                  --title     "Configuración de interfaces de red" --clear \
                  --msgbox    "Ahora se instalará el software WPA Supplicant para que pueda conectarse a redes
                              wifi." 0 0 ;
          pacman -S wpa_supplicant ;
          while [[ -z $(pacman -Qs wpa_supplicant) ]] ; do
            dialog  --backtitle "$backtitle_var" \
                    --title     "Configuración de interfaces de red" --clear \
                    --msgbox    "No ha sido posible instalar el paquete wpa_supplicant. Se volverá a intentar
                                después de que pinche en OK." 0 0 ;
            pacman -S wpa_supplicant ;
          done
          wpa_s=1;
          mv network/network-wireless@.service /etc/systemd/system/ ;
          rm /etc/wpa_supplicant/wpa_supplicant.conf ;
      fi
      touch /etc/wpa_supplicant/wpa_supplicant-${if_new}.conf ;
      cat network/wpa_supplicant-skel.conf > /etc/wpa_supplicant/wpa_supplicant-${if_new}.conf ;
      dialog  --backtitle "$backtitle_var" \
              --title     "Configuración de interfaces de red" --clear \
              --msgbox    "Le recuerdo que tendrá que crear un fichero
                          /etc/wpa_supplicant/wpa_supplicant-${wl_if} para poder conectar la interfaz ${wl_if}
                          a la red que desee. Luego, pinche en OK." 0 0 ;
      dialog  --backtitle "$backtitle_var" \
              --title     "Configuración de interfaces de red" --clear \
              --yesno     "¿Desea hacer que se conecte automáticamente con la interfaz ${if_new} a una red
                          wifi?" 0 0 ;
      response=$? ;
      while [ "$response" == "0" ] ; do
        printf "Introduzca el ESSID de dicha red: " ;
        read essid ;
        printf "Introduzca ahora la passphrase: " ;
        read passphrase ;
        # Regex: cuidado con los símbolos raros como #. Ahora no me da problemas en eso. Quizás es porque he
        # configurado el idioma del teclado.
        wpa_passphrase $essid $passphrase >> /etc/wpa_supplicant/wpa_supplicant-${if_new}.conf ;
        dialog  --backtitle "$backtitle_var" \
                --title     "Configuración de interfaces de red" --clear \
                --yesno     "¿Desea introducir los datos de otra red a la que quiera conectarse con la
                            interfaz ${if_new}?" 0 0 ;
        response=$? ;
      done
      # En un futuro, se eliminará esta parte.
      dialog  --backtitle "$backtitle_var" \
              --title     "Configuración de interfaces de red" --clear \
              --yesno     "¿Desea copiar mi fichero para conexión a redes wifi?" 0 0 ;
      response=$? ;
      if [ "$response" == "0" ] ; then
        cat network/wpa_supplicant-zfur.conf > /etc/wpa_supplicant/wpa_supplicant-${if_new}.conf ;
      fi
      dialog  --backtitle "$backtitle_var" \
              --title     "Configuración de interfaces de red" --clear \
              --yesno     "¿Desea habilitar el servicio wifi de red para la interfaz ${if_new}?" 0 0 ;
      response=$? ;
      if [ "$response" == "0" ] ; then
          systemctl enable network-wireless@${wl_if}.service ;
      fi
  fi
  printf "[Match]\n" > /etc/systemd/network/${if_new}.link ;
  printf "MACAddress=${if_new_mac_addr}\n" >> /etc/systemd/network/${if_new}.link ;
  printf "Driver=${if_new_driver}\n" >> /etc/systemd/network/${if_new}.link ;
  printf "# Path=pci-0000:02:00.0-*\n" >> /etc/systemd/network/${if_new}.link ;
  printf "Type=${if_new_type}\n" >> /etc/systemd/network/${if_new}.link ;
  printf "Virtualization=no\n" >> /etc/systemd/network/${if_new}.link ;
  printf "Host=${static_hn}\n" >> /etc/systemd/network/${if_new}.link ;
  printf "# Architecture=x86-64\n" >> /etc/systemd/network/${if_new}.link ;
  printf "\n" >> /etc/systemd/network/${if_new}.link ;
  printf "[Link]\n" >> /etc/systemd/network/${if_new}.link ;
  printf "Name=${if_new}\n" >> /etc/systemd/network/${if_new}.link ;
  printf "# MTUBytes=1480\n" >> /etc/systemd/network/${if_new}.link ;
  printf "# BitsPerSecond=10M\n" >> /etc/systemd/network/${if_new}.link ;
  printf "# WakeOnLan=magic\n" >> /etc/systemd/network/${if_new}.link ;
  printf "MACAddress=${if_new_mac_addr}" >> /etc/systemd/network/${if_new}.link ;
  printf "[Match]\n" > /etc/systemd/network/${if_new}.network ;
  printf "Name=${if_new}\n" >> /etc/systemd/network/${if_new}.network ;
  printf "Host=${static_hn}\n" >> /etc/systemd/network/${if_new}.network ;
  printf "\n" >> /etc/systemd/network/${if_new}.network ;
  printf "[Network]\n" >> /etc/systemd/network/${if_new}.network ;
  printf "DHCP=ipv4\n" >> /etc/systemd/network/${if_new}.network ;
  printf "\n" >> /etc/systemd/network/${if_new}.network ;
  printf "[DHCP]\n" >> /etc/systemd/network/${if_new}.network ;
  printf "# RouteMetric=" >> /etc/systemd/network/${if_new}.network ;
  num_if_new_conf=$(($num_if_new_conf + 1)) ;
  num_if_new_conf0=$(($num_if_new_conf0 + 1)) ;
  dialog  --backtitle "$backtitle_var" \
          --title     "Configuración de interfaces de red" --clear \
          --yesno     "¿Desea instalar alguna otra interfaz de red en su Raspberry Pi 2?" 0 0 ;
  response=$? ;
  if [ "$response" == "0" ] && [ $num_if_new0 -eq $tope ] ; then
      dialog  --backtitle "$backtitle_var" \
              --title     "Configuración de interfaces de red" --clear \
              --msgbox    "Lo siento, pero no quedan puertos USB libres en su sistema para instalar nuevas \
                          interfaces de red. Pinche en OK" 0 0 ;
  fi
done
rm if_before ;
rm if_after ;


# Reinicio -----------------------------------------------------------------------------------------------------
backtitle_var="Reinicio" ;
dialog  --backtitle "$backtitle_var" \
        --title     "" --clear \
        --yesno     "Ahora es aconsejable que reinicie su Raspberry Pi 2. ¿Desea reiniciar?" 0 0 ;
response=$? ;
case $response in
  0)
    printf "Reiniciando\n" ;
    systemctl reboot ;;
  1)
    exit ;;
  255)
    echo "Ha pulsado Esc." ;;
esac
