from kafka import KafkaConsumer, KafkaProducer, KafkaAdminClient
from kafka.admin.new_partitions import NewPartitions
import random
import socket

# producer = KafkaProducer(bootstrap_servers=['192.168.122.31:9092'])
# producer.send('reg', key=b'192.168.122.1', value=b'', partition=0)
# producer.flush()
# print(len(producer.partitions_for('reg')))

kafka_admin = KafkaAdminClient(bootstrap_servers='192.168.122.31:9092')
# result = kafka_admin.create_partitions({'reg': NewPartitions(10)})
# print(result)

print(kafka_admin.list_topics())
