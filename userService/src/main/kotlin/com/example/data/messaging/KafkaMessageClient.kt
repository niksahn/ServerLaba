package com.example.data.messaging

import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import org.apache.kafka.clients.producer.KafkaProducer
import org.apache.kafka.clients.producer.ProducerRecord
import org.apache.kafka.streams.KafkaStreams
import org.apache.kafka.streams.StreamsBuilder
import org.apache.kafka.streams.kstream.KStream
import java.util.*
//
val ProducerProps = Properties().apply {
    put("bootstrap.servers", "servers-kafka-1:9092")
    put("key.serializer", "org.apache.kafka.common.serialization.StringSerializer")
    put("value.serializer", "org.apache.kafka.common.serialization.StringSerializer")
}

val StreamsProps = Properties().apply {
    put("application.id", "user-service")
    put("bootstrap.servers", "servers-kafka-1:9092")
    put("default.key.serde", "org.apache.kafka.common.serialization.Serdes\$StringSerde")
    put("default.value.serde", "org.apache.kafka.common.serialization.Serdes\$StringSerde")
}

class KafkaStreamsMessageClient(
    producerProps: Properties = ProducerProps,
    private val streamsProps: Properties = StreamsProps
) : Messaging {
    private val producer = KafkaProducer<String, String>(producerProps)
    private val scope = CoroutineScope(Dispatchers.Default)

    override fun subscribe(channel: String): StateFlow<Messaging.Message?> {
        val flow = MutableStateFlow<Messaging.Message?>(null)
        scope.launch {
            val builder = StreamsBuilder()
            val stream: KStream<String, String> = builder.stream(channel)
            stream.foreach { _, value -> flow.tryEmit(Messaging.Message(channel, value)) }
            val streams = KafkaStreams(builder.build(), streamsProps)
            streams.start()
       }
        return flow.asStateFlow()
    }

    override fun push(channel: String, message: String) {
        scope.launch {
            val record: ProducerRecord<String, String> = ProducerRecord(channel, message)
            producer.send(record)
        }
    }
}
