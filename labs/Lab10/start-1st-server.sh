#!/usr/bin/env bash
CONFIG=`pwd`/config

cd ~/kafka-advanced

## TODO Run Kafka
kafka/bin/kafka-server-start.sh "$CONFIG/server-0.properties"
## TODO Pass config file.
# HINT: "$CONFIG/server-0.properties"


