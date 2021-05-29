

Lab 3. Deep Dive into Kafka Producers
--------------------------------------------------



In previous labs, you have learned about messaging systems and Kafka
architecture. While it is a good start, we will now take a deeper look
into Kafka producers. Kafka can be used as a message queue, message bus,
or data storage system. Irrespective of how Kafka is used in your
enterprise, you will need an application system that can write data to
the Kafka cluster. Such a system is called a [**producer**]. As
the name suggests, they are the source or producers of messages for
Kafka topics. Kafka producers publish messages as per Kafka protocols
defined by the makers of Kafka. This lab is all about producers,
their internal working, examples of writing producers using Java or
Scala APIs, and some of the best practices of writing Kafka APIs. We
will cover the following topics in this lab:


-   Internals of a Kafka producer
-   The Kafka Producer API and its uses
-   Partitions and their uses
-   Additional configuration for producers
-   Some common producer patterns
-   An example of a producer
-   Best practices to be followed for a Kafka producer



Kafka producer internals 
----------------------------------------



In this section, we will walk through different Kafka producer
components, and at a higher level, cover how messages get transferred
from a Kafka producer application to Kafka queues. While writing
producer applications, you generally use Producer APIs, which expose
methods at a very abstract level. Before sending any data, a lot of
steps are performed by these APIs. So it is very important to understand
these internal steps in order to gain complete knowledge about Kafka
producers. We will cover these in this section. First, we need to
understand the responsibilities of Kafka producers apart from publishing
messages. Let\'s look at them one by one:


-   [**Bootstrapping Kafka broker URLs**]: The Producer
    connects to at least one broker to fetch metadata about the Kafka
    cluster. It may happen that the first broker to which the producer
    wants to connect may be down. To ensure a failover, the producer
    implementation takes a list of more than one broker URL to bootstrap
    from. Producer iterates through a list of Kafka broker addresses
    until it finds the one to connect to fetch cluster metadata.
-   [**Data serialization:**] Kafka uses a binary protocol to
    send and receive data over TCP. This means that while writing data
    to Kafka, producers need to send the ordered byte sequence to the
    defined Kafka broker\'s network port. Subsequently, it will read the
    response byte sequence from the Kafka broker in the same ordered
    fashion. Kafka producer serializes every message data object into
    [**ByteArrays**] before sending any record to the
    respective broker over the wire. Similarly, it converts any byte
    sequence received from the broker as a response to the message
    object.
-   [**Determining topic partition:**] It is the responsibility
    of the Kafka producer to determine which topic partition data needs
    to be sent. If the partition is specified by the caller program,
    then Producer APIs do not determine topic partition and send data
    directly to it. However, if no partition is specified, then producer
    will choose a partition for the message. This is generally based on
    the key of the message data object. You can also code for your
    custom partitioner in case you want data to be partitioned as per
    specific business logic for your enterprise.
-   [**Determining the leader of the partition**]: Producers
    send data to the leader of the partition directly. It is the
    producer\'s responsibility to determine the leader of the partition
    to which it will write messages. To do so, producers ask for
    metadata from any of the Kafka brokers. Brokers answer the request
    for metadata about active servers and leaders of the topic\'s
    partitions at that point of time.
-   [**Failure handling/retry ability:**] Handling failure
    responses or number of retries is something that needs to be
    controlled through the producer application. You can configure the
    number of retries through Producer API configuration, and this has
    to be decided as per your enterprise standards. Exception handling
    should be done through the producer application component. Depending
    on the type of exception, you can determine different data flows.
-   [**Batching:**] For efficient message transfers, batching
    is a very useful mechanism. Through Producer API configurations, you
    can control whether you need to use the producer in
    [**asynchronous**] mode or not. Batching ensures reduced
    I/O and optimum utilization of producer memory. While deciding on
    the number of messages in a batch, you have to keep in mind the
    end-to-end latency. End-to-end latency increases with the number of
    messages in a batch.


Hopefully, the preceding paragraphs have given you an idea about the
prime responsibilities of Kafka producers. Now, we will discuss Kafka
producer data flows. This will give you a clear understanding about the
steps involved in producing Kafka messages.


### Note

Internal implementation or the sequence of steps in Producer APIs may
differ for respective programming languages. Some of the steps can be
done in parallel using threads or callbacks.


The following image shows the high-level steps involved in producing
messages to the Kafka cluster:


![](./images/f3fc32c0-0c9d-4778-a991-e61146bb6d8a.png)

Kafka producer high-level flow

Publishing messages to a Kafka topic starts with calling Producer APIs
with appropriate details such as messages in string format, topic,
partitions (optional), and other configuration details such as broker
URLs and so on. The Producer API uses the passed on information to form
a data object in a form of nested key-value pair. Once the data object
is formed, the producer serializes it into byte arrays. You can either
use an inbuilt serializer or you can develop your custom serializer.
[**Avro**] is one of the commonly used data serializers.


### Note

[**Serialization**] ensures compliance to the Kafka binary
protocol and efficient network transfer.


Next, the partition to which data needs to be sent is determined. If
partition information is passed in API calls, then producer would use
that partition directly. However, in case partition information is not
passed, then producer determines the partition to which data should be
sent. Generally, this is decided by the keys defined in data objects.
Once the record partition is decided, producer determines which broker
to connect to in order to send messages. This is generally done by the
bootstrap process of selecting the producers and then, based on the
fetched metadata, determining the leader broker.

Producers also need to determine supported API versions of a Kafka
broker. This is accomplished by using API versions exposed by the Kafka
cluster. The goal is that producer will support different versions of
Producer APIs. While communicating with the respective leader broker,
they should use the highest API version supported by both the producers
and brokers.

Producers send the used API version in their write requests. Brokers can
reject the write request if a compatible API version is not reflected in
the write request. This kind of setup ensures incremental API evolution
while supporting older versions of APIs.

Once a serialized data object is sent to the selected Broker, producer
receives a response from those brokers. If they receive metadata about
the respective partition along with new message offsets, then the
response is considered successful. However, if error codes are received
in the response, then producer can either throw the exception or retry
as per the received configuration.

As we move further in the lab, we will dive deeply into the
technical side of Kafka Producer APIs and write them using Java and
Scala programs.



Kafka Producer APIs 
-----------------------------------



Kafka has provided you with a rich set of APIs to create applications to
interact with it. We will go through Producer API details and understand
its uses.

Creating a Kafka producer involves the following steps:


1.  Required configuration.
2.  Creating a producer object.
3.  Setting up a producer record.
4.  Creating a custom partition if required.
5.  Additional configuration.


Required configuration: In most applications, we first start with
creating the initial configuration without which we cannot run the
application. The following are three mandatory configuration parameters:


-   `bootstrap.servers`: This contains a list of Kafka brokers
    addresses. The address is specified in terms of
    `hostname:port`. We can specify one or more broker detail,
    but we recommend that you provide at least two so that if one broker
    goes down, producer can use the other one.



### Note

It is not necessary to specify all brokers as the Kafka producer queries
this configured broker for information about other brokers. In older
versions of Kafka, this property was `metadata.broker.list`,
where we used to specify a list of brokers `host:port`.



-   `key.serializer`: The message is sent to Kafka brokers in
    the form of a key-value pair. Brokers expect this key-value to be in
    byte arrays. So we need to tell producer which serializer class is
    to be used to convert this key-value object to a byte array. This
    property is set to tell the producer which class to use to serialize
    the key of the message.


Kafka provides us with three inbuilt serializer classes:
`ByteArraySerializer`, `StringSerializer`, and
`IntegerSerializer`. All these classes are present in the
`org.apache.kafka.common.serialization` package and implement
the serializer interface.

 


-   `value.serializer`: This is similar to the
    `key.serializer` property, but this property tells the
    producer which class to use in order to serialize the value. You can
    implement your own serialize class and assign to this property.


Let\'s see how we do it in a programming context.

Here is how Java works for Producer APIs:

```
Properties producerProps = new Properties();
producerProps.put("bootstrap.servers", "broker1:port,broker2:port");
producerProps.put("key.serializer",
    "org.apache.kafka.common.serialization.StringSerializer");
     producerProps.put("value.serializer",
      "org.apache.kafka.common.serialization.StringSerializer");
KafkaProducer<String, String> producer = new KafkaProducer<String,String>(producerProps);
```

The Producer API in Scala:

```
val producerProps = new Properties()
 producerProps.put("bootstrap.servers", "broker1:port,broker2:port");

       producerProps.put("key.serializer",        "org.apache.kafka.common.serialization.StringSerializer")
     producerProps.put("value.serializer",      "org.apache.kafka.common.serialization.StringSerializer")

 val producer = new KafkaProducer[String, String](producerProps)
```

The preceding code contains three specific points:


-   [**Properties object**]: We start with creating a property
    object; this object contains the `put` method that is used
    to put the configuration key-value pair in place
-   [**Serializer class**]: We will use
    `StringSerializer` for both key and value as our key and
    value will be of the string type
-   [**Producer object**]: We create a producer object by
    passing the configuration object to it, which provides the producer
    with specific information about broker servers, serializer classes,
    and other configurations that we will see later




### Producer object and ProducerRecord object



Producer accepts the `ProducerRecord` object to send records
to the `.ProducerRecord` topic. It contains a topic name,
partition number, `timestamp`, key, and value. Partition
number, `timestamp`, and key are optional parameters, but the
topic to which data will be sent and value that contains the data is
mandatory.


-   If the partition number is specified, then the specified partition
    will be used when sending the record
-   If the partition is not specified but a key is specified, a
    partition will be chosen using a hash of the key
-   If both key and partition are not specified, a partition will be
    assigned in a round-robin fashion


Here is the `producerRecord` in Java:

```
ProducerRecord producerRecord = new ProducerRecord<String, String>(topicName, data);
Future<RecordMetadata> recordMetadata = producer.send(producerRecord);
```

Here is an example of `producerRecord` in Scala:

```
val producerRecord = new ProducerRecord<String, String>(topicName, data);
val recordMetadata = producer.send(producerRecord);
```

We have different constructors available for `ProducerRecord`:


-   Here is the first constructor for `producerRecord`:


```
ProducerRecord(String topicName, Integer numberOfpartition, K key, V value)
```


-   The second constructor goes something like this:


```
ProducerRecord(String topicName, Integer numberOfpartition, Long timestamp, K key, V value)
```


-   The third constructor is as follows:


```
ProducerRecord(String topicName, K key, V value)
```


-   The final constructor of our discussion is as follows:


```
ProducerRecord(String topicName, V value)
```

Each record also has a `timestamp` associated with it. If we
do not mention a `timestamp`, the producer will stamp the
record with its current time. The `timestamp` eventually used
by Kafka depends on the `timestamp` type configured for the
particular topic:


-   [**CreateTime**]: The `timestamp` of
    `ProducerRecord` will be used to append a
    `timestamp` to the data
-   [**LogAppendTime**]: The Kafka broker will overwrite the
    `timestamp` of `ProducerRecord` to the message
    and add a new `timestamp` when the message is appended to
    the log


Once data is sent using the `send()` method, the broker
persists that message to the partition log and returns
`RecordMetadata`, which contains metadata of the server
response for the record, which includes `offset`,
`checksum`, `timestamp`, `topic`,
`serializedKeySize`, and so on. We previously discussed common
messaging publishing patterns. The sending of messages can be either
synchronous or asynchronous.

[**Synchronous messaging**]: Producer sends a message and waits
for brokers to reply. The Kafka broker either sends an error or
`RecordMetdata`. We can deal with errors depending on their
type. This kind of messaging will reduce throughput and latency as the
producer will wait for the response to send the next message.

Generally, Kafka retries sending the message in case certain connection
errors occur. However, errors related to serialization, message, and so
on have to be handled by the application, and in such cases, Kafka does
not try to resend the message and throws an exception immediately.

Java:

```
ProducerRecord producerRecord = new ProducerRecord<String, String>(topicName, data);

Object recordMetadata = producer.send(producerRecord).get();
```

Scala:

```
val producerRecord = new ProducerRecord<String, String>(topicName, data);

valrecordMetadata = producer.send(producerRecord);
```

[**Asynchronous messaging**]: Sometimes, we have a scenario
where we do not want to deal with responses immediately or we do not
care about losing a few messages and we want to deal with it after some
time.

Kafka provides us with the callback interface that helps in dealing with
message reply, irrespective of error or successful. `send()`
can accept an object that implements the callback interface.

`send(ProducerRecord<K,V> record,Callbackcallback)`

The callback interface contains the `onCompletion` method,
which we need to override. Let\'s look at the following example:

Here is the example in Java:

```
public class ProducerCallback implements Callback {
public void onCompletion(RecordMetadata recordMetadata, Exception ex) {
if(ex!=null){
//deal with exception here 
}
else{
//deal with RecordMetadata here
}
}
}
```

Scala:

```
class ProducerCallback extends Callback {
override def onCompletion(recordMetadata: RecordMetadata, ex: Exception): Unit = {
if (ex != null) {
//deal with exception here
}
else {
//deal with RecordMetadata here
}
}
} 
```

Once we have the `Callback` class implemented, we can simply
use it in the `send` method as follows:

```
val callBackObject = producer.send(producerRecord,new ProducerCallback());
```

If Kafka has thrown an exception for the message, we will not have a
null exception object. We can also deal with successful and error
messages accordingly in `onCompletion()`.




### Custom partition



Remember that we talked about key serializer and value serializer as
well as partitions used in Kafka producer. As of now, we have just used
the default partitioner and inbuilt serializer. Let\'s see how we can
create a custom partitioner.

Kafka generally selects a partition based on the hash value of the key
specified in messages. If the key is not specified/null, it will
distribute the message in a round-robin fashion. However, sometimes you
may want to have your own partition logic so that records with the same
partition key go to the same partition on the broker. We will see some
best practices for partitions later in this lab. Kafka provides you
with an API to implement your own partition.

In most cases, a hash-based default partition may suffice, but for some
scenarios where a percentage of data for one key is very large, we may
be required to allocate a separate partition for that key. This means
that if key K has 30 percent of total data, it will be allocated to
partition N so that no other key will be assigned to partition N and we
will not run out of space or slow down. There can be other use cases as
well where you may want to write `Custom Partition`. Kafka
provides the partitionerinterface, which helps us create our own
partition.

Here is an example in Java:

```
public class CustomePartition implements Partitioner {
    public int partition(String topicName, Object key, byte[] keyBytes, Object value, byte[] valueByte, Cluster cluster) {
        List<PartitionInfo> partitions = cluster.partitionsForTopic(topicName);

        int numPartitions = partitions.size();
        //Todo: Partition logic here
        return 0;
    }

    public void close() {

    }

    public void configure(Map<String, ?> map) {

    }
}
```

Scala:

```
class CustomPartition extends Partitioner {
  override def close(): Unit = {}

  override def partition(topicName: String, key: scala.Any, keyBytes: Array[Byte], value: scala.Any, valueBytes: Array[Byte], cluster: Cluster): Int = {

    val partitions: util.List[PartitionInfo] = cluster.partitionsForTopic(topicName)

    val numPartitions: Int = partitions.size

    //TODO : your partition logic here
    0
  }

  override def configure(map: util.Map[String, _]): Unit = {}
}
```




### Additional producer configuration



There are other optional configuration properties available for Kafka
producer that can play an important role in performance, memory,
reliability, and so on:


-   `buffer.memory`: This is the amount of memory that
    producer can use to buffer a message that is waiting to be sent to
    the Kafka server.In simple terms, it is the total memory that is
    available to the Java producer to collect unsent messages. When this
    limit is reached, the producer will block the messages for
    `max.block.ms`before raising an exception. If your batch
    size is more, allocate more memory to the producer buffer.


Additionally, to avoid keeping records queued indefinitely, you can set
a timeout using `request.timeout.ms`. If this timeout expires
before a message can be successfully sent, then it will be removed from
the queue and an exception will be thrown.


-   `acks`: This configuration helps in configuring when
    producer will receive acknowledgment from the leader before
    considering that the message is committed successfully:
    
    -   `acks=0`: Producer will not wait for any
        acknowledgment from the server. Producer will not know if the
        message is lost at any point in time and is not committed by the
        leader broker. Note that no retry will happen in this case and
        the message will be completely lost. This can be used when you
        want to achieve very high throughput and when you don\'t care
        about potential message loss.
    -   `acks=1`: Producer will receive an acknowledgment as
        soon as the leader has written the message to its local log. If
        the leader fails to write the message to its log, producer will
        retry sending the data according to the retry policy set and
        avoid potential loss of messages. However, we can still have
        message loss in a scenario where the leader acknowledges to
        producer but does not replicate the message to the other broker
        before it goes down.
    -   `acks=all`: Producer will only receive acknowledgment
        when the leader has received acknowledgment for all the replicas
        successfully. This is a safe setting where we cannot lose data
        if the replica number is sufficient to avoid such failures.
        Remember, throughput will be lesser then the first two settings.
    
-   `batch.size`: This setting allows the producer to batch
    the messages based on the partition up to the configured amount of
    size. When the batch reaches the limit, all messages in the batch
    will be sent. However, it\'s not necessary that producer wait for
    the batch to be full. It sends the batch after a specific time
    interval without worrying about the number of messages in the batch.
-   `linger.ms`: This represents an amount of time that a
    producer should wait for additional messages before sending a
    current batch to the broker. Kafka producer waits for the batch to
    be full or the configured `linger.ms` time; if any
    condition is met, it will send the batch to brokers. Producer will
    wait till the configured amount of time in milliseconds for any
    additional messages to get added to the current batch.
-   `compression.type`: By default, producer sends
    uncompressed messages to brokers. When sending a single message, it
    will not make that much sense, but when we use batches, it\'s good
    to use compression to avoid network overhead and increase
    throughput. The available compressions are GZIP, Snappy, or LZ4.
    Remember that more batching would lead to better compression.
-   `retires`: If message sending fails, this
    represents the number of times producer will retry sending messages
    before it throws an exception. It is irrespective of reseeding a
    message after receiving an exception.
-   `max.in.flight.requests.per.connection`: This is the
    number of messages producer can send to brokers without waiting for
    a response. If you do not care about the order of the messages, then
    setting its value to more than 1 will increase throughput. However,
    ordering may change if you set it to more than 1 with retry enabled.
-   `partitioner.class`: If you want to use a custom
    partitioner for your producer, then this configuration allows you to
    set the partitioner class, which implements the partitioner
    interface.
-   `timeout.ms`: This is the amount of time a leader will
    wait for its followers to acknowledge the message before sending an
    error to producer. This setting will only help when `acks`
    is set to all.



Java Kafka producer example 
-------------------------------------------



We have covered different configurations and APIs in previous sections.
Let\'s start coding one simple Java producer, which will help you create
your own Kafka producer.

[**Prerequisite**]


-   IDE: We recommend that you use a Scala-supported IDE such as IDEA,
    NetBeans, or Eclipse. We have used JetBrains
    IDEA:<https://www.jetbrains.com/idea/download/>.
-   Build tool: Maven, Gradle, or others. We have used Maven to build
    our project.
-   `Pom.xml`: Add Kafka dependency to the `pom`
    file:


```
<dependency>
    <groupId>org.apache.kafka</groupId>
    <artifactId>kafka_2.11</artifactId>
    <version>0.10.0.0</version>
</dependency>
```

Java:

```
import java.util.Properties;
import java.util.concurrent.Future;
import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.apache.kafka.clients.producer.RecordMetadata;

public class DemoProducer {

    public static void main(final String[] args) {
        Properties producerProps = new Properties();
        producerProps.put("bootstrap.servers", "localhost:9092");
        producerProps.put("key.serializer", "org.apache.kafka.common.serialization.StringSerializer");
        producerProps.put("value.serializer", "org.apache.kafka.common.serialization.StringSerializer");
        producerProps.put("acks", "all");
        producerProps.put("retries", 1);
        producerProps.put("batch.size", 20000);
        producerProps.put("linger.ms", 1);
        producerProps.put("buffer.memory", 24568545);
        KafkaProducer<String, String> producer = new KafkaProducer<String, String>(producerProps);

        for (int i = 0; i < 2000; i++) {
           ProducerRecord data = new ProducerRecord<String, String>("test1", "Hello this is record " + i);
           Future<RecordMetadata> recordMetadata = producer.send(data);
        }
     producer.close();
    }
}
```

Scala:

```
import java.util.Properties
import org.apache.kafka.clients.producer._

object DemoProducer extends App {
  override def main(args: Array[String]): Unit = {

    val producerProps = new Properties()
    producerProps.put("bootstrap.servers", "localhost:9092")
    producerProps.put("key.serializer", "org.apache.kafka.common.serialization.StringSerializer")
    producerProps.put("value.serializer", "org.apache.kafka.common.serialization.StringSerializer")
    producerProps.put("client.id", "SampleProducer")
    producerProps.put("acks", "all")
    producerProps.put("retries", new Integer(1))
    producerProps.put("batch.size", new Integer(16384))
    producerProps.put("linger.ms", new Integer(1))
    producerProps.put("buffer.memory", new Integer(133554432))

    val producer = new KafkaProducer[String, String](producerProps)

    for (a <- 1 to 2000) {
      val record: ProducerRecord[String, String] = new ProducerRecord("test1", "Hello this is record"+a)
      producer.send(record);
    }

    producer.close()
  }

}
```

The preceding example is a simple Java producer where we are producing
string data without a key. We have also hardcoded the topic name, which
probably can be read through configuration file or as an command line
input. To understand producer, we have kept it simple. However, we will
see good examples in upcoming labs where we will follow good coding
practice.


Common messaging publishing patterns 
----------------------------------------------------



Applications may have different requirements of producer\--a producer
that does not care about acknowledgement for the message they have sent
or a producer that cares about acknowledgement but the order of messages
does not matter. We have different producer patterns that can be used
for application requirement. Let\'s discuss them one by one:


-   [**Fire-and-forget**]: In this pattern, producers only care
    about sending messages to Kafka queues. They really do not wait for
    any success or failure response from Kafka. Kafka is a highly
    available system and most of the time, messages would be delivered
    successfully. However, there is some risk of message loss in this
    pattern. This kind of pattern is useful when latency has to be
    minimized to the lowest level possible and one or two lost messages
    does not affect the overall system functionality. To use the fire
    and forget model with Kafka, you have to set producer
    `acks` config to `0`. The following image
    represents the Kafka-based fire and forget model:
    
    ![](./images/a4eb532f-09aa-4cfa-bc55-5df9cca3b3ef.png)
    


Kafka producer fire and forget model


-   [**One message transfers**]: In this pattern, producer
    sends one message at a time. It can do so in synchronous or
    asynchronous mode. In synchronous mode, producer sends the message
    and waits for a success or failure response before retrying the
    message or throwing the exception. In asynchronous mode, producer
    sends the message and receives the success or failure response as a
    callback function. The following image indicates this model. This
    kind of pattern is used for highly reliable systems where guaranteed
    delivery is the requirement. In this model, producer thread waits
    for response from Kafka. However, this does not mean that you cannot
    send multiple messages at a time. You can achieve that using
    multithreaded producer applications.



![](./images/607095c2-dc15-46a9-a69a-71360ae9ec14.png)

Kafka producer one message transfer model


-   [**Batching**]: In this pattern, producers send multiple
    records to the same partition in a batch. The amount of memory
    required by a batch and wait time before sending the batch to Kafka
    is controlled by producer configuration parameters. Batching
    improves performance with bigger network packets and disk operations
    of larger datasets in a sequential manner. Batching negates the
    efficiency issues with respect to random reads and writes on disks.
    All the data in one batch would be written in one sequential fashion
    on hard drives. The following image indicates the batching message
    model:



Best practices 
------------------------------



Hopefully, at this juncture, you are very well aware of Kafka Producer
APIs, their internal working, and common patterns of publishing messages
to different Kafka topics. This section covers some of the best
practices associated with Kafka producers. These best practices will
help you in making some of the design decisions for the producer
component.

Let\'s go through some of the most common best practices to design a
good producer application:


-   [**Data validation**]: One of the aspects that is usually
    forgotten while writing a producer system is to perform basic data
    validation tests on data that is to be written on the Kafka cluster.
    Some such examples could be conformity to schema, not null values
    for Key fields, and so on. By not doing data validation, you are
    risking breaking downstream consumer applications and affecting the
    load balancing of brokers as data may not be partitioned
    appropriately.
-   [**[**Exception handling**]**]: It is the sole
    responsibility of producer programs to decide on program flows with
    respect to exceptions. While writing a producer application, you
    should define different exception classes and as per your business
    requirements, decide on the actions that need to be taken. Clearly
    defining exceptions not only helps you in debugging but also in
    proper risk mitigation. For example, if you are using Kafka for
    critical applications such as fraud detection, then you should
    capture relevant exceptions to send e-mail alerts to the OPS team
    for immediate resolution.
-   [**Number of retries**]: In general, there are two types of
    errors that you get in your producer application. The first type are
    errors that producer can retry, such as network timeouts and leader
    not available. The second type are errors that need to be handled by
    producer programs as mentioned in the preceding section. Configuring
    the number of retries will help you in mitigating risks related to
    message losses due to Kafka cluster errors or network errors.
-   [**Number of bootstrap URLs**]: You should always have more
    than one broker listed in your bootstrap broker configuration of
    your producer program. This helps producers to adjust to failures
    because if one of the brokers is not available, producers try to use
    all the listed brokers until it finds the one it can connect to. An
    ideal scenario is that you should list all your brokers in the Kafka
    cluster to accommodate maximum broker connection failures. However,
    in case of very large clusters, you can choose a lesser number that
    can significantly represent your cluster brokers. You should be
    aware that the number of retries can affect your end-to-end latency
    and cause duplicate messages in your Kafka queues.
-   [**Avoid poor partitioning mechanism**]: Partitions are a
    unit of parallelism in Kafka. You should always choose an
    appropriate partitioning strategy to ensure that messages are
    distributed uniformly across all topic partitions. Poor partitioning
    strategy may lead to non-uniform message distribution and you would
    not be able to achieve the optimum parallelism out of your Kafka
    cluster. This is important in cases where you have chosen to use
    keys in your messages. In case you do not define keys, then producer
    will use the default round-robin mechanism to distribute your
    messages to partitions. If keys are available, then Kafka will hash
    the keys and based on the calculated hash code, it will assign the
    partitions. In a nutshell, you should choose your keys in a way that
    your message set uses all available partitions.
-   [**Temporary persistence of messages**]: For highly
    reliable systems, you should persist messages that are passing
    through your producer applications. Persistence could be on disk or
    in some kind of database. Persistence helps you replay messages in
    case of application failure or in case the Kafka cluster is
    unavailable due to some maintenance. This again, should be decided
    based on enterprise application requirements. You can have message
    purging techniques built in your producer applications for messages
    that are written to the Kafka cluster. This is generally used in
    conjunction with the acknowledgement feature that is available with
    Kafka Producer APIs. You should purge messages only when Kafka sends
    a success acknowledgement for a message set.
-   [**Avoid adding new partitions to existing topics**]: You
    should avoid adding partitions to existing topics when you are using
    key-based partitioning for message distribution. Adding new
    partitions would change the calculated hash code for each key as it
    takes the number of partitions as one of the inputs. You would end
    up having different partitions for the same key.


Summary 
-----------------------



This concludes our section on Kafka producers. This lab addresses
one of the key functionalities of Kafka message flows. The major
emphasis in this lab was for you to understand how Kafka producers
work at the logical level and how messages are passed from Kafka
producers to Kafka queues. This was covered in the [*Kafka
Internals*] section. This is an important section for you to
understand before you learn how to code with Kafka APIs. Unless you
understand the logical working of Kafka producers, you will not be able
to do justice to producer application technical designing.

We discussed Kafka Producer APIs and different components around it such
as custom practitioners. We gave both Java and Scala examples as both
languages are heavily used in enterprise applications. We would suggest
you try all those examples on your consoles and get a better grasp of
how Kafka producers work. Another important design consideration for
Kafka producer is data flows. We covered some commonly used patterns in
this lab. You should have a thorough understanding of these
patterns. We covered some of the common configuration parameters and
performance tuning steps. These will definitely help you in case you are
writing Kafka producer code for the first time.

In the end, we wanted to bring in some of the best practices of using
Kafka producers. These best practices will help you in scalable designs
and in avoiding some common pitfalls. Hopefully, by the end of this
lab, you have mastered the art of designing and coding Kafka
producers.

In the next lab, we will cover the internals of Kafka consumers,
consumer APIs, and common usage patterns. The next lab will give us
a good understanding of how messages produced by producer are being
consumed by different consumers irrespective of knowing their producer.



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
