#!/usr/bin/env bash
cd ~/kafka-advanced

## Create topics
kafka/bin/kafka-topics.sh --create \
    --replication-factor 1 \
    --partitions 13 \
    --topic my-example-topic \
    --zookeeper  localhost:2181


## List created topics
kafka/bin/kafka-topics.sh --list \
    --zookeeper localhost:2181


