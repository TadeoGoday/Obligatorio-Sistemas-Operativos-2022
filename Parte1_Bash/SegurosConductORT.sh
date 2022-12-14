#!/bin/bash

#Colores
greenColour="\e[0;32m\033[1m"
endColour="\033[0m\e[0m"
redColour="\e[0;31m\033[1m"
blueColour="\e[0;34m\033[1m"
yellowColour="\e[0;33m\033[1m"
purpleColour="\e[0;35m\033[1m"
turquoiseColour="\e[0;36m\033[1m"
grayColour="\e[0;37m\033[1m"

mkdir logs 2>/dev/null #Crea carpeta para almacenar registros
log_file=logs/registro_$(date +%F_%T).log #Variable para referenciar al archivo log

#//////////////////////////////// FUNCIONES AUXILIARES ////////////////////////////////

Pedir_Cedula(){
	while [ true ]; do
		read -p "Ingrese la cédula del responsable: " cedula
		#Verificar cedula
		if [ $(echo $cedula | grep -E "\b[0-9]{1}\.[0-9]{3}\.[0-9]{3}-[0-9]{1}\b" -c) -eq 1 ]; then break; fi
		echo -e "Cédula Invalida\n" > /dev/stderr
	done
	echo $cedula
}

Pedir_Fecha(){
	while [ true ]; do
		read -p "Ingrese la fecha de vencimiento del seguro (YYYY-MM-DD): " fecha
		#Verificar fecha
		if [ $(echo $fecha | grep -E "\b[0-9]{4}-([1-9]|0[1-9]|1[012])-([1-9]|[012][0-9]|3[01])\b" -c) -eq 1 ]; then break; fi
		echo -e "Fecha Invalida\n" > /dev/stderr
	done
	echo $fecha
}

Pedir_Matricula(){
	while [ true ]; do
		read -p "Ingrese la matricula: " matricula
		matricula=$(echo $matricula | tr '[:lower:]' '[:upper:]')
		#Verificar matricula
		if [ $(echo $matricula | grep -E "\bS[A-Z]{2}-[0-9]{4}\b" -c) -eq 1 ]; then break; fi
		echo -e "Matricula Invalida\n" > /dev/stderr
	done
	echo $matricula
}

Modificar_Permiso(){
	echo "Ingresar password admin"
	$(sudo chmod $1 matriculas.txt)
	case $1 in
		'444') 	echo "Modificaciones bloqueadas"
				msg="Solo Lectura"
			;;
		'666') 	echo "Modificaciones habilitadas"
				msg="Lectura y Escritura"
			;;
	esac
	#Registrar en el log
	echo -e "Operacion $(date +%T)\nCambiar Permiso de Modificacion\nSe cambió permiso de modificación a $msg\n" >> $log_file
}
	
#//////////////////////////////// FIN DE FUNCIONES AUXILIARES ////////////////////////////////

#Funcion para: Cambiar Permiso de Modificacion
Cambiar_Permiso_de_Modificacion(){
	while [ true ];do
		echo -e "\n${blueColour}[+]${endColour} Cambiar Permiso de Modificacion"
		echo -e "\t1) Bloquear modificaciones"; 
		echo -e "\t2) Permitir modificaciones";
		echo -e "\t3) Volver al menu\n"
		read -p 'Seleccione una opción: ' opcion

		case $opcion in 
			'1') Modificar_Permiso 444
				break
				;;
			'2') Modificar_Permiso 666
				break
				;;
			'3') break
				;;
			*) 	echo -e "No es una opcion valida\n"
				echo; read -sp "Presione [ENTER] para continuar"
				clear
				;;
		esac		
	done
}

#Funcion para: Registrar Matriculas
Registrar_Matricula(){
	echo -e "\n${blueColour}[+]${endColour} Registrar Matricula"

	matricula=$(Pedir_Matricula)
	cedula=$(Pedir_Cedula)
	fecha=$(Pedir_Fecha)

	echo -e "$matricula | $cedula | $fecha\n"
	

	#Guarda matricula en el archivo matriculas.txt
	if [[ $(ls -l matriculas.txt | cut -b -3) == "-rw" ]]; then
		echo -e "Operacion exitosa!"

		echo "$matricula | $cedula | $fecha" >> matriculas.txt

		#Registrar en el log - Operacion exitosa
		echo -e "Operacion $(date +%T)\nRegistrar Matricula\n[ $matricula | $cedula | $fecha ]\n" >> $log_file
	
	else
		echo -e "La matricula no se registro por falta de permisos"
		
		#Registrar en el log - Operacion fallida
		echo -e "Operacion $(date +%T)\nRegistrar Matricula\nNo se guardo en el archivo matriculas.txt\n[ $matricula | $cedula | $fecha ]\n" >> $log_file
	fi

	
}

#Funcion para: Ver Matriculas Registradas
Ver_Matriculas_Registradas(){
	echo -e "\n${blueColour}[+]${endColour} Ver Matriculas Registradas"
	echo -e "\t${yellowColour}+------------+-------------+----------+${endColour}"
	echo -e "\t${yellowColour}| Matriculas |   Cedulas   |  Estado  |${endColour}"
	echo -e "\t${yellowColour}+------------+-------------+----------+${endColour}"

	fecha_actual=$(date +%F)
	
	while IFS= read -r line; do
		fecha_matricula=$(echo "$line" | cut -d "|" -f3 | tr -d " ")
		
		#Verificar estado de la matricula (vencida o en orden)
		estado="${greenColour}En orden${endColour}"
		if [ $(date -d $fecha_matricula +%s) -lt $(date -d $fecha_actual +%s) ]; then
			estado="${redColour}Vencido ${endColour}"
		fi

		#Imprimir matriculas
        	echo -e "\t|  $(echo "$line" | cut -d "|" -f1) |$(echo "$line" | cut -d "|" -f2)| $estado |"
		echo -e "\t+------------+-------------+----------+"
	done < matriculas.txt

	#Registrar en el log
	echo -e "Operacion $(date +%T)\nVer Matriculas Registradas\n" >> $log_file
}

#Funcion para: Buscar Matriculas por Usuario
Buscar_Matriculas_por_Usuario(){
	echo -e "\n${blueColour}[+]${endColour} Buscar Matriculas por Usuario"
	cedula=$(Pedir_Cedula)

	#Imprimir matriculas del usuario
	echo -e "\t${yellowColour}+-------------+${endColour}"
	echo -e "\t${yellowColour}| Matricula/s |${endColour}"
	echo -e "\t${yellowColour}+-------------+${endColour}"
	echo "$(cat matriculas.txt | grep $cedula | cut -d "|" -f1 | tr -d '|')" > logs/.auxFile
	while IFS= read -r line; do 
		echo -e "\t|  $line  |" 
	done < logs/.auxFile
	rm logs/.auxFile
	echo -e "\t+-------------+"
	echo "Hay $(cat matriculas.txt | grep $cedula -c) matricula/s asignadas al usuario"
	#Registrar en el log
        echo -e "Operacion $(date +%T)\nBuscar Matriculas del Usuario: $cedula\n" >> $log_file
}



while [ true ]; do
	clear
	figlet --gay -t -k "Seguros ConductORT" 2>/dev/null #2>/dev/null -> si no tiene figlet instalado no reporta errores
	echo -e "\nSeguros ConductORT\n"

	echo "1) Registrar Matricula"
	echo "2) Ver Matriculas Registradas"
	echo "3) Buscar Matriculas por Usuario"
	echo "4) Cambiar Permiso de Modificacion"
	echo -e "5) Salir\n"

	read -p 'Seleccione una opción: ' x
	case $x in
		'1')	Registrar_Matricula
			;;
		'2')	Ver_Matriculas_Registradas
			;;
		'3') 	Buscar_Matriculas_por_Usuario
			;;
		'4')	Cambiar_Permiso_de_Modificacion
			;;
		'5')	echo -e "Saliendo...\n"
			break
			;;
		*)	echo -e "No es una opcion valida\n"
			;;
	esac
	echo; read -sp "Presione [ENTER] para continuar"
done
