#!/usr/bin/env bash

PORT=8080
echo "Port: $PORT"

# POST method predict
curl -d '{  
   "Weight":200
}'\
     -H "Content-Type: application/json" \
     -X POST https://twmvef3ipe.ap-southeast-2.awsapprunner.com/predict