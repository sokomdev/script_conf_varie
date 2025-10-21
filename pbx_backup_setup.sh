#!/bin/bash

rm -R .bkps/


# Creare directory
mkdir .bkps && cd .bkps

# Creare i file necessari e rendere eseguibili gli script
touch token ftp_login login


RAW_BASE="https://raw.githubusercontent.com/sokomdev/script_conf_varie/main"
FILES=(
    "pbx_ftp_upload.sh"
    "pbx_refreshToken.sh"
)
for file in "${FILES[@]}"; do
    echo "Downloading $file..."
    curl -s -O "$RAW_BASE/$file"
done


chmod +x pbx_ftp_upload.sh
chmod +x pbx_refreshToken.sh

# Editing file creati
echo ftppbx-$(hostname) >> ftp_login
echo 'CAMBIAMI_PWD_FTP' >> ftp_login
echo 'ftpbkp.sokom.it' >> ftp_login

echo 'admin' >> login
echo 'CAMBIAMI_PWD_WEB' >> login
echo https://$(hostname).wildixin.com/api/v1/pbx/settings/backups?token= >> login

echo 'INSERISCI_ID_TOKEN' >> token
echo 'INSERISCI_KEY_TOKEN' >> token

# Editare crontab per running settimanale script backup e daily controllo token
crontab -l 2>/dev/null; echo "# PATH
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

# Refresh token Backup
0 0 * * * cd /root/.bkps && ./pbx_refreshToken.sh > /dev/null

# Cron upload backup via FTP
30 5 * * 6 cd /root/.bkps && ./pbx_ftp_upload.sh > /dev/null" | crontab -

# Rimuovere cartelle sporche backup in /mnt/backups
rm -r /mnt/backups/$(hostname)*/

# Avvertenze
echo "Attenzione! Inserire manualmente le password nei file ftp_login e login
e id e key token nel file token"

exit 0
