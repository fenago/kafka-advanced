

Lab 13. Streaming Application Design Considerations
----------------------------------------------------------------



Streaming is becoming an important pillar for organizations dealing with
big data nowadays. More and more organizations are leaning toward faster
actionable insights from the massive data pool that they have. They
understand that timely data and appropriate actions based on those
timely data insights has a long-lasting impact on profitability. Apart
from in-time actions, streaming opens channels to capture unbound,
massive amounts of data from different business units across an
organization.

Keeping these important benefits in mind, this lab focuses on
factors that one should keep in mind while designing any streaming
application. The end results of any such design are driven by
organization business goals. Controlling these factors in any streaming
application design helps achieving those defined goals appropriately. In
lieu of that, let\'s look at these factors one by one.

The following topics will be covered in this lab:


-   Latency and throughput
-   Data persistence
-   Data sources
-   Data lookups
-   Data formats
-   Data serialization
-   Level of parallelism
-   Data skews
-   Out-of-order events
-   Memory tuning


Latency and throughput 
--------------------------------------



One of the fundamental features of any streaming application is to
process inbound data from different sources and produce an outcome
instantaneously. Latency and throughput are the important initial
considerations for that desired feature. In other words, performance of
any streaming application is measured in terms of latency and
throughput.

The expectation from any streaming application is to produce outcomes as
soon as possible and to handle a high rate of incoming streams. Both
factors have an impact on the choice of technology and hardware capacity
to be used in streaming solutions. Before we understand their impact in
detail, let\'s first understand the meanings of both terms.


### Note

Latency is defined as the unit of time (in milliseconds) taken by the
streaming application in processing an event or group of events and
producing an output after the events have been received by it. Latency
can be expressed in terms of average latency, best case latency, or
worst case latency. Sometimes, it is also represented as the percentage
of total events received in each time window.


For example, it can be defined as 2 ms for 85% of messages that are
received in the last 24 hours.


### Note

Throughput is defined as the number of outcomes produced by streaming
applications at each unit of time. Basically, throughput derives the
number of events that can be processed by a streaming application at
each unit of time.


In a streaming application design, you usually consider the maximum
throughput that the system can handle, keeping end-to-end latency within
the agreed upon SLAs. When the system is in a state of maximum
throughput, all system resources are fully utilized and beyond this,
events will be in the wait state till resources are freed.

Now that we are clear with the definitions of both latency and
throughput, it can be easily understood that both are not independent of
each other.


### Note

High latency means more time to process an event and produce an output.
This also means that for an event, system resources are occupied for a
longer duration of time and hence, at a time, lesser number of parallel
events can be processed. Hence, if system capacity is limited, high
latency will result in less throughput.


There are multiple factors that should be kept in mind while striking a
balance between the throughput and latency of your streaming
application. One such factor is the load distribution across multiple
nodes. Load distribution helps in utilizing each system resource
optimally and ensuring end-to-end low latency per node.

Most of the stream processing engines have such a mechanism built-in by
default. However, at times, you must ensure that it avoid too much data
shuffling at runtime and data partitions are defined appropriately. To
achieve the desired throughput and frequency, you must perform capacity
planning of your cluster accordingly.


### Note

The number of CPUs, RAM, page cache, and so on are some of the important
factors that affect your streaming application performance. To keep your
streaming application performance at the desired level, it is imperative
that you program your streaming application appropriately. Choice of
program constructs and algorithms affect garbage collection, data
shuffling, and so on. Lastly, factors such as network bandwidth also
affect your latency and throughput.



Data and state persistence 
------------------------------------------



Data integrity, safety, and availability are some of the key
requirements of any successful streaming application solution. If you
give these factors a thought, you will understand that to ensure
integrity, safety, and availability, persistence plays an important
role. For example, it is absolutely essential for any streaming solution
to persists its state. We often call it checkpointing. Checkpointing
enables streaming applications to persist their states over a period of
time and ensures recovery in case of failures. State persistence also
ensures strong consistency, which is essential for data correctness and
exactly-once message delivery semantics.

Now you must have understood why persisting state is important. Another
aspect of persistence is the outcomes of data processing or raw
unprocessed events. This serves a two-fold purpose. It gives us an
opportunity to replay messages and to compare the current data with
historical data. It also gives us the ability to retry messages in case
of failures. It also helps us handle back-pressure on the source system
in case of peak throughput time periods.


### Note

Careful thought must be given to the storage medium used to persist the
data. Some factors that really drive a storage medium for streaming
applications are low latency read/write, hardware fault tolerance,
horizontal scalability, and optimized data transfer protocols with
support for both synchronous and asynchronous operations.



Data sources 
----------------------------



One of the fundamental requirements for any streaming application is
that the sources of data should have the ability to produce unbound data
in terms of streams. Streaming systems are built for unbound data
streams. If source systems have the support for such kinds of data
streams, then streaming solutions are the way to go, but if they do not
have support for data streams, then either you must build or use
prebuilt custom components that build data streams out of those data
sources or go for batch-oriented non-streaming-based solutions.


### Note

Either way, the key takeaway is that streaming solutions should have
data stream producing data sources. This is one of the key design
decisions in any streaming application. Any streaming solution or design
should ensure that continuous unbound data streams are input to your
stream processing engines.



External data lookups 
-------------------------------------



The first question that must be in your mind is why we need external
data lookups in the stream processing pipeline. The answer is that
sometimes you need to perform operations such as enrichment, data
validation, or data filtering on incoming events based on some
frequently changing external system data. However, in the streaming
design context, these data lookups pose certain challenges. These data
lookups may result in increased end-to-end latency as there will be
frequent calls to external systems. You cannot hold all the external
reference data in-memory as these external datasets are too big to fit
in-memory. They also change too frequently, which makes refreshing
memory difficult. If these external systems are down, then they will
become a bottleneck for streaming solutions.

Keeping these challenges in mind, there are three important factors
while designing solutions involving external data lookups. They are
performance, scalability, and fault tolerance. Of course, you can
achieve all of these and there are always trade-offs between the three. 


### Note

One criterion of data lookups is that they should have minimized impact
on event processing time. Even a response time in seconds is not
acceptable, keeping in mind the millisecond response time of stream
processing solutions. To comply with such requirements, some solutions
use caching systems such as Redis to cache all the external data.
Streaming systems use Redis for data lookups. You also need to keep
network latency in mind. Hence, the Redis cluster is generally
co-deployed with your streaming solutions. By caching everything, you
have chosen performance over fault tolerance and scalability.



Data formats 
----------------------------



One of the important characteristics of any streaming solution is that
it serves as an integration platform as well. It collects events from
varied sources and performs processing on these different events to
produce the desired outcomes. One of the pertinent problems with such
integration platforms is different data formats. Each type of source has
its own format. Some support XML formats and some support JSON or Avro
formats. It is difficult for you to design a solution catering to all
formats. Moreover, as more and more data sources get added, you need to
add support for data formats supported by the newly added source. This
is obviously a maintenance nightmare and buggy.

Ideally, your streaming solution should support one data format. Events
should be in the key/value model. The data format for these key/value
events should be one agreed-on format. You should pick one single data
format for your application. Choosing a single data format and ensuring
that all data sources and integration points comply to it is important
while designing and implementing streaming solutions.

One of the common solutions that is employed for one common data format
is to build a message format conversion layer before data is ingested
for stream processing. This message conversion layer will have REST APIs
exposed to different data sources. These data sources push events in
their respective formats to this conversion layer using REST APIs and
later, it gets converted to a single common data format. The converted
events will be pushed to stream processing. Sometimes, this layer is
also utilized to perform some basic data validation on incoming events.
In a nutshell, you should have data format conversion separate from
stream processing logic.



Data serialization 
----------------------------------



Almost all the streaming technology of your choice supports
serialization. However, key for any streaming application performance is
the serialization technique used. If the serialization is slow, then it
will affect your streaming application latency.

Moreover, if you are integrating with an old legacy system, it might be
that the serialization of your choice is not supported. Key factors in
choosing any serialization technique for your streaming application
should be the amount of CPU cycles required, time for
serialization/deserialization, and support from all integrated systems.



Level of parallelism 
------------------------------------



Any stream processing engine of your choice has ways to tune stream
processing parallelism. You should always give a thought to the level of
parallelism required for your application. A key point here is that you
should utilize your existing cluster to its maximum potential to achieve
low latency and high throughput. The default parameters may not be
appropriate as per your current cluster capacity. Hence, while designing
your cluster, you should always come up with the desired level of
parallelism to achieve your latency and throughput SLAs. Moreover, most
of the engines are limited by their automatic ability to determine the
optimal number of parallelism.

Let's take Spark\'s processing engine as an example and see how
parallelism can be tuned on that. In very simple terms, to increase
parallelism, you must increase the number of parallel executing tasks.
In Spark, each task runs on one data partition.


### Note

So if you want to increase the number of parallel tasks, you should
increase the number of data partitions. To achieve this, you can
repartition the data with the desired number of partitions or we can
increase the number of input splits from the source. Level of
parallelism also depends on the number of cores available in your
cluster. Ideally, you should plan your level of parallelism with two or
three tasks per CPU core.



Out-of-order events 
-----------------------------------



This is one of the key problems with any unbound data stream. Sometimes
an event arrives so late that events that should have been processed
after that out of order event are processed first. Events from varied
remote discrete sources may be produced at the same time and, due to
network latency or some other problem, some of them are delayed. The
challenge with out-of-order events is that as they come very late,
processing them involves data lookups on relevant datasets.

Moreover, it is very difficult to determine the conditions that help you
decide if an event is an out-of-order event. In other words, it is
difficult to determine if all events in each window have been received
or not. Moreover, processing these out-of-order events poses risks of
resource contentions. Other impacts could be increase in latency and
overall system performance degradation.

Keeping these challenges in mind, factors such as latency, easy
maintenance, and accurate results play an important role in processing
out-of-order events. Depending on enterprise requirements, you can drop
these events. In case of event drops, your latency is not affected and
you do not have to manage additional processing components. However, it
does affect the accuracy of processing outcomes.

Another option is to wait and process it when all events in each window
are received. In this case, your latency will take a hit and you must
maintain additional software components. Another one of the commonly
applied techniques is to process such data events at the end of the day
using batch processing. In this way, factors such as latency are moot.
However, there will be a delay in getting accurate results.



Message processing semantics 
--------------------------------------------



Exactly-once delivery is the holy grail of streaming analytics. Having
duplicates of events processed in a streaming job is inconvenient and
often undesirable, depending on the nature of the application. For
example, if billing applications miss an event or process an event
twice, they could lose revenue or overcharge customers. Guaranteeing
that such scenarios never happen is difficult; any project seeking such
a property will need to make some choices with respect to availability
and consistency. One main difficulty stems from the fact that a
streaming pipeline might have multiple stages, and exactly-once delivery
needs to happen at each stage. Another difficulty is that intermediate
computations could potentially affect the final computation. Once
results are exposed, retracting them causes problems.

It is useful to provide exactly-once guarantees because many situations
require them. For example, in financial examples such as credit card
transactions, unintentionally processing an event twice is bad. Spark
Streaming, Flink, and Apex all guarantee exactly-once processing. Storm
works with at least-once delivery. With the use of an extension called
[**Trident**], it is possible to reach exactly-once behavior
with Storm, but this may cause some reduction in performance.

De-duplication is one way of preventing multiple execution of an
operation and achieving exactly-once processing semantics.
De-duplication is achievable if the application action is a database
update. We can consider some other action such as a web services call.



Summary 
-----------------------



At the end of this lab, you should have a clear understanding of
various design considerations for streaming applications. Our goal with
this lab was to ensure that you have understood various complex
aspects of a streaming application design.

Although the aspects may vary from project to project, based on our
industry experience, we feel that these are some of the common aspects
that you will end up considering in any streaming application design.
For example, you cannot design any streaming application without
defining SLAs around latency and throughput.

You can use these principals irrespective of your choice of technology
for stream processing\--be it micro-batch Spark streaming applications
or real-time Storm/Heron stream processing applications. They are
technology agnostic. However, the way they can be achieved varies from
technology to technology. With this, we conclude this lab and
hopefully, you will be able to apply these principles to your enterprise
applications.
