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
     echo "${translated}: ${value}"
  fi
done
