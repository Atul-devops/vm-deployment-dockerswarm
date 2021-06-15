#!/bin/sh
export $(cat .env) > /dev/null 2>&1; 
sudo env $(cat .env | grep ^[A-Z] | xargs) docker stack deploy -c mercury-homepage.yml ${STACK_NAME} --with-registry-auth
