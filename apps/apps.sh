#!/bin/bash

# Apps
# https://docs.openshift.org/latest/dev_guide/new_app.html
# https://docs.openshift.org/latest/dev_guide/templates.html
# https://docs.openshift.org/latest/dev_guide/deployments.html
#oc policy add-role-to-user admin admin -n gf-project
#oc policy add-role-to-user cluster-admin admin 
oc new-app -f gasistafelice.yaml \
-p SERVER_NAME=gf.befaircloud.me
watch -n 1 oc get pods

oc exec $(oc get pods | grep back | awk '{print $1}') -- psql -f /code/gasistafelice/fixtures/test.sql
