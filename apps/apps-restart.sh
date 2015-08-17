#!/bin/bash

oc delete all -l app=gf
./up.sh
