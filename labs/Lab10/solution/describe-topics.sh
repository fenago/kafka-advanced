#!/usr/bin/env bash

cd ~/kafka-advanced

# List existing topics
kafka/bin/kafka-topics.sh --describe \
    --topic my-failsafe-topic \
    --zookeeper localhost:2181



