#!/bin/bash

#git checkout master
az provider list > provider.json

subscriptionId=$(az account show | jq -r .id)
nullId="00000000-0000-0000-0000-000000000000"

sed "s/$subscriptionId/$nullId/g" provider.json > cleanedprovider.json

rm -rf providers/* 

mkdir -p providers
cleanedprovider=$(cat cleanedprovider.json)
for row in $(echo "${cleanedprovider}" | jq -r '.[]| @base64'); do
    _jq() {
     echo ${row} | base64 -d | jq -r ${1}
    }
   namespace="$(_jq '.namespace').json"
   namespace=${namespace// /_}
   echo $row | base64 -d | jq -r '.' > "providers/${namespace}"
done   


# largely stolen from - https://github.com/eine/actions/blob/3f0701c2f20780984590bd955839a38b75c96668/.github/workflows/push.yml
if ! git diff --no-ext-diff --quiet --exit-code; then

    git config --global user.email "action@azured.io"
    git config --global user.name "Github Action"
    
    echo "Staging providers/*"
    git add -A -v -- providers/*
    git ls-files --deleted -z | xargs -0 git rm 
    echo "Committing changes"
    commitDate=$(date "+%Y-%B-%d")
    git commit -m $commitDate
    git remote set-url origin "$(git config --get remote.origin.url | sed 's#http.*com/#git@github.com:#g')"
    eval `ssh-agent -t 60 -s`
    echo "$GHA_DEPLOY_KEY" | ssh-add -
    mkdir -p ~/.ssh/
    ssh-keyscan github.com >> ~/.ssh/known_hosts
    echo "Pushing origin"
    git push origin master
    ssh-agent -k
fi
