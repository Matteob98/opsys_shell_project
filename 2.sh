#Secondo esercizio primo homework
#Matteo Battisti
#Matricola:1848458


errore()
{
    echo "Uso: $0 sampling commands files" >&2
}
arguments=($( echo $@ | tr " " "\n" ))

declare -a command_list
declare -a f_list
declare -a g_list
flag=0 command_count=0 end_of_command=0 f_count=0 g_count=0
#flag -> 0 se intervallo di campionamento, 1  altrimenti
for elm in "${arguments[@]}"
do
    #Se è il primo argomento, quindi l'intervallo di campionamento
    if [ $flag -eq 0 ]
    then	
        if [[ ! $elm =~ ^[0-9]+$ ]]
		then
	    	errore
		fi	    
		c=$elm
		flag=1

    else	    
	    #se non sono finiti i comandi C
	    if [ $end_of_command -eq 0 ]		
	    then
			flag=2
			command_list[$command_count]+=" $elm"
			##
			## Controllo se è l'ultimo comando
			##
			
			if [[ $elm =~ ,,,$ ]]
			then		

		    	#Elimina ,,, dalla fine della parola (se la parola è ,,, elimina tutto e quindi non aggiunge niente
		    	command_list[$command_count]=${command_list[$command_count]::-3}
		    	##	
		    	## fine di tutti i comandi
		    	##
		    	end_of_command=1
		    	
		    	command_count=$( expr $command_count + 1 )
		    	##
		    	## Variabile di appoggio per il conteggio dei file fi gi
		    	##
		    	dim_cmd=$command_count
			else
		
			##
			## Se è la fine di questo comando
			##
			
		    if [[ $elm =~ ,,$ ]]
		    then
		    
		    	#Elimina ,, dalla fine della parola
				command_list[$command_count]=${command_list[$command_count]::-2}
				
				##
				## fine di questo comando
				## Devo salvarmi il numero di comandi -> $ind
				##
				
				command_count=$( expr $command_count + 1 )
		    fi
		fi
	    else
	    	## 
	    	## se sono finiti i comandi
			## Per n numero di comandi, cerco n fi
			##
			if [ $dim_cmd -gt 0 ]    
			then
		    	##
		    	## Entrato qui imposto flag=2
		    	## Dopo viene controllato flag, se non è 2 vuol dire che mancano argomenti
		    	## Quindi lancia errore
		    	##
			    	
		    	#aggiungo l'elemento alla lista degli fi
		    	f_list[$f_count]=$elm
		    	f_count=$( expr $f_count + 1 )
		    	
		    	#diminusco di 1 il numero di comandi
		    	dim_cmd=$( expr $dim_cmd - 1 )
		    			    
			else #Inizio a salvare i g1		    
	       	    	#aggiungo l'elemento alla lista dei gi
		    	g_list[$g_count]=$elm
		    	g_count=$( expr $g_count + 1 )		
		    	
			fi
	    fi
	
    fi     
done

if [ $flag -lt 2 ]
then
    errore
    exit 15
fi

#se la dimensione della lista di fi è diversa dalla dimensione dei gi
if [ $f_count -ne $g_count ]
then
     errore
     exit 30
fi   
if [ $f_count -ne $command_count ]
then
     errore
     exit 30
fi   

PID_String=""
i=0
for elm in "${command_list[@]}"
do
	##
    ##lancio comando elm"
	##
	
    #Se $elm è un comando che esiste
    if [ "$(command -v $elm)" != "" ]
    then
    	##
		## Lancio il comando $elm
		## Redirigo lo standard output sul file fi
		## Redirigo lo standard error sul file g1
		## Eseguo in background con &
		##
		$elm 1>${f_list[$i]} 2>${g_list[$i]} &
		
		PID_elm="$!" #Ultimo PID in background

		PID_String+="$PID_elm"","
		if [[ $i -eq 0 ]]
		then
			firstPID=$PID_elm
    	fi
	fi
    i=$( expr $i + 1 )
done

##
## Controllo se la foresta non esiste (tutti i processi sono terminati
##
if [[ $PID_String != "" ]]
then
	PID_String=${PID_String::-1}

	#
	# Controllo se i comandi C producono processi figli
	#
	figli=($(ps -o pid,ppid --pid $PID_String | tail -n +2))
	if [[ "${#figli[@]}" -eq 0 ]]
	then
		echo "Tutti i processi sono terminati" >&1
		exit 1
	fi
fi


##
## Scrivo su file descriptor 3, sulla stessa riga separati di _, i PID di tutti i comandi lanciati
##
echo "$PID_String" | tr "," "_" >&3

PID_String=$( echo $PID_String | tr "," " " )
##
## Inizio monitoraggio processi
##

##
## Finchè non trovo più figli (se done non esiste già)
##
while [[ ! -f done.txt ]] 
do
	sleep $c
done

##
## Fine monitoraggio processi
##
echo "File done.txt trovato" >&3

##
## Prendo tutti i processi in formato PID,PPID
## Elimino le righe di intestazione con tail
## Passo ad AWK la stringa dei padri, se in una riga di ps trovo un padre che si trova in padri, stampo la riga e aggiungo il figlio ai nuovi padri
## ordino e mando in output
##

ps -o pid,ppid | tail -n +2 | awk -v padri="$PID_String" ' { if ( match(padri,$2) )  { print $2" "$1 ; padri=padri" "$1; } } ' | sort -n >&1

exit 0





