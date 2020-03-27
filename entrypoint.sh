#!/bin/sh


envsubst < /dd-config.template.json > /config/dd-config.json

cat /config/dd-config.json

nginx -t
nginx
