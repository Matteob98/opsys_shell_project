####
#### Problemi noti:
####

errore()
{
    echo "Uso: $0 [opzioni] stringa file1...filen" >&2
    exit 10
}

r_selected=0
e_selected=0
argomento=""
while getopts ":e:r" opt;
do
    case $opt in
	e) argomento=${OPTARG}

	   ##
	   ## Se e è seguito da un altra opzione da errore
	   ##
	   if [[ $argomento =~ ^-  ]]
	   then
      	       errore
	   fi
	   e_selected=1;;
	
	r) r_selected=1;;
	
	\?) errore;;
	
	:) errore;;
    esac
done

shift $(($OPTIND-1))

##
## Selezionato r senza e
##
if [[ $r_selected -eq 1 && $e_selected -eq 0 ]]
then
    errore
fi

##
## Meno di due argomenti
##
if [[ $# -lt 2 ]]
then
    errore
fi


##
## Prendo la stringa s
##
stringa=$1
shift

##
## Lista dei file che superano i controlli
##
declare -a lista_file
index_file=0

##
## Lista delle stringhe che vanno nel file descriptor 3
##
declare -a fileDescr3
ind3=0

##
## Lista delle stringhe che vanno nel file descriptor 4
##
declare -a fileDescr4
ind4=0

##
## Lista delle stringhe che vanno nel file descriptor 5
##
declare -a fileDescr5
ind5=0

##
## Mi salvo tutti i file e cartelle scartati, sarà l'exit status
##
scartati=0

##
## Mi salvo tutti i file a cui fanno riferimento i soft link
##
declare -a softLink
indSoft=0

##
## Salvo tutti i file trovati nel tree
##
declare -a dirFile
indDir=0

##
## Ciclo per ogni fi
##
while (( "$#" ))
do
    elm=$1
    
    ##
    ## Se fi non esiste lo ignoro
    ##
    if [ ! -e $elm ]
    then
		fileDescr3[$ind3]="L'argomento $elm non esiste"
		ind3=$( expr $ind3 + 1 )
	
		scartati=$( expr $scartati + 1 )
		shift
		continue
    fi
    
    ##
    ## Se è un soft link e un file regolare
    ##
    if [[ -f $elm && -L $elm ]]
    then
    
    	linkedFile=$( readlink -f $elm)
		softLink[$indSoft]=$linkedFile
		indSoft=$( expr $indSoft + 1)
    	
    	dirFile[$indDir]=$elm
		indDir=$( expr $indDir + 1 )
		shift
		continue
    fi

    ##
    ## Se fi è un file e non è un soft Link 
    ## lo aggiungo a lista_file
    ##
    if [[ -f $elm ]]
    then	
		dirFile[$indDir]=$elm
		indDir=$( expr $indDir + 1 )
		shift
		continue
    fi

    ##
    ## se -r non è stata data e fi è una directory la ignoro
    ##
    if [[ $r_selected -eq 0 && -d $elm ]]
    then
	fileDescr4[$ind4]="L'argomento $elm e' una directory"
	ind4=$( expr $ind4 + 1 )

	scartati=$( expr $scartati + 1 )
	shift
	continue
    fi

    ##
    ## se -r  è stata data e fi è una directory, se ho i permessi, cerco nell'albero della directory
    ##
    
    if [[ $r_selected -eq 1 && -d $elm ]]
    then
		###
		### Prendo i permessi
		### ES. 7567
		## sgid = 7567 / 1000 = 7
		## proprietario = (7567 - 7000) / 100 = 5
		###
	
		permessi=$(stat -c %a $elm)
		sgid=$(( $permessi/1000 ))
		proprietario=$(( (( $permessi - (( $sgid * 1000 )) )) /100 ))
	
		if [[ $proprietario -ne 7 ]]
		then
	    	fileDescr5[$ind5]="I permessi $permessi dell'argomento $elm non sono quelli richiesti"
	    	ind5=$( expr $ind5 + 1 )
	
	    	scartati=$( expr $scartati + 1 )
	    	shift
	    	continue
		fi

		for figlio in $(tree -i -f -F -a --noreport $elm | grep -v /$)
		do
	    	nome_file=${figlio##*/}
	
	    	if [[ "$(echo $nome_file | grep -E $argomento)" != "" ]]
	    	then
				
				if [ -L $figlio ]
				then
					continue
				fi
					
		   	 	if [ -f $figlio  ]
		   	 	then
		   	 		
		   	 		dirFile[$indDir]=$figlio
		    		indDir=$( expr $indDir + 1 )	
				fi
	    	fi
		done

		##
		## Qui finisce il ciclo sul tree della directory
		##
    fi
    
    shift
done

##
## Qui finisce il ciclo sugli elementi passati in input
##
##

declare -a std_out
out_ind=0
##
## Per tutti i file che hanno superato i controlli
##
for file in "${dirFile[@]}"
do
	##
	## Se non esiste
	##
	if [ ! -e $file ]
	then
		continue
	fi
	
	##
	## Se non è un file a cui fa riferimento un soft link
	##	
    nome_file=${file##*/}
    if [[ "$(echo "${softLink[@]}" | grep ${file##*/})" != "" ]]
    then
		continue
    fi
        
    inode=$( ls -i $file )
    inode=($inode[0])
    list_hard_link=($( find ./ -inum $inode |  tr "\n" " " ))

    flagL=0
    if [ ${#list_hard_link[@]} -ge 2 ]
    then
		nameFile=${file##*/}
		lenFile=${#nameFile}
	
		for linkedFile in "${list_hard_link[@]}"
		do
	    	nameLinkedFile=${linkedFile##*/}
	    	lenLinked=${#nameLinkedFile}
	
	    	if [[ $lenLinked -lt $lenFile && "$(echo "${dirFile[@]}" | grep -E $linkedFile)" != "" ]]
	    	then
			flagL=1
	    	fi
		done
    fi

    if [[ $flagL -ne 1 ]]
    then
		lista_file[$index_file]=$file
		index_file=$( expr $index_file + 1 )
    fi        
done

##
## Cerco i match di contenuto
##
for file in "${lista_file[@]}"
do
    dimB=$( cat $file | wc -c )
    mod=$( expr $dimB % 4 )
    exa=$( cat $file | od -tx1 | cut -b9- | tr "\n" " " | sed "s/ //g" ) 
    for (( i=0 ; i<$mod; i++ ))
    do
	exa=$exa"00"
    done
    
    ##
    ## od -tx prende il valore esadecimale di $file
    ## grep -b restituisce la stringa offset:match
    ## grep -Eo prende solo l'offset
    ## tronca i due punti alla fine dell'offset
    ##
    ## 
    
    offset=($( echo $exa | sed "s/ //g"  | grep -Ebo $stringa | grep -Eo '[0-9]+:' | tr ":\n" "\n" )) # | sed " ")
    for off in "${offset[@]}"
    do
	std_out[$out_ind]="$file:$off"
	out_ind=$( expr $out_ind + 1 )
    done	      
done

##
## Salvo su FileDescr3 tutti i fi che non esistono
##

for file in "${fileDescr3[@]}"
do
    echo $file
done | sort -r | uniq >&3

##
## Salvo su FileDescr4 tutte le directory se non ho selezionato -r
##
for file in "${fileDescr4[@]}"
do
    echo $file
done | sort -r | uniq >&4

##
## Salvo su FileDescr5 tutte le directory di cui non ho i permessi
##
for file in "${fileDescr5[@]}"
do
    echo $file
done | sort -r | uniq >&5


##
## Salvo su Std_out (File descr 1) tutti i match
##
for riga in "${std_out[@]}"
do
    echo $riga
done | sort -r | uniq >&1

##
## Scrivo il numero di scartati in ottale su StdErr e lo ritorno in exit
##
scartati=($( printf "%o" $scartati ))
echo $scartati >&2
exit $scartati 
