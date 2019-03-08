#!/bin/bash

toPort() {
	case $1 in
        EXPORT)
          echo "9300"
	  ;;
	GATEKEEPER)
	  echo "9123"
	  ;;
	HAKKEN)
	  echo "8000"
	  ;;
	HIGHWATER)
	  echo "9191"
	  ;;
	HYDROPHONE)
	  echo "9157"
	  ;;
	JELLYFISH)
	  echo "9122" 
	  ;;
	API)
	  echo "9119"
	  ;;
	AUTH)
	  echo "9222"
	  ;;
	BLOB)
	  echo "9225"
	  ;;
	DATA)
	  echo "9220" 
	  ;;
	NOTIFICATION)
	  echo "9223" 
	  ;;
	TASK)
	  echo "9224"
	  ;;
	USER)
	  echo "9221"
	  ;;
	SEAGULL)
	  echo "9120"
	  ;;
	SHORELINE)
	  echo "9107"
	  ;;
	STYX)
	  echo "8009"
	  ;;
	WHISPERER)
	  echo "9127"
	  ;;
	*)
		echo "unknown service $1"
		exit -1
	  ;;
	esac
}

while IFS='' read -r line || [[ -n "$line" ]]
do
   if [[ "$line" =~ "=" ]]
   then
	   stripped="$(echo -e "${line}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
     IFS='=' read -ra ADDR <<< "${stripped}"
     name=${ADDR[0]}
     value=${ADDR[1]}
     if [[ "${value}" =~ " " ]]
     then
	     value=\"$value\"
     fi
     translated=$(echo "${name}" | sed -e "s/TIDEPOOL_DOCKER_//" -e 's/_/\./g' | tr '[:upper:]' '[:lower:]')

     IFS='_' read -ra PARTS <<< "${name}"
     len=${#PARTS[@]}
	tlen=${#translated}
     if [[ "$1" == "template" ]]
     then
       if [[ "$name" =~ "PREFIX" ]]
       then
         echo "export $name="
	 portName=$(echo $name | sed -e "s/_PREFIX//")
	 echo "export $portName={{.Value.${translated:0: $tlen-7}}"
       else
         echo "export $name={{.Values.${translated}}}"
       fi
     else
       if [[ "$name" =~ "PREFIX" ]]
       then
	 service=${PARTS[len-3]}
	 port=$(toPort $service)
	 echo "${translated:0: $tlen-7}: $port"
       else
         echo "${translated}: ${value}"
       fi
     fi
fi
done
if [[ "$1" == "template" ]]
then
	echo "export TIDEPOOL_DOCKER_BLIP_PORT={{.Values.blip.port}}"
else
        echo "blip.port=9300"
fi
