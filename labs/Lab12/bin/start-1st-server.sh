#!/usr/bin/env bash
CONFIG=`pwd`/config
cd ~/kafka-advanced

## Run Kafka for 1st Server
kafka/bin/kafka-server-start.sh \
    "$CONFIG/server-0.properties"







