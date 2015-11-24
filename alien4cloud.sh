#!/bin/sh

echo " █████╗ ██╗     ██╗███████╗███╗   ██╗    ██╗      █████╗ ██╗   ██╗███╗   ██╗ ██████╗██╗  ██╗███████╗██████╗ "
echo "██╔══██╗██║     ██║██╔════╝████╗  ██║    ██║     ██╔══██╗██║   ██║████╗  ██║██╔════╝██║  ██║██╔════╝██╔══██╗"
echo "███████║██║     ██║█████╗  ██╔██╗ ██║    ██║     ███████║██║   ██║██╔██╗ ██║██║     ███████║█████╗  ██████╔╝"
echo "██╔══██║██║     ██║██╔══╝  ██║╚██╗██║    ██║     ██╔══██║██║   ██║██║╚██╗██║██║     ██╔══██║██╔══╝  ██╔══██╗"
echo "██║  ██║███████╗██║███████╗██║ ╚████║    ███████╗██║  ██║╚██████╔╝██║ ╚████║╚██████╗██║  ██║███████╗██║  ██║"
echo "╚═╝  ╚═╝╚══════╝╚═╝╚══════╝╚═╝  ╚═══╝    ╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝"                                                                                                          
echo ""
CONFIG=1
if [ ! -f "$USERPROFILE/alienlauncher.properties" ];then
	CONFIG=0
	echo '# Path to folder containig alien4cloud .war' >> $USERPROFILE/alienlauncher.properties
	echo 'WARFOLDER=""' >> $USERPROFILE/alienlauncher.properties
	echo '# Path to folder containig alien4cloud data' >> $USERPROFILE/alienlauncher.properties
	echo 'ALIENDATAS=$USERPROFILE/.alien' >> $USERPROFILE/alienlauncher.properties
	echo '# Alien4cloud credential' >> $USERPROFILE/alienlauncher.properties
	echo 'USER=""' >> $USERPROFILE/alienlauncher.properties
	echo 'PASSWD=""' >> $USERPROFILE/alienlauncher.properties
	echo 'HTTP_PROXY=""' >> $USERPROFILE/alienlauncher.properties
	echo 'HTTP_PROXY=""' >> $USERPROFILE/alienlauncher.properties
	
fi
. $USERPROFILE/alienlauncher.properties
if [ -z "$WARFOLDER" ]; then
	CONFIG=0
fi

if [ -z "$USER" ]; then
	CONFIG=0
fi

if [ -z "$PASSWD" ]; then
	CONFIG=0
fi

if [ -z "$ALIENDATAS" ]; then
	CONFIG=0
fi

if [ ! -f "$WARFOLDER/postConfig.sh" ]; then
	echo '#!/bin/sh
echo "Postconfig init" >> postconf.log
if [ -f "postconf.log" ];then
	rm postconf.log
fi
if [ -f "cookiefile" ];then
	rm cookiefile
fi
sleep 30

arr=$(echo $1 | tr "." "\n")
folder=""
for x in $arr
do
	if [[ $x != "war" ]]; then
		if [[ $folder != "" ]]; then
			folder=$folder"."$x
		else
			folder=$x
		fi
	fi  
done

loadPLUGIN () {
	if [ -d "$folder/plugin" ];then
		for entity in "$folder/plugin/"*
		do
			if [[ ${entity##*/} == *.zip ]] ; then
				response=`curl -F "filecomment=loaded via REST" -F "file=@"$entity http://localhost:8088/rest/plugin -b cookiefile`
				if [[ $response != '\''{"data":null,"error":null}'\'' ]]; then
					curl -F "filecomment=loaded via REST" -F "file=@"$entity http://localhost:8088/rest/plugins -b cookiefile
				fi
				
			fi
		done
	fi		
}

loadCSAR () {
	if [ -d "$folder/csar" ];then
		for entity in "$folder/csar/"*
		do
			if [[ ${entity##*/} == *.zip ]] ; then
				curl -F "filecomment=loaded via REST" -F "file=@"$entity http://localhost:8088/rest/csars -b cookiefile
			fi
		done
	fi
}

loadCLOUDIMAGE () {
	if [ -d "$folder/image" ];then
		for entity in "$folder/image/"*
		do
			if [[ ${entity##*/} == *.json ]] ; then
				local JSONCONTENT=`cat $entity  | tr -d '\''\r\n'\''`
				curl -H "Content-Type: application/json" -X POST -d $JSONCONTENT http://localhost:8088/rest/cloud-images -b cookiefile
			fi
		done
	fi
} 


echo "Alienversion : "$1  >> postconf.log
echo "Ressources folder : "$folder >> postconf.log
if [ -d "${folder}" ];then
TRIES=0
while [ $TRIES -lt 10 ]
do
	curl -s http://localhost:8088/login -c cookiefile -d "username=$2&password=$3&submit=Login"
	TRIES=$((TRIES+1))
	echo "try to log to alien for "$TRIES"th times ..." >> postconf.log
	if [ -f cookiefile ];then
		cat cookiefile
		echo "Successfully connected" >> postconf.log
		break
	fi
	sleep 5
done

#if [ -d "${folder}" ];then
	echo "loading plugin ..." >> postconf.log
	loadPLUGIN

	echo "loading csar ..." >> postconf.log
	loadCSAR

	echo "loading image ..." >> postconf.log
	loadCLOUDIMAGE
fi' >> $WARFOLDER/postConfig.sh
fi

if [ $CONFIG -eq 1 ]; then
	
	export HTTP_PROXY=$HTTP_PROXY
	export HTTPS_PROXY=$HTTPS_PROXY
	echo ""
	echo "*******************************************"
	echo "*                                         *"
	echo "*   Do you wish to clean .alien folder?   *"
	echo "*                                         *"
	echo "*******************************************"

	select yn in "Yes" "No"; do
	    case $yn in
	        Yes ) cd $ALIENDATAS; rm -R *; break;;
	        No ) break;;
	    esac
	done

	cd $WARFOLDER
	if [ ! -d "oldlog" ];then
		mkdir oldlog
	fi
	horodate=$(date '+%Y%m%d%H%M')
	log="alien4cloud.log"
	if [ -f "${log}" ];then
		mv $log $WARFOLDER"/oldlog/${horodate}.log"
	fi

	echo ""
	i=0
	WAR=()  
	echo "*******************************************"
	echo "*                                         *"
	echo "*          Choose alien version :         *" 
	echo "*                                         *"
	echo "*******************************************"
	echo ""
	echo ""
	for entity in "$WARFOLDER"/*
	do
		if [[ ${entity##*/} == *.war ]] ; then
			i=`expr $i + 1`
			WAR+=(${entity##*/})
			echo $i") "${entity##*/}
		fi
	done

	read version

	version=`expr $version - 1`

	./postConfig.sh ${WAR[$version]} $USER $PASSWD &

	java -server -showversion -XX:+AggressiveOpts -Xms512m -Xmx2g -XX:MaxPermSize=512m -jar ${WAR[$version]}
else
	echo "properties not setted please watch $USERPROFILE/alienlauncher.properties"
	sleep 30
fi
