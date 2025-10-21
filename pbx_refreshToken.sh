#!/bin/bash

# Variabili
getEpoch=$(date +%s)
getTempEpoch=$(date -d '+1 year' +%s)
getOldId=$(sed -n 1p ./token)
getOldToken=$(sed -n 2p ./token)

# Prende scadenza attuale token e riduce di 2 gg
getExpire=$(($(curl -s --request GET --url https://$(hostname).wildixin.com/api/v1/PBX/Applications/SimpleToken/ --header "Accept: application/json" --header "Authorization: Bearer ${getOldToken}" | jq -r '.result.records[0].expireTime')-172800))

# Verifica scadenza
if [ $getEpoch -gt $getExpire ]; then

	# Update vecchio token
	curl -s --request PUT \
		--url https://$(hostname).wildixin.com/api/v1/PBX/Applications/SimpleToken/${getOldId}/ \
		--header "Accept: application/json" \
		--header "Authorization: Bearer ${getOldToken}" \
		--header "Content-Type: application/json" \
		--data '{
			"name": "BackupOLD"
		}'

	# Creazione nuovo token
	curl -s --request POST \
		--url https://$(hostname).wildixin.com/api/v1/PBX/Applications/SimpleToken/ \
		--header "Accept: application/json" \
		--header "Authorization: Bearer ${getOldToken}" \
		--header "Content-Type: application/json" \
		--data '{
			"name": "Backup",
			"pbxUser": "admin",
			"expireTime": '$getTempEpoch'
		}'
	
	# Update token file e dichiarazione nuove variabili
	curl -s --request GET \
		--url https://$(hostname).wildixin.com/api/v1/PBX/Applications/SimpleToken/ \
  		--header "Accept: application/json" \
  		--header "Authorization: Bearer ${getOldToken}" | jq -r '.result.records[1].id' > ./token

	curl -s --request GET \
		--url https://$(hostname).wildixin.com/api/v1/PBX/Applications/SimpleToken/ \
  		--header "Accept: application/json" \
  		--header "Authorization: Bearer ${getOldToken}" | jq -r '.result.records[1].secret' >> ./token

	getNewId=$(sed -n 1p ./token)
	getNewToken=$(sed -n 2p ./token)

	# Cancellazione vecchio token
	curl --request DELETE \
		--url "https://$(hostname).wildixin.com/api/v1/PBX/Applications/SimpleToken/${getOldId}/" \
		--header "Accept: application/json" \
		--header "Authorization: Bearer ${getNewToken}"	
	
else
	echo "Nessuna operazione da fare"
fi

exit 0
