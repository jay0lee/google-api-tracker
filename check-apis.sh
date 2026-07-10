#!/bin/bash

# Define the multi-line Python script cleanly
pyparser='
import json
import os
import sys
import re

# Read JSON from standard input
disc = json.loads(sys.stdin.read())

# Remove volatile fields
disc.pop("etag", None)
disc.pop("revision", None)

# Redact the API key using regex
url = os.getenv("use_url", "")
disc["retrieved_from"] = re.sub(r"key=[^&]*", "key=****", url)

# Output the formatted JSON
print(json.dumps(disc, indent=2, sort_keys=True))
'

while read line; do
    api=$(echo $line | cut -d' ' -f1);
    ver=$(echo $line | cut -d' ' -f2);
    apifile="${api}-${ver}.json"
    
    # 1) v2 URL with key
    v2_url_key="https://${api}.googleapis.com/\$discovery/rest?version=${ver}&key=${googleapikey}"
    # 2) v1 URL with key
    v1_url_key="https://www.googleapis.com/discovery/v1/apis/${api}/${ver}/rest?key=${googleapikey}"
    # 3) v2 URL without key
    v2_url_nokey="https://${api}.googleapis.com/\$discovery/rest?version=${ver}"
    # 4) v1 URL without key
    v1_url_nokey="https://www.googleapis.com/discovery/v1/apis/${api}/${ver}/rest"
    
    echo "1) Checking v2 URL with key for $api $ver..."
    export use_url="${v2_url_key}"
    curl -s -f --compressed -o ~/$apifile $use_url; result=$?; true;
    
    if [ $result -ne 0 ]; then
        echo "   v2 URL with key failed (${result})."
        echo "2) Checking v1 URL with key for $api $ver..."
        export use_url="${v1_url_key}"
        curl -s -f --compressed -o ~/$apifile $use_url; result=$?; true;
        
        if [ $result -ne 0 ]; then
            echo "   v1 URL with key failed (${result})."
            echo "3) Checking v2 URL without key for $api $ver..."
            export use_url="${v2_url_nokey}"
            curl -s -f --compressed -o ~/$apifile $use_url; result=$?; true;
            
            if [ $result -ne 0 ]; then
                echo "   v2 URL without key failed (${result})."
                echo "4) Checking v1 URL without key for $api $ver..."
                export use_url="${v1_url_nokey}"
                curl -s -f --compressed -o ~/$apifile $use_url; result=$?; true;
                
                if [ $result -ne 0 ]; then
                    echo "   v1 URL without key also failed (${result}). Giving up."
                    continue
                fi
            fi
        fi
    fi
    
    # Process the successful JSON payload through the formatted Python script
    cat ~/$apifile | python3 -c "${pyparser}" > $apifile;

done < apis.txt
