

Lab 4. Deep Dive into Kafka Consumers
--------------------------------------------------



Every messaging system has two types of data flows. One flow pushes the
data to the Kafka queues and the other flow reads the data from those
queues. In the previous lab, our focus was on the data flows that
are pushing the data to Kafka queues using producer APIs. After reading
the previous lab, you should have sufficient knowledge about
publishing data to Kafka queues using producer APIs in your application.
In this lab, our focus is on the second type of data flow\--reading
the data from Kafka queues.

Before we start with a deep dive into Kafka consumers, you should have a
clear understanding of the fact that reading data from Kafka queues
involves understanding many different concepts and they may differ from
reading data from traditional queuing systems.


### Note

With Kafka, every consumer has a unique identity and they are in full
control of how they want to read data from each Kafka topic partition.
Every consumer has its own consumer offset that is maintained in
Zookeeper and they set it to the next location when they read data from
a Kafka topic.


In this lab, we will cover different concepts of Kafka consumers.
Overall, this lab covers how to consume messages from Kafka systems
along with Kafka consumer APIs and their usage. It will walk you through
some examples of using Kafka consumer APIs with Java and Scala
programming languages and take a deep dive with you into consumer
message flows along with some of the common patterns of consuming
messages from Kafka topics.

We will cover the following topics in this lab:


-   Kafka consumer internals
-   Kafka consumer APIs
-   Java Kafka consumer example
-   Scala Kafka consumer example
-   Common message consuming patterns
-   Best practices



Kafka consumer internals 
----------------------------------------



In this section of the lab, we will cover different Kafka consumer
concepts and various data flows involved in consuming messages from
Kafka queues. As already mentioned, consuming messages from Kafka is a
bit different from other messaging systems. However, when you are
writing consumer applications using consumer APIs, most of the details
are abstracted. Most of the internal work is done by Kafka consumer
libraries used by your application.

Irrespective of the fact that you do not have to code for most of the
consumer internal work, you should understand these internal workings
thoroughly. These concepts will definitely help you in debugging
consumer applications and also in making the right application decision
choices.



### Understanding the responsibilities of Kafka consumers



On the same lines of the previous lab on Kafka producers, we will
start by understanding the responsibilities of Kafka consumers apart
from consuming messages from Kafka queues.

Let\'s look at them one by one:


-   [**Subscribing to a topic**]: Consumer operations start
    with subscribing to a topic. If consumer is part of a consumer
    group, it will be assigned a subset of partitions from that topic.
    Consumer process would eventually read data from those assigned
    partitions. You can think of topic subscription as a registration
    process to read data from topic partitions.
-   [**Consumer offset position**]: Kafka, unlike any other
    queues, does not maintain message offsets. Every consumer is
    responsible for maintaining its own consumer offset. Consumer
    offsets are maintained by consumer APIs and you do not have to do
    any additional coding for this. However, in some use cases where you
    may want to have more control over offsets, you can write custom
    logic for offset commits. We will cover such scenarios in this
    lab.
-   [**Replay / rewind / skip messages**]: Kafka consumer has
    full control over starting offsets to read messages from a topic
    partition. Using consumer APIs, any consumer application can pass
    the starting offsets to read messages from topic partitions. They
    can choose to read messages from the beginning or from some specific
    integer offset value irrespective of what the current offset value
    of a partition is. In this way, consumers have the capability of
    replaying or skipping messages as per specific business scenarios.
-   [**Heartbeats**]: It is the consumer\'s responsibility to
    ensure that it sends regular heartbeat signals to the Kafka broker
    (consumer group leader) to confirm their membership and ownership of
    designated partitions. If heartbeats are not received by the group
    leader in a certain time interval, then the partition\'s ownership
    would be reassigned to some other consumer in the consumer group.
-   [**Offset commits**]: Kafka does not track positions or
    offsets of the messages that are read from consumer applications. It
    is the responsibility of the consumer application to track their
    partition offset and commit it. This has two advantages\--this
    improves broker performance as they do not have to track each
    consumer offset and this gives flexibility to consumer applications
    in managing their offsets as per their specific scenarios. They can
    commit offsets after they finish processing a batch or they can
    commit offsets in the middle of very large batch processing to
    reduce side-effects of rebalancing.
-   [**Deserialization**]: Kafka producers serialize objects
    into byte arrays before they are sent to Kafka. Similarly, Kafka
    consumers deserialize these Java objects into byte arrays. Kafka
    consumer uses the deserializers that are the same as serializers
    used in the producer application.


Now that you have a fair idea of the responsibilities of a consumer, we
can talk about consumer data flows.

The following image depicts how data is fetched from Kafka consumers:


![](./images/ae955771-6aeb-45d7-a7fb-492071be845e.png)

Consumer flows

The first step toward consuming any messages from Kafka is topic
subscription. Consumer applications first subscribe to one or more
topics. After that, consumer applications poll Kafka servers to fetch
records. In general terms, this is called [**poll loop**]. This
loop takes care of server co-ordinations, record retrievals, partition
rebalances, and keeps alive the heartbeats of consumers.


### Note

For new consumers that are reading data for the first time, poll loop
first registers the consumer with the respective consumer group and
eventually receives partition metadata. The partition metadata mostly
contains partition and leader information of each topic.


Consumers, on receiving metadata, would start polling respective brokers
for partitions assigned to them. If new records are found, they are
retrieved and deserialized. They are finally processed and after
performing some basic validations, they are stored in some external
storage systems.

In very few cases, they are processed at runtime and passed to some
external applications. Finally, consumers commit offsets of messages
that are successfully processed. The poll loop also sends periodic
keep-alive heartbeats to Kafka servers to ensure that they receive
messages without interruption.



Kafka consumer APIs 
-----------------------------------



Like Kafka producer, Kafka also provides a rich set of APIs to develop a
consumer application. In previous sections of this lab, you have
learned about internal concepts of consumer, working of consumer within
a consumer group, and partition rebalance. We will see how this concept
helps in building a good consumer application.


-   Consumer configuration
-   KafkaConsumer object
-   Subscription and polling
-   Commit and offset
-   Additional configuration




### Consumer configuration



Creating Kafka consumer also requires a few mandatory properties to be
set. There are basically four properties:


-   `bootstrap.servers`: This property is similar to what we
    defined in Lab 3 for
    producer configuration. It takes a list of Kafka brokers\' IPs.
-   `key.deserializer`: This is similar to what we specified
    in producer. The difference is that in producer, we specified the
    class that can serialize the key of the message. Serialize means
    converting a key to a ByteArray. In consumer, we specify the class
    that can deserialize the ByteArray to a specific key type. Remember
    that the serializer used in producer should match with the
    equivalent deserializer class here; otherwise, you may get a
    serialization exception.



-   `value.deserializer`: This property is used to deserialize
    the message. We should make sure that the deserializer class should
    match with the serializer class used to produce the data; for
    example, if we have used `StringSerializer` to serialize
    the message in producer, we should use
    `StringDeserializer` to deserialize the message.
-   `group.id`: This property is not mandatory for the
    creation of a property but recommended to use while creating. You
    have learned in the previous section about consumer groups and their
    importance in performance. Defining a consumer group while creating
    an application always helps in managing consumers and increasing
    performance if needed.


Let\'s see how we set and create this in the real programming world.

Java:

```
Properties consumerProperties = new Properties();
consumerProperties.put("bootstrap.servers", "10.200.99.197:6667");
consumerProperties.put("group.id", "Demo");
consumerProperties.put("key.deserializer","org.apache.kafka.common.serialization.StringDeserializer");consumerProperties.put("value.deserializer","org.apache.kafka.common.serialization.StringDeserializer");KafkaConsumer<String, String> consumer = new KafkaConsumer<String, String>(consumerProperties);
```

Scala:

```
val consumerProperties: Properties = new Properties();
consumerProperties.put("bootstrap.servers", "10.200.99.197:6667")
consumerProperties.put("group.id", "consumerGroup1")
consumerProperties.put("key.deserializer", "org.apache.kafka.common.serialization.StringDeserializer")consumerProperties.put("value.deserializer", "org.apache.kafka.common.serialization.StringDeserializer")
val consumer: KafkaConsumer[String, String] = new KafkaConsumer[String, String](consumerProperties)
```

The preceding code contains three specific things:


-   `Properties` object: This object is used to initialize
    consumer properties. Mandatory properties discussed earlier can be
    set as a key-value pair, where the key would be the property name
    and value would be the value for the key.



-   `Deserializer`: This is also a mandatory property that
    tells which deserializer class is to be used to convert ByteArray to
    the required object. Class can be different for key and value, but
    it should align with the serializer class used in producer while
    publishing data to the topic. Any mismatch will lead to a
    serialization exception.
-   `KafkaConsumer`: Once properties are set, we can create a
    consumer object by passing this property to the class. Properties
    tell the consumer object about brokers IP to connect, the group name
    that the consumer should be part of, the deserialization class to
    use, and offset strategy to be used for the commit.





### Subscription and polling



Consumer has to subscribe to some topic to receive data. The
`KafkaConsumer` object has `subscribe()`, which
takes a list of topics that the consumer wants to subscribe to. There
are different forms of the subscribe method.

Let\'s talk about the subscribe method in detail with its different
signatures:


-   `public void subscribe(Collection<String> topics)`:
    This signature takes a list of topic names to which the consumer
    wants to subscribe. It uses the default rebalancer, which may affect
    data processing of the message.



-   `public void subscribe(Pattern pattern,ConsumerRebalanceListener listener)`:
    This signature takes regex to match topics that exist in Kafka. This
    process is dynamic; any addition of a new topic matching the regex
    or deletion of a topic matching the regex will trigger the
    rebalancer. The second parameter,
    `ConsumerRebalanceListener`, will take your own class that
    implements this interface. We will talk about this in detail.



-   `public void subscribe(Collection<String> topics,ConsumerRebalanceListener listener)`:
    This takes a list of topics and your implementation of
    `ConsumerRebalanceListner`.





### Committing and polling



Polling is fetching data from the Kafka topic. Kafka returns the
messages that have not yet been read by consumer. How does Kafka know
that consumer hasn\'t read the messages yet?

Consumer needs to tell Kafka that it needs data from a particular offset
and therefore, consumer needs to store the latest read message somewhere
so that in case of consumer failure, consumer can start reading from the
next offset.

Kafka commits the offset of messages that it reads successfully. There
are different ways in which commit can happen and each way has its own
pros and cons. Let\'s start looking at the different ways available:


-   [**Auto commit**]: This is the default configuration of
    consumer. Consumer auto-commits the offset of the latest read
    messages at the configured interval of time. If we
    make`enable.auto.commit = true` and set
    `auto.commit.interval.ms=1000`, then consumer will commit
    the offset every second. There are certain risks associated with
    this option. For example, you set the interval to 10 seconds and
    consumer starts consuming the data. At the seventh second, your
    consumer fails, what will happen? Consumer hasn\'t committed the
    read offset yet so when it starts again, it will start reading from
    the start of the last committed offset and this will lead to
    duplicates.
-   [**Current offset commit**]: Most of the time, we may want
    to have control over committing an offset when required. Kafka
    provides you with an API to enable this feature. We first need to do
    `enable.auto.commit = false` and then use
    the`commitSync()`method to call a commit offset from the
    consumer thread. This will commit the latest offset returned by
    polling. It would be better to use this method call after we process
    all instances of `ConsumerRecord`, otherwise there is a
    risk of losing records if consumer fails in between.


Java:

```
while (true) {
    ConsumerRecords<String, String> records = consumer.poll(2);
    for (ConsumerRecord<String, String> record : records)
        System.out.printf("offset = %d, key = %s, value = %sn",
                record.offset(), record.key(), record.value());
    try {
        consumer.commitSync();
    } catch (CommitFailedException ex) {
        //Logger or code to handle failed commit
    }
}
```

Scala:

```
while (true) {
  val records: ConsumerRecords[String, String] = consumer.poll(2)
  import scala.collection.JavaConversions._
  for (record <- records) println("offset = %d, key = %s, value = %sn", record.offset, record.key, record.value)

  try
    consumer.commitSync()

  catch {
    case ex: CommitFailedException => {
      //Logger or code to handle failed commit
    }
  }
}
```


-   [**Asynchronous commit**]: The problem with synchronous
    commit is that unless we receive an acknowledgment for a commit
    offset request from the Kafka server, consumer will be blocked. This
    will cost low throughput. It can be done by making commit happen
    asynchronously. However, there is a problem in asynchronous
    commit\--it may lead to duplicate message processing in a few cases
    where the order of the commit offset changes. For example, offset of
    message 10 got committed before offset of message 5. In this case,
    Kafka will again serve message 5-10 to consumer as the latest offset
    10 is overridden by 5.


Java:

```
while (true) {
    ConsumerRecords<String, String> records = consumer.poll(2);
    for (ConsumerRecord<String, String> record : records)
        System.out.printf("offset = %d, key = %s, value = %sn",
                record.offset(), record.key(), record.value());
    consumer.commitAsync(new OffsetCommitCallback() {
        public void onComplete(Map<TopicPartition, OffsetAndMetadata> map, Exception e) {

        }
    });

}
```

Scala:

```
while (true) {
val records: ConsumerRecords[String, String] = consumer.poll(2)
for (record <- records) println("offset = %d, key = %s, value = %sn", record.offset, record.key, record.value)

consumer.commitAsync(new OffsetCommitCallback {
override def onComplete(map: util.Map[TopicPartition, OffsetAndMetadata], ex: Exception): Unit = {
}
})
}
```

You have learned about synchronous and asynchronous calls. However, the
best practice is to use a combination of both. Asynchronous should be
used after every poll call and synchronous should be used for behaviors
such as the triggering of the rebalancer, closing consumer due to some
condition, and so on.

Kafka also provides you with an API to commit a specific offset.




### Additional configuration



You have learned a few mandatory parameters in the beginning. Kafka
consumer has lots of properties and in most cases, some of them do not
require any modification. There are a few parameters that can help you
increase performance and availability of consumers:


-   `enable.auto.commit`: If this is configured to true, then
    consumer will automatically commit the message offset after the
    configured interval of time. You can define the interval by
    setting`auto.commit.interval.ms`. However, the best idea
    is to set it to false in order to have control over when you want to
    commit the offset. This will help you avoid duplicates and miss any
    data to process.
-   `fetch.min.bytes`: This is the minimum amount of data in
    bytes that the Kafka server needs to return for a fetch request. In
    case the data is less than the configured number of bytes, the
    server will wait for enough data to accumulate and then send it to
    consumer. Setting the value greater than the default, that is, one
    byte, will increase server throughput but will reduce latency of the
    consumer application.
-   `request.timeout.ms`:This is the maximum amount of time
    that consumer will wait for a response to the request made before
    resending the request or failing when the maximum number of retries
    is reached.
-   `auto.offset.reset`:This property is used when consumer
    doesn\'t have a valid offset for the partition from which it is
    reading the value.
    
    -   [**latest**]: This value, if set to latest, means that
        the consumer will start reading from the latest message from the
        partition available at that time when consumer started.
    -   [**earliest**]: This value, if set to earliest, means
        that the consumer will start reading data from the beginning of
        the partition, which means that it will read all the data from
        the partition.
    -   [**none**]: This value, if set to none, means that an
        exception will be thrown to the consumer.
    
-   `session.timeout.ms`:Consumer sends a heartbeat to the
    consumer group coordinator to tell it that it is alive and restrict
    triggering the rebalancer. The consumer has to send heartbeats
    within the configured period of time. For example, if timeout is set
    for 10 seconds, consumer can wait up to 10 seconds before sending a
    heartbeat to the group coordinator; if it fails to do so, the group
    coordinator will treat it as dead and trigger the rebalancer.
-   `max.partition.fetch.bytes`: This represents the maximum
    amount of data that the server will return per partition. Memory
    required by consumer for the `ConsumerRecord` object must
    be bigger then [*numberOfParition\*valueSet*]. This means
    that if we have 10 partitions and 1 consumer, and
    `max.partition.fetch.bytes` is set to 2 MB, then consumer
    will need [*10\*2 =20*] MB for consumer record.


Remember that before setting this, we must know how much time consumer
takes to process the data; otherwise, consumer will not be able to send
heartbeats to the consumer group and the rebalance trigger will occur.
The solution could be to increase session timeout or decrease partition
fetch size to low so that consumer can process it as fast as it can.



Java Kafka consumer 
-----------------------------------



The following program is a simple Java consumer which consumes data from
topic test. Please make sure data is already available in the mentioned
topic otherwise no record will be consumed.

```
import org.apache.kafka.clients.consumer.*;
import org.apache.kafka.common.TopicPartition;
import org.apache.log4j.Logger;

import java.util.*;

public class DemoConsumer {
    private static final Logger log = Logger.getLogger(DemoConsumer.class);

    public static void main(String[] args) throws Exception {

        String topic = "test1";
        List<String> topicList = new ArrayList<>();
        topicList.add(topic);
        Properties consumerProperties = new Properties();
        consumerProperties.put("bootstrap.servers", "localhost:9092");
        consumerProperties.put("group.id", "Demo_Group");
        consumerProperties.put("key.deserializer",
                "org.apache.kafka.common.serialization.StringDeserializer");
        consumerProperties.put("value.deserializer",
                "org.apache.kafka.common.serialization.StringDeserializer");

        consumerProperties.put("enable.auto.commit", "true");
        consumerProperties.put("auto.commit.interval.ms", "1000");
        consumerProperties.put("session.timeout.ms", "30000");

        KafkaConsumer<String, String> demoKafkaConsumer = new KafkaConsumer<String, String>(consumerProperties);

        demoKafkaConsumer.subscribe(topicList);
        log.info("Subscribed to topic " + topic);
        int i = 0;
        try {
            while (true) {
                ConsumerRecords<String, String> records = demoKafkaConsumer.poll(500);
                for (ConsumerRecord<String, String> record : records)
                    log.info("offset = " + record.offset() + "key =" + record.key() + "value =" + record.value());

                //TODO : Do processing for data here 
                demoKafkaConsumer.commitAsync(new OffsetCommitCallback() {
                    public void onComplete(Map<TopicPartition, OffsetAndMetadata> map, Exception e) {

                    }
                });

            }
        } catch (Exception ex) {
            //TODO : Log Exception Here
        } finally {
            try {
                demoKafkaConsumer.commitSync();

            } finally {
                demoKafkaConsumer.close();
            }
        }
    }
}
```



Scala Kafka consumer 
------------------------------------



This is the Scala version of the previous program and will work the same
as the previous snippet. Kafka allows you to write consumer in many
languages including Scala.

```
import org.apache.kafka.clients.consumer._
import org.apache.kafka.common.TopicPartition
import org.apache.log4j.Logger
import java.util._


object DemoConsumer {
  private val log: Logger = Logger.getLogger(classOf[DemoConsumer])

  @throws[Exception]
  def main(args: Array[String]) {
    val topic: String = "test1"
    val topicList: List[String] = new ArrayList[String]
    topicList.add(topic)
    val consumerProperties: Properties = new Properties
    consumerProperties.put("bootstrap.servers", "10.200.99.197:6667")
    consumerProperties.put("group.id", "Demo_Group")
    consumerProperties.put("key.deserializer", "org.apache.kafka.common.serialization.StringDeserializer")      consumerProperties.put("value.deserializer","org.apache.kafka.common.serialization.StringDeserializer")
    consumerProperties.put("enable.auto.commit", "true")
    consumerProperties.put("auto.commit.interval.ms", "1000")
    consumerProperties.put("session.timeout.ms", "30000")
    val demoKafkaConsumer: KafkaConsumer[String, String] = new KafkaConsumer[String, String](consumerProperties)
    demoKafkaConsumer.subscribe(topicList)
    log.info("Subscribed to topic " + topic)
    val i: Int = 0
    try
        while (true) {
          val records: ConsumerRecords[String, String] = demoKafkaConsumer.poll(2)
          import scala.collection.JavaConversions._
          for (record <- records) {
            log.info("offset = " + record.offset + "key =" + record.key + "value =" + record.value)
            System.out.print(record.value)
          }
          //TODO : Do processing for data here
          demoKafkaConsumer.commitAsync(new OffsetCommitCallback() {
            def onComplete(map: Map[TopicPartition, OffsetAndMetadata], e: Exception) {
            }
          })
        }

    catch {
      case ex: Exception => {
        //TODO : Log Exception Here
      }
    } finally try
      demoKafkaConsumer.commitSync()
    finally demoKafkaConsumer.close()
  }
}
```



### Rebalance listeners



We discussed earlier that in case of addition or removal of consumer to
the consumer group, Kafka triggers the rebalancer and consumer loses the
ownership of the current partition. This may lead to duplicate
processing when the partition is reassigned to consumer. There are some
other operations such as database connection operation, file operation,
or caching operations that may be part of consumer; you may want to deal
with this before ownership of the partition is lost.

Kafka provides you with an API to handle such scenarios. It provides the
`ConsumerRebalanceListener` interface that contains the
`onPartitionsRevoked()` and `onPartitionsAssigned()`
methods. We can implement these two methods and pass an object while
subscribing to the topic using the `subscribe` method
discussed earlier:

```
import org.apache.kafka.clients.consumer.ConsumerRebalanceListener;
import org.apache.kafka.common.TopicPartition;

import java.util.Collection;

public class DemoRebalancer implements ConsumerRebalanceListener {
    @Override
    public void onPartitionsRevoked(Collection<TopicPartition> collection) {
        //TODO: Things to Do before your partition got revoked
    }

    @Override
    public void onPartitionsAssigned(Collection<TopicPartition> collection) {
         //TODO : Things to do when  new partition get assigned 
    }
}
```



Common message consuming patterns 
-------------------------------------------------



Here are a few of the common message consuming patterns:


-   [**Consumer group - continuous data processing**]: In this
    pattern, once consumer is created and subscribes to a topic, it
    starts receiving messages from the current offset. The consumer
    commits the latest offsets based on the count of messages received
    in a batch at a regular, configured interval. The consumer checks
    whether it\'s time to commit, and if it is, it will commit the
    offsets. Offset commit can happen synchronously or asynchronously.
    It uses the auto-commit feature of the consumer API.


The key point to understand in this pattern is that consumer is not
controlling the message flows. It is driven by the current offset of the
partition in a consumer group. It receives messages from that current
offset and commits the offsets as and when messages are received by it
after regular intervals. The main advantage of this pattern is that you
have a complete consumer application running with far less code, and as
this kind of pattern mostly depends on the existing consumer APIs, it is
less buggy.

The following image represents the continuous data processing pattern:


![](./images/a5c19ab3-f09a-4bb4-92f2-50cfb94426de.png)

Consumer group - continuous data processing


-   [**Consumer group - discrete data processing**]: Sometimes
    you want more control over consuming messages from Kafka. You want
    to read specific offsets of messages that may or may not be the
    latest current offset of the particular partition. Subsequently, you
    may want to commit specific offsets and not the regular latest
    offsets. This pattern outlines such a type of discrete data
    processing. In this, consumers fetch data based on the offset
    provided by them and they commit specific offsets that are as per
    their specific application requirements.


Commit can happen synchronously or asynchronously. The consumer API
allows you to call `commitSync()`and `commitAsync()`
and pass a map of partitions and offsets that you wish to commit.

This pattern can be used in a variety of ways. For example, to go back a
few messages or skip ahead a few messages (perhaps a time-sensitive
application that is falling behind will want to skip ahead to more
relevant messages), but the most exciting use case for this ability is
when offsets are stored in a system other than Kafka. Think about this
common scenario - your application is reading events from Kafka (perhaps
a clickstream of users in a website), processes the data (perhaps clean
up clicks by robots and add session information), and then stores the
results in a database, NoSQL store, or Hadoop. Suppose that we really
don\'t want to lose any data nor do we want to store the same results in
the database twice. The following image shows the discrete data
processing pattern:


![](./images/64615729-b2b8-4945-a810-993a16ff3b2f.png)

Consumer group - discrete data processing



Best practices 
------------------------------



After going through the lab, it is important to note a few of the
best practices. They are listed as follows:


-   [**Exception handling**]: Just like producers, it is the
    sole responsibility of consumer programs to decide on program flows
    with respect to exceptions. A consumer application should define
    different exception classes and, as per your business requirements,
    decide on the actions that need to be taken.
-   [**Handling rebalances**]: Whenever any new consumer joins
    consumer groups or any old consumer shuts down, a partition
    rebalance is triggered. Whenever a consumer is losing its partition
    ownership, it is imperative that they should commit the offsets of
    the last event that they have received from Kafka. For example, they
    should process and commit any in-memory buffered datasets before
    losing the ownership of a partition. Similarly, they should close
    any open file handles and database connection objects.
-   [**Commit offsets at the right time**]: If you are choosing
    to commit offset for messages, you need to do it at the right time.
    An application processing a batch of messages from Kafka may take
    more time to complete the processing of an entire batch; this is not
    a rule of thumb but if the processing time is more than a minute,
    try to commit the offset at regular intervals to avoid duplicate
    data processing in case the application fails. For more critical
    applications where processing duplicate data can cause huge costs,
    the commit offset time should be as short as possible if throughput
    is not an important factor.
-   [**Automatic offset commits:**] Choosing an auto-commit is
    also an option to go with where we do not care about processing
    duplicate records or want consumer to take care of the offset commit
    automatically. For example, the auto-commit interval is 10 seconds
    and at the seventh second, consumer fails. In this case, the offset
    for those seven seconds has not been committed and the next time the
    consumer recovers from failure, it will again process those seven
    seconds records.



### Note

Keeping the auto-commit interval low will always result in avoiding less
processing of duplicate messages.



-   In the [*Committing and polling*] section, a call to the
    poll function will always commit the last offset of the previous
    poll. In such cases, you must ensure that all the messages from the
    previous poll have been successfully processed, otherwise you may
    lose records if the consumer application fails after a new previous
    poll last offset commit and before all the messages from the
    previous poll call are processed. So always make sure that the new
    call to polling only happens when all the data from the previous
    poll call is finished.[]



Summary 
-----------------------



This concludes our section on Kafka consumers. This lab addresses
one of the key functionalities of Kafka message flows. The major focus
was on understanding consumer internal working and how the number of
consumers in the same group and number of topic partitions can be
utilized to increase throughput and latency. We have also covered how to
create consumers using consumer APIs and how to handle message offsets
in case consumer fails. We started with Kafka consumer APIs and also
covered synchronous and asynchronous consumers and their advantages and
disadvantages. We explained how to increase the throughput of a consumer
application. We then went through the consumer rebalancer concept and
when it gets triggered and how we can create our own rebalancer. We also
focused on different consumer patterns that are used in different
consumer applications. We focused on when to use it and how to use it.

In the end, we wanted to bring in some of the best practices of using
Kafka consumers. These best practices will help you in scalable designs
and in avoiding some common pitfalls. Hopefully, by the end of this
lab, you have mastered the art of designing and coding Kafka
consumers.

In the next lab, we will go through an introduction to Spark and
Spark streaming, and then we will look at how Kafka can be used with
Spark for a real-time use case and the different ways to integrate Spark
with Kafka.
