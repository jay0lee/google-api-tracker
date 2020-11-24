#!/bin/bash

pyparser="import json, sys, collections; disc = json.loads(sys.stdin.read()); disc.pop('etag', None); disc.pop('revision', None); print(json.dumps(disc, indent=2, sort_keys=True))"

while read line; do
    api=$(echo $line | cut -d' ' -f1);
    ver=$(echo $line | cut -d' ' -f2);
    apifile="${api}-${ver}.json"
    v2_url="https://${api}.googleapis.com/\$discovery/rest?version=${ver}";
    v1_url="https://www.googleapis.com/discovery/v1/apis/${api}/${ver}/rest";
    echo "Checking v2 URL for $api $ver...";
    curl -s -f --compressed -o ~/$apifile $v2_url; result=$?; true;
    if [ $result -ne 0 ]; then
        echo "v2 URL failed with $result, checking v1 URL for $api $ver...";
        curl -s --compressed -f -o ~/$apifile $v1_url; result=$?; true;
        if [ $result -ne 0 ]; then
            echo "$api $ver v1 failed also with $result!";
        fi;
    fi;
    cat ~/$apifile | python3 -c "${pyparser}" > $apifile;
done < apis.txt
