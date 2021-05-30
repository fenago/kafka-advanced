
Lab 6. Building Storm Applications with Kafka
----------------------------------------------------------



cd ~/kafka-advanced

kafka/bin/kafka-topics.sh --create --zookeeper localhost:2181 --replication-factor 1 --partitions 1 --topic new_topic





mvn clean compile exec:java  -Dmain.class=com.stormadvance.kafka_producer.KafkaSampleProducer






cd ~/kafka-advanced

kafka/bin/kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic verification --from-beginning

kafka/bin/kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic new_topic --from-beginning





mvn clean compile exec:java  -Dmain.class=com.stormadvance.storm_kafka_topology.KafkaTopology

mvn clean install


