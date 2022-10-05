#!/bin/bash

pyparser="import json, os, sys, collections; disc = json.loads(sys.stdin.read()); disc.pop('etag', None); disc.pop('revision', None); disc['retrieved_from'] = os.getenv('use_url'); print(json.dumps(disc, indent=2, sort_keys=True))"

while read line; do
    api=$(echo $line | cut -d' ' -f1);
    ver=$(echo $line | cut -d' ' -f2);
    apifile="${api}-${ver}.json"
    v2_url="https://${api}.googleapis.com/\$discovery/rest?version=${ver}";
    v1_url="https://www.googleapis.com/discovery/v1/apis/${api}/${ver}/rest";
    echo "Checking v2 URL ${v2_url} for $api $ver...";
    export use_url="${v2_url}"
    curl -s -f --compressed -o ~/$apifile $use_url; result=$?; true;
    if [ $result -ne 0 ]; then
        echo " v2 URL failed with ${result}, checking v1 URL ${v1_url} for ${api} ${ver}...";
        export use_url="${v1_url}"
        curl -s --compressed -f -o ~/$apifile $use_url; result=$?; true;
        if [ $result -ne 0 ]; then
            echo " v1 also failed with ${result} for ${api} ${ver}. Giving up.";
            continue
        fi;
    fi;
    cat ~/$apifile | python3 -c "${pyparser}" > $apifile;
done < apis.txt
