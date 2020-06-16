while read line; do
          export api=$(echo $line | cut -d' ' -f1)
          export ver=$(echo $line | cut -d' ' -f2)
          export apifile="${api}-${ver}.json"
          export v2_url="https://${api}.googleapis.com/\$discovery/rest?version=${ver}"
          export v1_url="https://www.googleapis.com/discovery/v1/apis/${api}/${ver}/rest"
          echo "Checking v2 URL for $api $ver..."
          curl -s --compressed -f -o ~/$apifile $v2_url
          export result=$?
          if [ $result -ne 0 ]; then
            echo "v2 URL failed with $result, checking v1 URL for $api $ver..."
            curl -s --compressed -f -o ~/$apifile $v1_url
            export result=$?
            if [ $result -ne 0 ]; then
              echo "v1 failed also! Giving up."
              exit 1
            fi
          fi
          cat ~/$apifile | python3 -c "import json, sys, collections; disc = json.loads(sys.stdin.read()); disc.pop('etag', None); disc.pop('revision', None); print(json.dumps(disc, indent=2, sort_keys=True))" > $apifile 
        done < apis.txt
