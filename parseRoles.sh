#!/bin/bash


az role definition list > roles.json

subscriptionId=$(az account show | jq -r .id)
nullId="00000000-0000-0000-0000-000000000000"

sed "s/$subscriptionId/$nullId/g" roles.json > cleanedroles.json

rm -rf roles/* 

cleanedroles=$(cat cleanedroles.json)
for row in $(echo "${cleanedroles}" | jq -r '.[] | select(.roleType=="BuiltInRole") | @base64'); do
    _jq() {
     echo ${row} | base64 -d | jq -r ${1}
    }
   roleName="$(_jq '.roleName').json"
   roleName=${roleName// /_}
   echo $row | base64 -d | jq > "roles/${roleName}"
   
done

git add roles/*
commitDate=$(date "+%Y-%B-%d")
git commit -m $commitDate
git push origin master
