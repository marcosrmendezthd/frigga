#!/bin/bash
FRIGGA_FOLDER="/root/frigga/.frigga"

GRAFANA_HOST="http://grafana.default.svc.cluster.local:3000"
RANDOM_KEY_NAME=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 10 ; echo '')
GRAFANA_API_KEY=$(curl -X POST -sL --user admin:admin -H "Content-Type: application/json" --data '{"name":"'${RANDOM_KEY_NAME}'","role":"Viewer","secondsToLive":86400}' ${GRAFANA_HOST}/api/auth/keys | jq -r .key)

# Install frigga
python3 -m pip install --editable ${FRIGGA_FOLDER}

# Generate .metrics.json 
frigga gl -gurl ${GRAFANA_HOST} -gkey ${GRAFANA_API_KEY}

# Add filters to prometheus.yml
frigga pa -ppath ${FRIGGA_FOLDER}/kubernetes/prometheus.yml -mjpath .metrics.json

# Reload prometheus
curl -X POST http://prometheus.default.svc.cluster.local:9090/-/reload
echo ">> [LOG] Prometheus was reloaded"