#!/bin/sh


envsubst < /dd-config.template.json > /etc/dd-config.json

cat /etc/dd-config.json

nginx -t
nginx
