package com.brigada.laba1.data.messaging

import com.brigada.laba1.data.entities.Recommendation
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import kotlinx.serialization.builtins.ListSerializer
import kotlinx.serialization.json.Json
import redis.clients.jedis.JedisPooled
import redis.clients.jedis.JedisPubSub

class RedisMessageClient : Messaging {
    private val flow = MutableStateFlow<Messaging.Message?>(null)
    private val jedis: JedisPooled = JedisPooled("redis", 6379)

    override fun subscribe(channel: String): StateFlow<Messaging.Message?> {
        val subscriber = object : JedisPubSub() {
            override fun onMessage(channel: String, message: String) {
                flow.tryEmit(Messaging.Message(channel, message))
            }
        }
        CoroutineScope(Dispatchers.IO).launch {
            jedis.subscribe(subscriber, channel)
        }
        return flow.asStateFlow()
    }
}

class PrologMessaging(
    private val client: Messaging
) {
    private val recommendationChannel = client.subscribe("recommendations")
    fun getLastMessage() =
        recommendationChannel
            .value
            ?.message
            ?.let { Json.decodeFromString(ListSerializer(Recommendation.serializer()), it) }
}

interface Messaging {
    fun subscribe(channel: String): StateFlow<Message?>
    data class Message(
        val channel: String,
        val message: String
    )
}
