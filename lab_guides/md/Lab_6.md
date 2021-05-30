
Lab 6. Building Storm Applications with Kafka
----------------------------------------------------------



cd ~/kafka-advanced

kafka/bin/kafka-topics.sh --create \
  --zookeeper localhost:2181 \
  --replication-factor 1 --partitions 1 \
  --topic new_topic




mvn compile exec:java





cd ~/kafka-advanced

kafka/bin/kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic streams-plaintext-input --from-beginning





mvn clean compile exec:java  -Dmain.class=com.stormadvance.kafka.KafkaTopology

mvn clean install




cd $STORM_HOME
bin/storm jar ~/storm-kafka-topology-0.0.1-SNAPSHOT-jar-with-dependencies.jar com.stormadvance.kafka.KafkaTopology KafkaTopology1

