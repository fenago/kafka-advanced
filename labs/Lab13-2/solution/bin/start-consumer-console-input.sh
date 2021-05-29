#!/usr/bin/env bash
cd ~/kafka-advanced

## Input Consumer
kafka/bin/kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic word-count-input --from-beginning
