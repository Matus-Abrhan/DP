from kafka import KafkaConsumer

consumer = KafkaConsumer(
    'test test2', bootstrap_servers='192.168.122.31:9092', auto_offset_reset='earliest')
print(consumer.bootstrap_connected())
for msg in consumer:
    print(msg)
