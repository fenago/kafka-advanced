#!/usr/bin/env bash
CONFIG=`pwd`/config
cd ~/kafka-advanced

## Run Kafka for 3rd Server
kafka/bin/kafka-server-start.sh \
    "$CONFIG/server-2.properties"





