#!/usr/bin/env bash
cd ~/kafka-advanced

# Already done
# curl -O http://packages.confluent.io/archive/6.1/confluent-6.1.1.zip
# unzip confluent-6.1.1.zip

~/kafka-advanced/confluent-6.1.1/bin/schema-registry-start  ~/kafka-advanced/confluent-6.1.1/etc/schema-registry/schema-registry.properties
