#!/bin/bash

rm /opt/bitnami/config/monit/bitnami.conf
cat >/opt/bitnami/config/monit/bitnami.conf <<EOL
set httpd port 2812 and
    allow 0.0.0.0/0.0.0.0
include /opt/bitnami/config/monit/conf.d/*.conf
EOL
chmod 700 /opt/bitnami/config/monit/bitnami.conf

n=0
until [ $n -ge 5 ]
do
   apt-get update && apt-get install monit && break
   n=$[$n+1]
   sleep 3m
done

ln -s /opt/bitnami/config/monit/bitnami.conf /etc/monit/conf.d/bitnami.conf
monit reload
