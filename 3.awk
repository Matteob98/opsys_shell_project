#!/usr/bin/awk -f

##
## Matteo Battisti matricola: 1848458
##

##
## ------ Indice array ------
## 1) Nomi delle tabelle
## 		nomeTabella[nrTab]=nome
## 2) Valori m delle tabelle
## 		mList[nrTab]=m
## 3) nomi degli attributi
## 		nomiAttributiTabella[nrTab]= nome1 nome2 ... nomen
## 4) numero degli attributi di ogni tabella
## 		nrAttributiTabella[nrTab]=n
## 5) valori degli attributi
## 		attributi[nrTab_nomeAttr]= attr1 attr2 ... attrn
## 

BEGIN {

	nArg=ARGC-1 #ARGC conta anche il file awk, quindi devo togliere 1
	fileIndex=-1
	tabIndex=0
	indexUltimoCsv=1
	##
	## Se sono stati passati meno di 2 argomenti do errore
	##
	if ( nArg < 2 ) {
		print "Errore: dare almeno 2 file in input" | "cat 1>&2"
		exit 10
	}
	
}

##
## Se sta iniziando un nuovo file aumento l'indice
## FNR rappresenta l'indice di riga del file corrente
##
FNR==1 { 
	listaFile=listaFile" "FILENAME
	csvOutput=FILENAME
	fileIndex++
	##
	##Se è il file I
	##
	if ( fileIndex == 0 ) {
		FS="=" }
	##
	## se è un file CSV
	##
	else {
		
		if ( nrTab==0 ) {
			print "Errore: non e' stata precisata neanche una tabella per il join" | "cat 1>&2"
			exit 20
		}
	
		##Il separatore del file fileIndex-esimo è contenuto in separator
		FS=separator[fileIndex]
		##Imposto che devo cercare per primo il nome della tabella
		isNomeTabella=1
		isAttributi=0
	        tabIndex++
	} 
 }

##
## Se sono nel file I
## Se è il numero di pivot di una tabella
## num_pivot_nome=numero
##
fileIndex==0 && /^num_pivot_/ { 
	nome=substr($1,11)
	numPivot[nome]=$2 }
##
## Se sono nel file I
## Se è il separatore
## separator_1=|
##
fileIndex==0 && /^separator_[0-9]+/ {
	numero=substr($1,11)
	if ( numero<=nArg && numero>=0 )
		separator[numero]=$2 }
##
## Se sono nel file I
## Se è lo string pivot di una tabella
## string_pivot_nome=stringa
##
fileIndex==0 && /^string_pivot_/ { 
	nome=substr($1,14)
	stringPivot[nome]=$2 } #stringPivot[nome].add 
	
##
## Se sono nel file I
## Se è il nome di una tabella
## Tab_m_n=nome
##
fileIndex==0 && /^tab_[0-9]+_[1-2]+/ { 
	m=substr($1,5,1)
	n=substr($1,7)
	tab[m"_"n]=$2
		
	if ( m > mMaxTab ) { mMaxTab=m } ##Prendo m (numero tab)
	##Conto le tabelle
	nrTab++}

##
## Se è un file CSV
##
fileIndex > 0 {
	##
	## Se sto cercando il nome della tabella
	##
	if (isNomeTabella == 1 ) {
		##
		## Se la riga non è vuota (tra una tabella e l'altra)
		##
		if ( $1 != "") {
			
			##
			## Se sj non è specificato, assegnare ","
			##
		        if (separator[fileIndex] == "") {separator[fileIndex]="," }

			##
			## Prendo l'indice del primo separatore
			##
			spl=index($0,separator[fileIndex])
			spl--
			fileDiOrigine[tabIndex]=fileIndex
			##
			## Il nome della tabella si trova prima del separatore
			##
			nomeTabella[tabIndex]=substr($0,0,spl)
			mList[fileIndex]=length(substr($0,spl)) + 2 #+2 (1 per il FS prima del nome, uno per quello dopo il nome)


			isNomeTabella=0
			isAttributi=1
		}
	}
	##
	## Se sto cercando i nomi degli attributi
	##
	else if (isAttributi == 1 ) {
		c=0
		##
		## Per ogni stringa della riga aggiungo il nome dell'attributo alla tabella
		##
		for ( i=1 ; i<=NF ; i++ ) {
			if( $i != "" ) {
				nomiAttributiTabella[tabIndex]=nomiAttributiTabella[tabIndex]$i" "
				c++ }
		}
		nrAttributiTabella[tabIndex]=c
		
		isAttributi=0
	}
	##
	## Se sto cercando i valori degli attributi
	##
	else {
		spl=index($0,separator[fileIndex])
		m=mList[tabIndex]
		##
		## Se mi accorgo che è finita la tabella
		##
		if ( $1 == "" ) {
			isNomeTabella=1
			tabIndex++
		}
		##
		## Altrimenti aggiungo gli attributi negli array
		##
		else {
			split(nomiAttributiTabella[tabIndex], nomi, " " )
			for ( i=1; i<=nrAttributiTabella[tabIndex]; i++ ) {

			        nomeAttributo=nomi[i]
				attributi[tabIndex"_"nomeAttributo]=attributi[tabIndex"_"nomeAttributo]$i""separator[fileIndex]
			}
		}
				
	}

}
##
## Se sono nell'ultima tabella mi salvo tutte le righe
## Serviranno quando dovrò riscriverli per darli in output
##
fileIndex==(nArg-1) {

    ultimoCsv[indexUltimoCsv]=$0
    indexUltimoCsv++
}



##
##
##
END {
	##
	## Scrivo sia su stdOut che us StdErr la lista di file eseguiti
	##
	print "Eseguito con argomenti"listaFile | "cat 1>&1"
	print "Eseguito con argomenti"listaFile | "cat 1>&2"
	
	for (n_m in tab) {
		tabella=tab[n_m]
		##
		## Se per la stessa t ho sia num_pivot che string_pivot prendo solo num_pivot
		##
		if ( numPivot[tabella]!="" && stringPivot[tabella]!="" ) {
			stringPivot[tabella]="" }
		##
		## Se per la stessa t non è definito ne numPivot ne stringPivot, imposto numPivot=1
		##
		else if ( numPivot[tabella]=="" && stringPivot[tabella]=="" ) {
			numPivot[tabella]="1" }
	}

	for (i=1; i<=mMaxTab; i++) {
	
		##
		## Prendo tab_i_1
		## Prendo tab_i_2
		##
		t1=tab[i"_1"]
		t2=tab[i"_2"]		

		##
		## Implemento i controlli sulle tab
		##
		j=i-1
		
		#Per ogni i>1 esiste tab_i_1 ma non tab_(i-1)_1
		if ( i>1 && t1!="" && tab[j"_1"]=="") {
			print "Errore: non sono precisate le tabelle del join all'indice "j | "cat 1>&2"
			exit 30
		}
		#Per ogni i>1 esiste tab_i_2 ma non tab_(i-1)_2
		if ( i>1 && t2!="" && tab[j"_2"]=="") {
			print "Errore: non sono precisate le tabelle del join all'indice "j | "cat 1>&2"
			exit 30
		}
		
		#Non vengono specificati entrambi i tab_i_1 e tab_i_2
		if ( t1=="" || t2=="") {
			print "Errore: non sono precisate le tabelle del join all'indice "i | "cat 1>&2"
			exit 30
		}

		##
		## Prendo l'indice delle due tabelle (indice che le identifica nei vari array)
		##
		indxT1=-1
		indxT2=-1
		for ( indx in nomeTabella ) {
			if (t1 == nomeTabella[indx] ) 
				indxT1=indx
			if (t2 == nomeTabella[indx] )
				indxT2=indx
		}
		if (indxT1 == -1 ) {
			print "Errore: la tabella "t1" non e' presente nell'input" | "cat 1>&2"
			exit 35
		}
		
		if (indxT2 == -1 ) {
			print "Errore: la tabella "t2" non e' presente nell'input" | "cat 1>&2"
			exit 35
		}
		
		pt1=stringPivot[t1]
		pt2=stringPivot[t2]
		
		##
		## Se è definito kt invece di pt, definisco pt al kt-esimo attributo della t-esima tabella
		##
		if(pt1=="") {
			kt1=numPivot[t1]
			
			##
			## Se kt non è nel range di attributi della tabella
			##

			if(kt1>nrAttributiTabella[indxT1]) {
				print "Errore: la posizione dell'attributo "kt1" non e' corretta per la tabella "nomeTabella[indxT1] | "cat 1>&2"
				exit 40 }
			
			split(nomiAttributiTabella[indxT1],nomi," ")
			pt1=nomi[kt1]
		}
		else {
			split(nomiAttributiTabella[indxT1],nomi," ")
			if (! ( pt1 in nomi )) {
				print "Errore: l'attributo "pt1" non è corretto per la tabella "nomeTabella[indxT1] | "cat 1>&2"
				exit 50
			}
		}
		
		##
		## Se è definito kt invece di pt, definisco pt al kt-esimo attributo della t-esima tabella
		##
		if(pt2=="") {
			kt2=numPivot[t2]
			
			##
			## Se kt non è nel range di attributi della tabella
			##

			if(kt2>nrAttributiTabella[indxT2]) {
				print "Errore: la posizione dell'attributo "kt2" non e' corretta per la tabella "nomeTabella[indxT2] | "cat 1>&2"
				exit 40 
				}
			
			split(nomiAttributiTabella[indxT2],nomi," ")
			pt2=nomi[kt2]


		}
		else {
			split(nomiAttributiTabella[indxT2],nomi," ")
			if (! ( pt2 in nomi )) {
				print "Errore: l'attributo "pt2" non è corretto per la tabella "nomeTabella[indxT2] | "cat 1>&2"
				exit 50
			}
		}
		
		
		##
		## Qui ho finito tutti i controlli, cerco il join
		##

		##
		## Prendo tutti i valori della tabella e dell'attributo specificato
		##
		separatore1=separator[fileDiOrigine[indxT1]]
		split(attributi[indxT1"_"pt1], attr1, separatore1)

		separatore2=separator[fileDiOrigine[indxT2]]
		split(attributi[indxT2"_"pt2], attr2, separatore2)

		##
		## Ordino i nomi degli attributi (mi servirà per l'output)
		##
		split(nomiAttributiTabella[indxT1], nomi1, " ")
		asort(nomi1)

		split(nomiAttributiTabella[indxT2], nomi2, " ")
		asort(nomi2)

		##
		## Scrivo le prime due righe del risultato (elenco gli attributi)
		##
		res=""
		for (indNomi1=1; indNomi1<=length(nomi1); indNomi1++) {
		    res=res""nomi1[indNomi1]""separator[nArg-1] }
		for (indNomi2=1; indNomi2<=length(nomi2); indNomi2++) {
		    res=res""nomi2[indNomi2]""separator[nArg-1] }
		res=substr(res, 1, length(res)-1)

		len1=length(nomi1)
		len2=length(nomi2)
		newM=len1+len2
		if (newM>mList[nArg-1]) { mList[nArg-1]=newM }

		##
		## Devo mettere i separatori prima del risultato #######
		##
		spazio=""
		for ( sInd=1; sInd<mList[nArg-1]; sInd++ ) spazio=spazio""separator[nArg-1]
		ultimoCsv[indexUltimoCsv]=spazio
		indexUltimoCsv++

		##
		## Metto i nomi delle tabele prima del risultato
		## 
		ultimoCsv[indexUltimoCsv]=t1""separator[nArg-1]""numPivot[t1]""separator[nArg-1]""t2""separator[nArg-1]""numPivot[t2]""
		indexUltimoCsv++

		##
		## Metto i nomi degli attributi prima del risultato (calcolati sopra)
		##
		ultimoCsv[indexUltimoCsv]=res
		indexUltimoCsv++

		for ( iAttr=1; iAttr< length(attr1); iAttr++ ) {
		
			for ( jAttr=1; jAttr<length(attr2); jAttr++ ) {
				#Con "" forzo la conversione a stringa

			    ##
			    ## Se fa join
			    ##
				if (attr1[iAttr]!="" && attr2[jAttr]!="" && attr1[iAttr]"" == attr2[jAttr]"" ) {

					res=""
					for (indNomi1=1; indNomi1<=length(nomi1); indNomi1++) {
					    ##Prendo il nome dell'attributo
					    nomeAttributo=nomi1[indNomi1]

					    ##Prendo l'attributo
					    split(attributi[indxT1"_"nomeAttributo], attr, separatore1)					  
					    res=res""attr[iAttr]""separator[nArg-1]
					}
					for (indNomi2=1; indNomi2<=length(nomi2); indNomi2++) {
					    ##Prendo il nome dell'attributo
					    nomeAttributo=nomi2[indNomi2]

					    ##Prendo l'attributo
					    split(attributi[indxT2"_"nomeAttributo], attr, separatore2)					  
					    res=res""attr[jAttr]""separator[nArg-1]
					}
					res=substr(res, 1, length(res)-1) #Levo il separatore alla fine
					ultimoCsv[indexUltimoCsv]=res
					indexUltimoCsv++
        
				}
			}
		}			
	}
	##
	## Cancello la vecchia tabella
	##
	system("rm "csvOutput)
	
	for ( ind=1; ind<indexUltimoCsv; ind++) {
	    str=ultimoCsv[ind]
	    split(str,arr,separator[nArg-1])
	    
	    for (i=length(arr); i<mList[nArg-1]; i++)
		str=str""separator[nArg-1]
		     
	    print str >> csvOutput
	}

	spazio=""
        for ( sInd=1; sInd<mList[nArg-1]; sInd++ ) spazio=spazio""separator[nArg-1]
	print spazio >> csvOutput
}
		
