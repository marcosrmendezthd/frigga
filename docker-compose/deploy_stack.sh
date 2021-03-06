#!/bin/bash

generate_apikey(){
    echo ">> Grafana - Generating API Key - for Viewer"
    apikey=$(curl -s -L -X POST \
        --user admin:admin \
        -H "Content-Type: application/json" \
        --data '{"name":"local","role":"Viewer","secondsToLive":86400}' \
        http://localhost:3000/api/auth/keys | jq -r .key)
    echo $apikey
    [[ ! -z $FRIGGA_TESTING ]] && echo $apikey > .apikey
}

grafana_update_admin_password(){
    echo ">> Grafana - Changing admin password to 'admin'"
    response=$(curl -s -X PUT -H "Content-Type: application/json" -d '{
    "oldPassword": "admin",
    "newPassword": "admin",
    "confirmNew": "admin"
    }' http://admin:admin@localhost:3000/api/user/password)
    msg=$(echo ${response} | jq -r .message)
    echo ">> Grafana - ${msg}"
}

network=$(docker network ls | grep frigga_net)
[[ ! -z $network ]] && echo "ERROR: wait for network to be deleted, docker network ls, or restart docker daemon" && exit
cp docker-compose/prometheus-original.yml docker-compose/prometheus.yml
docker-compose --project-name frigga \
    --file docker-compose/docker-compose.yml \
    up --detach

echo ">> Waiting for Grafana to be ready ..."
counter=0
until [ $counter -gt 6 ]; do
    response=$(curl -s http://admin:admin@localhost:3000/api/health | jq -r .database)
    if [[  $response == "ok" ]]; then
        echo ">> Grafana is ready!"
        grafana_update_admin_password
        generate_apikey
        exit 0
    else
        sleep 10
        counter=$((counter+1))
    fi
done
