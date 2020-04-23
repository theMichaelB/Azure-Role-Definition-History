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
   echo $row | base64 -d | jq -r '.' > "roles/${roleName}"
   
done

if ! git diff --no-ext-diff --quiet --exit-code; then
    git switch master
    git add roles/*
    git config --global user.email "action@azured.io"
    git config --global user.name "Github Action"
    commitDate=$(date "+%Y-%B-%d")
    git commit -m $commitDate
    git remote set-url origin "$(git config --get remote.origin.url | sed 's#http.*com/#git@github.com:#g')"
    eval `ssh-agent -t 60 -s`
    echo "$GHA_DEPLOY_KEY" | ssh-add -
    mkdir -p ~/.ssh/
    ssh-keyscan github.com >> ~/.ssh/known_hosts
    git push origin master
    ssh-agent -k
fi
