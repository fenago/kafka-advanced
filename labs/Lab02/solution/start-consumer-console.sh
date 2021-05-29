#!/usr/bin/env bash
cd ~/kafka-advanced

kafka/bin/kafka-console-consumer.sh \
    --bootstrap-server localhost:9092 \
    --topic my-topic \
    --from-beginning


