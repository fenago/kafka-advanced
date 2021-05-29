#!/usr/bin/env bash
cd ~/kafka-advanced

## Producer
kafka/bin/kafka-console-producer.sh --broker-list localhost:9092 --topic word-count-input
