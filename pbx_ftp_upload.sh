#!/bin/bash

# Variabili
ftpUser=$(sed -n 1p ./ftp_login)
ftpPass=$(sed -n 2p ./ftp_login)
ftpHost=$(sed -n 3p ./ftp_login)
userC=$(sed -n 1p ./login)
passC=$(sed -n 2p ./login)
hostC=$(sed -n 3p ./login)
tokenC=$(sed -n 2p ./token)

# Genera backup
curl --request POST $hostC$tokenC -u "$userC":"$passC"

# Definisce il file di backup da caricare e la directory remota
ftpFile=$(ls -rt /mnt/backups/$(hostname)_20* | tail -n 1)
ftpRemote=$(ls -rt /mnt/backups/$(hostname)_20* | tail -n 1 | xargs basename)

sleep 2 

# Invio ultimo backup via FTP
ftp -inv $ftpHost <<END_SCRIPT
	user $ftpUser $ftpPass
	binary
	put $ftpFile $ftpRemote
	bye
END_SCRIPT

# Retention ogni 90gg e mantiene ultimi 4 files in caso di failure

dateFiles=$(find "/mnt/backups" -maxdepth 1 -type f -name "$(hostname)_20*" -mtime -90 -print)

# Trova i 4 file più recenti (indipendentemente dalla data)
topFiles=$(ls -t "/mnt/backups/$(hostname)_20*" 2>/dev/null | head -n 4)

# Combina le due liste di file e rimuovi i duplicati per ottenere i file da MANTENERE
# Se ci sono meno di 4 file totali, li mantiene tutti.
keepFiles=$(
    {
        echo "$dateFiles"
        echo "$topFiles"
    } | sort -u
)

# Trova tutti i file che corrispondono al pattern
matchFilesRaw=$(find "/mnt/backups" -maxdepth 1 -type f -name "$(hostname)_20*")

# Ordina l'output di find per poterlo confrontare con i file da mantenere (sort -u già ordina)
matchFilesAll=$(echo "$matchFilesRaw" | sort)

# Confronta le due liste per trovare i file da eliminare
# comm -23 <(file1) <(file2) mostra solo le linee presenti in file1 ma non in file2
fileRet=$(comm -23 <(echo "$matchFilesAll") <(echo "$keepFiles"))

# Controlla se sono presenti backup da eliminare
if [ -z "$fileRet" ]; then
    echo "Nessun file da eliminare."
else
    echo "$fileRet"
    echo "$fileRet" | xargs rm
fi


exit 0
