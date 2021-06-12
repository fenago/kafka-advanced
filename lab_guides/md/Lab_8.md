<img align="right" src="./logo.png">


Lab 8. Building ETL Pipelines Using Kafka
------------------------------------------------------


In this lab, we will look into creating an ETL pipeline using these tools and Kafka Connect use cases and examples. In this lab, we will cover 
Kafka Connect in detail.


Using Kafka Connect 
--------------------

Kafka Connect provides us with various Connectors, and we can use the
Connectors based on our use case requirement. It also provides an API
that can be used to build your own Connector. We will go through a few
examples in this section.




Stop Confluent Platform
-------------------------

When you are done working with the local install, you can stop Confluent
Platform. Open new terminal and go to following directory:

`cd /headless/kafka-advanced/confluent-6.1.1/bin`


1.  Stop Confluent Platform using the Confluent CLI.
	
```
./confluent local services stop
```

2.  Destroy the data in the Confluent Platform instance with the
    confluent local destroy command.
	
```
./confluent local destroy
```



Summary  
------------------------


In this lab, we learned about Kafka Connect in detail. In the next lab, you will learn about Kafka Stream in detail, and we
will also see how we can use Kafka stream API to build our own streaming
application. We will explore the Kafka Stream API in detail and focus on
its advantages.
