package com.brigada.laba1.data.messaging

import com.brigada.laba1.data.caching.CacheClient
import com.brigada.laba1.data.entities.Recommendation
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import kotlinx.serialization.builtins.ListSerializer
import kotlinx.serialization.builtins.serializer
import kotlinx.serialization.json.Json
import redis.clients.jedis.JedisPooled
import redis.clients.jedis.JedisPubSub

class RedisMessageClient : Messaging {
    private val jedis: JedisPooled = JedisPooled("redis", 6379)

    override fun subscribe(channel: String): StateFlow<Messaging.Message?> {
        val flow = MutableStateFlow<Messaging.Message?>(null)
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

    override fun push(channel: String, message: String) {
        jedis.publish(channel, message)
    }
}

class PrologMessaging(
    private val client: Messaging,
    private val cacheClient: CacheClient
) {
    private val recommendationChannel = client.subscribe("recommendations")

    init {
        CoroutineScope(Dispatchers.IO).launch {
            recommendationChannel
                .filterNotNull()
                .map { Json.decodeFromString(ListSerializer(Recommendation.serializer()), it.message) }
                .collect {
                    it.onEach { recommendation ->
                        cacheClient.set(
                            recommendation.user,
                            value = recommendation.recomendation,
                            type = String.serializer()
                        )
                    }
                }
        }
    }

    fun getUserRecommendation(id: String) = cacheClient.get(id, ListSerializer(Recommendation.serializer()))

    fun getLastMessage() = recommendationChannel
            .value
            ?.message
            ?.let { Json.decodeFromString(ListSerializer(Recommendation.serializer()), it) }
}
