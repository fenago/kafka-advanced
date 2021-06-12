#!/usr/bin/env bash
cd ~/kafka-advanced
kafka/bin/kafka-topics.sh \
    --delete \
    --zookeeper localhost:2181 \
    --topic stock-prices





