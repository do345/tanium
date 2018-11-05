
##################################
## STEP 1. BASIC CONFIGURATION

#NAVER SERVER 
  SERVER=10.105.83.143
  USERNAME=taniumadmin
  PASSWORD=xksldna2@
  

  ENDPOINTIP=10.12.43.87


#  ENDPOINTIP=10.10.151.117
#  ENDPOINTIP=10.0.2.15 

#HYOSUNG ITX SERVER
#  SERVER=13.124.3.149
#  USERNAME=taniumadmin
#  PASSWORD=

  # Get the tanium session key.
  B64_USER=$(echo -n ${USERNAME} | base64)
  B64_PASS=$(echo -n ${PASSWORD} | base64)

##################################
## STEP 2. GET THE TANIUM SESSION KET
  echo "[STEP 2. GET THE TANIUM SESSION KEY]"

  TANIUM_SESSION=$(curl -vks -H "Username: ${B64_USER}" -H "Password: ${B64_PASS}" "https://${SERVER}/auth")
#  echo -n $TANIUM_SESSION | pbcopy
  echo $TANIUM_SESSION > api.session
  TSESS= cat api.session
#  echo $TSESS
#  echo "sleep 1"
  sleep 1
  echo  "---------------------------------------------------"


##################################
## STEP 3. ESTABLISH LIVE CONNECTION (POST)
  echo "[STEP 3. ESTABLISH LIVE CONNECTION (POST)]"

  LIVECONNECT_RESULT=$(curl -v -X POST  https://${SERVER}/plugin/products/trace/conns  -k  -H "session: ${TANIUM_SESSION}"  -H "Content-Type: application/json" -H "Cache-Control: no-cache"  -d  '{ "remote": true,    "dst": "'$ENDPOINTIP'",    "dstType": "'$ENDPOINTIP'" }'	) 

  sleep 10
  echo  "---------------------------------------------------"

  COMPUTER_NAME=""


  while [[ -z $COMPUTER_NAME ]]; do

    sleep 5

##################################
## STEP 4. GET LIST OF LIVE CONECTION
    echo "[STEP 4. GET LIST OF LIVE CONNECTION]"
    LIVECONNECT_LIST=$(curl -k -i -X GET https://${SERVER}/plugin/products/trace/conns  -H "session: ${TANIUM_SESSION}" )

    #echo $LIVECONNECT_LIST
    echo  "---------------------------------------------------"

##################################
## STEP 5. EXTRACE LIST OF COMPUTER NAME 

    echo "[STEP 5. EXTRACT COMPUTER NAME ]"
   
    COMPUTER_NAME=`echo $LIVECONNECT_LIST | sed -e  's/,{"name":"/\'$'\n/g' | grep  'wasConnected":true'  | grep $ENDPOINTIP | awk -F '","' '{print $1}'`
    echo $COMPUTER_NAME 

    if [[ -n $COMPUTER_NAME ]]; then
      echo "CONNECTION COMPLETED"
    else
      echo "RETRY CONNECTION"
    fi

    echo  "---------------------------------------------------"

  done

  SNAPSHOT_FLAG=""
  while [[ -z $SNAPSHOT_FLAG ]]; do

##################################
## STEP 6. SNAPSHOT (POST)
    echo "[STEP 6. SNAPSHOT (POST) ]"
    SNAPSHOT_RESULT=$(curl -v -X POST  https://${SERVER}/plugin/products/trace/conns/${COMPUTER_NAME}/snapshots  -k  -H "session: ${TANIUM_SESSION}"  -H "Content-Type: application/json" -H "Cache-Control: no-cache"  )
    #echo -n $SNAPSHOT_RESULT
    echo  "---------------------------------------------------"


##################################
## STEP 7. GET LIST OF SNAPSHOT LIST 
    echo "[STEP 7. GET LIST OF SNAPSHOT LIST]"
    SNAPSHOT_LIST=$(curl -k -i -X GET https://${SERVER}/plugin/products/trace/snapshots  -H "session: ${TANIUM_SESSION}" )
    #echo $SNAPSHOT_LIST
    echo  "---------------------------------------------------"

##################################
## STEP 8. EXTRACT LIST OF SNAPSHOT NAME 
    echo "[STEP 8. EXTRACT SNAPSHOT STATUS  ]"

    sleep 5

    SNAPSHOT_STATUS=`echo $SNAPSHOT_LIST | sed -e  's/}},"/\'$'\n/g' | grep $COMPUTER_NAME | awk -F '"state":' '{print $NF}'`
    #echo $SNAPSHOT_STATUS 


    if [[ $SNAPSHOT_STATUS =~ "backup" ]]; then
      SNAPSHOT_FLAG="BACKUP"
      echo "SNAPSHOT IS SUCCESSFULLY IN PROGRESS!"
    elif [[ $SNAPSHOT_STATUS =~ "error" ]]; then
      SNAPSHOT_FLAG="ERROR"
      echo "SNAPSHOT FAILURE!"
    fi

    echo $SNAPSHOT_FLAG

    echo  "---------------------------------------------------"

  done



