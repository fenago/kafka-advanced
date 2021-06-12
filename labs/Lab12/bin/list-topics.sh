#!/usr/bin/env bash

cd ~/kafka-advanced

# List existing topics
kafka/bin/kafka-topics.sh --list \
    --zookeeper localhost:2181


