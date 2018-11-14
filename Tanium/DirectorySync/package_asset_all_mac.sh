
# NAVER
# Tanium Sensor - Asset Database Sync 
# 
#
#	
#!/bin/bash
AssetFolder="/Library/Tanium/TaniumClient/NAVER"
AssetFile="AssetInfo.txt"
#AssetSyncURL="http://10.1.1.1/api-auth/endpoint"
MinimumSize=10
CurrentDateTime=`date '+%Y%m%d%H'`

ResultNoData="No Data,,,,,,,,,,,,$CurrentDateTime"
ResultConnectionFailure="Connection Failure,,,,,,,,,,,,$CurrentDateTime"


AssetSyncURL="https://tem.navercorp.com:8000/api-auth/endpoint"

if [ ! -d $AssetFolder ]; then
	mkdir -p "$AssetFolder"
fi

if [ ! -f "$AssetFolder/$AssetFile" ]; then
	touch "$AssetFolder/$AssetFile"
fi

# MAC Address
AllMACAddress=$(networksetup -listallhardwareports | egrep -A 2 "(: Ethernet|: AirPort|: Wi-Fi)" | grep "Ethernet Address" | cut -f 3- -d ' ')

for MACAddress in $AllMACAddress
do
	tempMACAddress="${MACAddress//:/-}"

	echo "$AssetSyncURL/$tempMACAddress"
	retCode=$(curl -k -s -o $AssetFile -w "%{http_code}\n" "$AssetSyncURL/$tempMACAddress/" )
	
	echo $retCode
	if [ $retCode -eq "200" ] || [ $retCode -eq "301" ]; then

		AssetFileLength=$(wc -c <"$AssetFile")

		echo $AssetFileLength

		if [ $AssetFileLength -ge $MinimumSize ]; then

			rm -f "$AssetFolder/$AssetFile" && cp -f $AssetFile "$AssetFolder/$AssetFile"
			echo "Success : $retCode"
		else
			echo $ResultNoData > $AssetFolder/$AssetFile 

		fi

	else
		echo $ResultConnectionFailure > $AssetFolder/$AssetFile 
		echo "Error : $retCode"
	fi

done
