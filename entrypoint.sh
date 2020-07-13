#!/bin/sh


envsubst < /dd-config.template.json > /config/dd-config.json

envsubst < /env.txt > /config/env.txt

cat /config/dd-config.json

cat /config/env.txt

nginx -t
nginx
