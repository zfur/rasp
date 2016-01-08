#!/bin/bash
##
## Script de BASH para automatizar la instalación complementaria de mis Raspberry Pi 2
##
##

source /root/rasp/functions.cfg

# ------------------ Script ------------------------------------------------------------------------------------
# --------------------------------------------------------------------------------------------------------------

#dir_copy=`pwd` ;

# Bienvenida ---------------------------------------------------------------------------------------------------
if [[ -z "$(pacman -Qs dialog)" ]] ; then
    read -n1 -rsp $'Bienvenido al instalador de Arch Linux para Raspberry Pi 2, creado por zFur. Presione
    cualquier tecla para continuar o, si lo prefiere, puede salir de este asistente con la combinación de teclas
    Ctrl+C.\n' ;
    printf "\n" ;
    read -n1 -rsp $'Ahora se instalará el paquete dialog para que pueda usar una interfaz TUI (terminal user
    interface). Pulse cualquier tecla para continuar o, si lo prefiere, salga de este asistente con la
    combinación de teclas Ctrl+C.\n\n' ;
    pacman -S dialog ;
    while [[ -z "$(pacman -Qs dialog)" ]] ; do
      read -n1 -rsp $'No ha sido posible instalar el paquete dialog. Se volverá a intentar después de que pulse
      cualquier tecla.\n' ;
      pacman -S dialog ;
    done
  else
    dialog  --backtitle "Bienvenido" \
            --title     "Bienvenido al instalador de Arch Linux de zFur" --clear \
            --msgbox    "Bienvenido al instalador de Arch Linux para Raspberry Pi 2, creado por zFur." 0 0 ;

fi


# Idioma y teclado ---------------------------------------------------------------------------------------------
backtitle_var="Configuración del idioma y teclado" ;
dialog  --backtitle "$backtitle_var" \
        --title     "Configuración del idioma y teclado" --clear --trim \
        --msgbox    "Ahora se le pedirá que indique qué idioma desea para que su sistema se comunique con
                    usted y qué idioma desea usar para comunicarse usted con su sistema (es decir, qué
                    mapeado de teclas desea que use su teclado)." 0 0 ;

#cp -t /usr/share/i18n/locales/ /root /rasp/locales/zfur_en_US /root/rasp/locales/zfur_es_ES ;
cp locales/zfur_en_US /usr/share/i18n/locales/ ;
cp locales/zfur_es_ES /usr/share/i18n/locales/ ;
cp keymap/zfur_es.map.gz /usr/share/kbd/keymaps/i386/qwerty/ ;

until [ "$repeat_q" == "0" ] ; do

  sed -i "/^[^#]/s/^/#/g" /etc/locale.gen ; # Comenta las líneas no comentadas
  sed -i "/^##[#]*/s/^[#]*/#/g" /etc/locale.gen ; # Quita los símbolos # de más
  
  sed -i "/^#en_US.UTF-8 UTF-8$/s/^#//" /etc/locale.gen 
  sed -i "/^#en_US ISO-8859-1$/s/^#//" /etc/locale.gen 
  sed -i "/^#en_GB.UTF-8 UTF-8$/s/^#//" /etc/locale.gen 
  sed -i "/^#en_GB ISO-8859-1$/s/^#//" /etc/locale.gen 

  lang_sel=$(dialog --backtitle "$backtitle_var" \
                    --title     "Selección de idioma del sistema"  --clear --trim \
                    --menu      "Ahora deberá seleccionar qué idioma desea para su sistema." 0 0 0 \
              "es_ES"       "español de España" \
              "en_US"       "inglés de EEUU" \
              "en_GB"       "inglés de Gran Bretaña" \
              "zfur_es_ES"  "español de España modalidad zFur" \
              "zfur_en_US"  "inglés de EEUU modalidad zFur" \
              "es_EC"       "español de Ecuador" 3>&1 1>&2 2>&3) ;
#  lang_sel=$? ;
  case $lang_sel in
    es_ES)
      sed -i '/^#es_ES.UTF-8 UTF-8/s/^#//' /etc/locale.gen ;
      sed -i '/^#es_ES ISO-8859-1/s/^#//' /etc/locale.gen ;
      locale-gen ;
      localectl set-locale LANG=es_ES.utf8 LANGUAGE=es_ES ;;
    en_US)
      locale-gen ;
      localectl set-locale LANG=en_US.utf8 LANGUAGE=en_US ;;
    en_GB)
      locale-gen ;
      localectl set-locale LANG=en_GB.utf8 LANGUAGE=en_GB ;;
    zfur_es_ES)
      sed -i '/^#zfur_es_ES.UTF-8 UTF-8/s/^#//' /etc/locale.gen ;
      locale-gen ;
      localectl set-locale LANG=es_ES.utf8 LANGUAGE=es_ES LC_NUMERIC=zfur_es_ES.utf8 LC_MONETARY=zfur_es_ES.utf8 ;;
    zfur_en_US)
      sed -i '/^#zfur_en_US.UTF-8 UTF-8/s/^#//' /etc/locale.gen ;
      locale-gen ;
      localectl set-locale LANG=es_ES.utf8 LANGUAGE=en_US LC_NUMERIC=zfur_es_ES.utf8 LC_MONETARY=zfur_es_ES.utf8 ;;
    es_EC)
      sed -i '/^#es_EC.UTF-8 UTF-8/s/^#//' /etc/locale.gen ;
      sed -i '/^#es_EC ISO-8859-1/s/^#//' /etc/locale.gen ;
      locale-gen ;
      localectl set-locale LANG=es_EC.utf8 LANGUAGE=es_EC ;;
#    255)
#      echo "Cancelado por la tecla Esc." ;;
  esac

  keyb_sel=$(dialog --backtitle "$backtitle_var" \
                    --title     "Selección de idioma del teclado" --clear --trim \
                    --menu      "Ahora deberá seleccionar cuáles de los siguientes mapeados de teclado desea
                                configurar para su sistema." 0 0 0 \
              "es"      "español" \
              "en"      "inglés" \
              "zfur_es" "español modalidad zFur" 3>&1 1>&2 2>&3);
#  keyb_sel=$? ;
  case $keyb_sel in
    es)
      localectl set-keymap es ;
      localectl set-x11-keymap es ;;
    en)
      localectl set-keymap en ;
      localectl set-x11-keymap en ;;
    zfur_es)
      localectl set-keymap zfur_es ;
      localectl set-x11-keymap zfur_es ;;
#    255)
#      echo "Cancelado por la tecla Esc." ;;
  esac

  dialog  --backtitle "$backtitle_var" \
          --title     "Configuración del idioma y teclado" --clear --trim \
          --yesno     "Los valores que ha configurado para su sistema son:\n
                          * idioma: $(localectl status | grep "LANGUAGE=" | sed -e "s/^[ ]*LANGUAGE=*//")\n
                          * teclado: $(localectl status | awk '$2~/Keymap/' | awk '{print $3}').\n
                      Es decir,\n\n
                      $(localectl status)\n\n
                      ¿Son éstos los que desea?" 0 0 ;
  repeat_q=$? ;
  
  if [ "$repeat_q" == "1" ] ; then
      dialog  --backtitle "$backtitle_var" \
              --title     "Configuración del idioma y teclado" --clear --trim \
              --msgbox    "Se le volverá a pedir que seleccione el idioma del sistema y el teclado." 0 0 ;
  fi

done

if [[ ! -f /etc/skel/.config ]] ; then
    mkdir /etc/skel/.config
fi
cp /etc/locale.conf /etc/skel/.config/locale.conf


# Software básico ----------------------------------------------------------------------------------------------
backtitle_var="Software básico" ;
dialog  --backtitle "$backtitle_var" \
        --title     "Selección de software básico" --clear --trim \
        --msgbox    "Ahora se le pedirá que seleccione los paquetes básicos que desea instalar." 0 0 ;

packets_bas=$(dialog --backtitle "$backtitle_var" \
                    --title     "Selección de software básico" --clear --trim \
                    --checklist "Marque los paquetes que desea instalar en su sistema." 0 0 0 \
              "python"                "Intérprete y librerías de Python"                on  \
              "vim"                   "VIM: Visual Editor Improved"                     on  \
              "vim-spell-en"          "Corrección ortográfica del inglés para VIM"      on  \
              "vim-spell-es"          "Corrección ortográfica del español para VIM"     on  \
              "vim-colorsamplerpack"  "Esquemas de colores para VIM"                    on  \
              "bash-completion"       "Autocompletado en BASH"                          on  \
              "sudo"                  "Para que algunos usuarios puedan introducir \
                                      comandos con privilegios"                         on  3>&1 1>&2 2>&3);
packets_bas_arr=( ${packets_bas} ) ;
num_packets_bas=${#packets_bas_arr[@]} ;
num_packets_bas0=$(($num_packets_bas - 1)) ;
packets_diff=0; # No hay diferencia entre los paquetes que seleccionó y los que se instalarán.
packets_none=1; # No hay paquetes para instalar.
packets_bas_v_arr=() ;
for i in $(seq 0 ${num_packets_bas0}) ; do
  if [[ -z "$(pacman -Qs ${packets_bas_arr[$i]})" ]] ; then
      packets_bas_v_arr[i]=${packets_bas_arr[$i]} ;
      packets_none=0;
    else
      packets_bas_v_arr[i]=" " ;
      packets_diff=1;
  fi
done
packets_bas_v="${packets_bas_v_arr[@]}" ;
#packets_bas_v_arr=(${packets_bas_v}) ;
#num_packets_bas_v=${#packets_bas_v_arr[@]} ;
#num_packets_bas_v0=$(($num_packets_bas_v - 1)) ;
if [ ${packets_diff} -eq 0 ] ; then
    dialog  --backtitle "$backtitle_var" \
            --title     "Selección de software básico" --clear --trim \
            --msgbox    "Se instalarán los paquetes que ha seleccionado." 0 0 ;
    pacman -S $packets_bas_v ;
  elif [ ${packets_none} -eq 0 ] ; then
    dialog  --backtitle "$backtitle_var" \
            --title     "Selección de software básico" --clear --trim \
            --msgbox    "De entre los paquetes que ha seleccionado, sólo se instalarán: ${packets_bas_v// /, }, \
                        puesto que el resto ya se encuentran instalados en su sistema." 0 0 ;
    pacman -S $packets_bas_v ;
  else
    dialog  --backtitle "$backtitle_var" \
            --title     "Selección de software básico" --clear --trim \
            --msgbox    "No se instalará ninguno de los paquetes que ha seleccionado por encontrarse éstos ya \
                        instalados en su sistema." 0 0 ;
fi


# Actualización ------------------------------------------------------------------------------------------------
backtitle_var="Actualización del sistema" ;
dialog  --backtitle "$backtitle_var" \
        --title     "Actualización del sistema" --clear --trim \
        --msgbox    "Ahora se va a actualizar su sistema a la última versión disponible." 0 0 ;
pacman -Syu ; # Ver si puedo ver el error estándar y en función del valor de éste repetir la descarga



# Operando -----------------------------------------------------------------------------------------------------
dialog --msgbox "Ahora se añadirán las configuraciones personalizadas de zFur de BASH y Vim para todo el \
                sistema." 0 0 ;
cat bashrc-add >> /etc/bash.bashrc ;
cat vimrc-add >> /etc/vimrc ;

dialog --msgbox "Ahora se cambiará la tabla de particiones (/etc/fstab)." 0 0 ;
mv fstab /etc/fstab ;
uuid1=$(lsblk -no uuid /dev/mmcblk0p1) ;
echo "  UUID=${uuid1}                              /boot   vfat    defaults  0       0" >> /etc/fstab ;
uuid2=$(lsblk -no uuid /dev/mmcblk0p2) ;
echo "  UUID=${uuid2}   /       ext4    defaults  0       0" >> /etc/fstab ;
uuid3=$(lsblk -no uuid /dev/mmcblk0p3) ;
echo "  UUID=${uuid3}   /home   ext4    defaults  0       2" >> /etc/fstab ;
# ¿Dónde desea que se monte la unidad /dev/mmcblk0p3?

# Nombres de host ----------------------------------------------------------------------------------------------
backtitle_var="Configuración de nombres de host" ;
dialog  --backtitle   "$backtitle_var" \
        --title       "Configuración de nombres de host" --clear --trim \
        --msgbox      "Ahora se cambiarán los nombres de host de su sistema." 0 0 ;

response="1";
until [ "$response" == "0" ] ; do
  dialog  --separate-widget $"\n" --ok-label "Submit" \
          --backtitle "$backtitle_var" \
          --title     "Configuración de nombres de host" --clear --trim \
          --form      "Introduzca los nombres de host que desea para su sistema." 0 0 0 \
            "Nombre static:"    1 5 ""  1 24  13  18  \
            "Nombre transient:" 2 5 ""  2 24  13  18  \
            "Nombre pretty:"    3 5 ""  3 24  18  38  2> host-names ;

  static_hn=$(sed -n "1p" < host-names) ;
  transient_hn=$(sed -n "2p" < host-names) ;
  pretty_hn=$(sed -n "3p" < host-names) ;
  chck_rgx hostname static_hn estático ;
  hostnamectl --static set-hostname "${static_hn}" ;
  chck_rgx hostname transient_hn transient ;
  hostnamectl --transient set-hostname "${transient_hn}" ;
  hostnamectl --pretty set-hostname "${pretty_hn}" ;

  dialog  --backtitle   "$backtitle_var" \
          --title "Configuración de nombres de host" --clear --trim \
          --yesno "Los nombres de host que tiene ahora configurados son:\n
                      -static: $(hostnamectl --static)\n
                      -transient: $(hostnamectl --transient)\n
                      -pretty: $(hostnamectl --pretty)\n
                  ¿Son éstos los nombres que deseaba para su host?" 0 0 ;
  response=$? ;
  if [ "$response" == "1" ] ; then
      dialog  --backtitle   "$backtitle_var" \
              --title       "Configuración de nombres de host" --clear --trim \
              --msgbox      "Se le pedirá de nuevo que introduzca los nombres de host que desea para su \
                            sistema." 0 0 ;
  fi
done

# Creación de usuarios -----------------------------------------------------------------------------------------
backtitle_var="Creación de usuario(s)" ;
dialog  --backtitle   "$backtitle_var" --yes-label "Crear" --no-label "No crear" \
        --title       "Creación de usuario(s)" --clear --trim \
        --yesno       "Ahora, si lo desea, puede crear una nueva cuenta de usuario en su sistema. ¿Desea
                      crear una cuenta de usuario en su sistema?" 0 0 ;
response=$? ;

while [ "$response" == "0" ] ; do

  user_name=$(dialog  --backtitle "$backtitle_var" \
                      --title     "Introducción del nombre de usuario" --clear --trim \
                      --inputbox  "¿Cuál desea que sea el nombre de este usuario?" 0 0 3>&1 1>&2 2>&3) ;
  chck_rgx username user_name usuario ;
  chck_user_name=$(grep -c "^${user_name}" /etc/passwd) ;
  while [ "$chck_user_name" = "1" ] ; do
    user_name=$(dialog  --backtitle "$backtitle_var" \
                        --title     "Introducción del nombre de usuario" --clear --trim \
                        --inputbox  "Lo siento, pero el usuario que desea crear ya existe en el sistema.
                                    Tendrá que escoger otro. ¿Cuál desea que sea el nombre de este
                                    usuario?" 0 0 3>&1 1>&2 2>&3) ;
    chck_rgx username user_name usuario ;
    chck_user_name=$(grep -c "^${user_name}" /etc/passwd) ;
  done

  pwrd_arr=( $(dialog --backtitle     "$backtitle_var" \
                      --title         "" --clear --trim \
                      --passwordform  "Introduzca a continuación una contraseña para el usuario
                                      ${user_name}." 0 0 0 \
                "Introduzca la contraseña:"           1 1 ""  1 36  11  43  \
                "Vuelva a introducir la contraseña:"  2 1 ""  2 36  11  43  3>&1 1>&2 2>&3) ) ;

  while [[ "${pwrd_arr[0]}" != *"${pwrd_arr[1]}"* ]] || [[ ${#pwrd_arr[0]} -le 5 ]] ; do
    if [[ "${pwrd_arr[0]}" != *"${pwrd_arr[1]}"* ]] && [[ ${#pwrd_arr[0]} -le 5 ]] ; then
        pass_f="    * Las cadenas que ha introducido no coinciden.\n    * La contraseña introducida no tiene un mínimo de 6 caracteres.\n"
      elif [[ "${pwrd_arr[0]}" != *"${pwrd_arr[1]}"* ]] ; then
        pass_f="    * Las cadenas que ha introducido no coinciden.\n"
      else
        pass_f="    * La contraseña introducida no tiene un mínimo de 6 caracteres.\n"
    fi
    pwrd_arr=( $(dialog --backtitle     "$backtitle_var" \
                        --title         "" --clear --trim \
                        --passwordform  "Error en la introducción de la contraseña debido a:\n${pass_f}Vuelva a introducir la contraseña desea para el usuario ${user_name}." 0 0 0 \
                  "Introduzca la contraseña:"           1 1 ""  1 36  11  43  \
                  "Vuelva a introducir la contraseña:"  2 1 ""  2 36  11  43  3>&1 1>&2 2>&3) );
  done
  pwrd=${pwrd_arr[0]}
  # Para hacer un hash SHA-512, que es como se guardan las contraseñas de usuarios en /etc/shadow
  python -c "import crypt, getpass, pwd; \
               print(crypt.crypt('${pwrd}', '\$6\$saltsalt\$'))" > temp-pwrd ;
  pwrd=$(cat temp-pwrd) ;
  rm temp-pwrd ;
  pwrd=${pwrd//#/\\#}
  pwrd=${pwrd//@/\\@}
  pwrd=${pwrd//!/\\!}
  pwrd=${pwrd//$/\\$}
  pwrd=${pwrd//%/\\%}
  pwrd=${pwrd//&/\\&}
  pwrd=${pwrd//\//\\\/}
  pwrd=${pwrd//\*/\\\*}

  l_group=$(dialog  --backtitle "$backtitle_var" \
                    --title     "Introducción del grupo de login de ${user_name}" --clear --trim \
                    --inputbox  "¿Cuál desea que sea el grupo de login de este usuario? (Es aconsejable que
                                sea users)" 0 0 3>&1 1>&2 2>&3) ;
  chck_rgx username l_group l_group ;
  chck_l_group=$(grep -c "^${l_group}:" /etc/group) ;
  while [ "$chck_l_group" = "0" ] ; do
    dialog --backtitle   "$backtitle_var" \
          --title       "${l_group} no es un grupo del sistema" --clear --trim \
          --yesno       "${l_group} no es un grupo del sistema. ¿Desea crearlo?" 0 0 ;
    response=$? ;
    case $response in
      0)
        groupadd $l_group ;
        chck_l_group=$(grep -c "^${l_group}:" /etc/group) ;;
      1)
        l_group=$(dialog  --backtitle "$backtitle_var" \
                          --title     "Introduzca otro grupo" --clear --trim \
                          --inputbox  "Introduzca entonces otro grupo." 0 0 3>&1 1>&2 2>&3) ;
        chck_rgx username l_group l_group ;
        chck_l_group=$(grep -c "^${l_group}:" /etc/group) ;;
      255)
        echo "Ha presionado la tecla Esc." ;;
    esac
  done

  # Hacer gauge
  printf "····Creando el usuario ${user_name}····\n"
  useradd -m -g $l_group -k /etc/skel/ -s /bin/bash $user_name ;
  sed -i "/^${user_name}:/s/:\!:/:${pwrd}:/" /etc/shadow ;
#  printf "\nEl hash de la contraseña es ${pwrd}\n" ;
#  printf "Y el la entrada de ${user_name} del fichero /etc/shadow es\n" ;
#  grep -e "^${user_name}:" /etc/shadow ;
#  read -n1 -rsp $'Presione...............................................' ;

  dialog  --backtitle   "$backtitle_var" \
          --title       "" --clear \
          --yesno       "¿Desea que este usuario pertenezca también a otros grupos?" 0 0 ;
  response=$? ;
  while [ "$response" == "0" ] ; do
    group_other=$(dialog  --backtitle "$backtitle_var" \
                          --title     "Introduzca el nombre del grupo" --clear --trim \
                          --inputbox  "Escriba el nombre del grupo al que desea añadir al usuario
                                      ${user_name}." 0 0 3>&1 1>&2 2>&3) ;
    chck_rgx username group_other group_other ;
    chck_group=`grep -c "^${group_other}:" /etc/group` ;
    while [ "$chck_group" == "0" ] ; do
      dialog  --backtitle   "$backtitle_var" \
              --title       "" --clear --trim \
              --yesno       "${group_other} no es un grupo del sistema. ¿Desea crearlo?" 0 0 ;
      response=$? ;
      case $response in
        0)
          groupadd $group_other ;;
        1)
          group_other=$(dialog  --backtitle "$backtitle_var" \
                                --title     "Introduzca otro grupo" --clear --trim \
                                --inputbox  "Introduzca entonces el nombre de otro grupo." 0 0 3>&1 1>&2 2>&3);
          chck_rgx username group_other group_other ;;
        255)
          echo "Ha pulsado Esc." ;;
      esac
      chck_group=`grep -c "^${group_other}:" /etc/group` ;
    done
    usermod -a -G $group_other $user_name ;
    dialog  --backtitle   "$backtitle_var" \
            --title       "" --clear --trim \
            --yesno       "Se ha añadido al usuario $user_name al grupo ${group_other}. ¿Desea que este
                          usuario pertenezca a algún otro grupo?" 0 0 ;
    response=$? ;
  done
  
  dialog  --backtitle   "$backtitle_var" \
          --title       "" --clear --trim \
          --yesno       "¿Desea crear ahora alguna otra cuenta de usuario en su sistema?" 0 0 ;
  response=$? ;
#  line=$(grep -e "^${user_name}")
#  sed -e "s/^${user_name}:!:/^${user_name}:${pwrd}:/g" /etc/shadow

done


sed -i '/%wheel ALL=(ALL) ALL/s/^#//g' /etc/sudoers ;
if [[ -n $(grep -e "^%power ALL=(ALL) NOPASSWD: " /etc/sudoers) ]] ; then
    sed -i '/%power ALL=(ALL) NOPASSWD: /d'  /etc/sudoers
fi
echo "%power ALL=(ALL) NOPASSWD: /usr/bin/systemctl poweroff,/usr/bin/systemctl reboot,/usr/bin/systemctl halt" >> /etc/sudoers ;

# Reinicio -----------------------------------------------------------------------------------------------------
backtitle_var="Reinicio" ;
dialog  --backtitle "$backtitle_var" \
        --title     "" --clear --trim \
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
