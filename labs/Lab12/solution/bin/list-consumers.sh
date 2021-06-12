#!/usr/bin/env bash

cd ~/kafka-advanced

BOOTSTRAP_SERVERS="localhost:9092,localhost:9093"

kafka/bin/kafka-consumer-groups.sh --list  \
    --bootstrap-server "$BOOTSTRAP_SERVERS"


