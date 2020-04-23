#!/bin/bash

#subscriptionId=$(az account show | jq -r .id)
#nullId="00000000-0000-0000-0000-000000000000"

#sed "s/$subscriptionId/$nullId/g" roles.json > cleanedroles.json

 #| select(.roleType=="CustomRole" | not
 rm -rf roles/* 

cleanedroles=$(cat cleanedroles.json)
for row in $(echo "${cleanedroles}" | jq -r '.[] | select(.roleType=="BuiltInRole") | @base64'); do
    _jq() {
     echo ${row} | base64 --decode | jq -r ${1}
    }
   roleName="$(_jq '.roleName').json"
   roleName=${roleName// /_}
   echo $row | base64 --decode | jq > "roles/${roleName}"
   
done

