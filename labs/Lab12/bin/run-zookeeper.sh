#!/usr/bin/env bash
CONFIG=`pwd`/config
cd ~/kafka-advanced

## Run ZooKeeper for 1st Cluster
kafka/bin/zookeeper-server-start.sh \
   "$CONFIG/zookeeper.properties"






