package com.brigada.laba1.data.caching

import kotlinx.serialization.KSerializer
import kotlinx.serialization.json.Json
import redis.clients.jedis.Jedis

class RedisClient(
    private val jedis: Jedis = Jedis("redis", 6379)
) : CacheClient {
    override fun <T> get(key: String, type: KSerializer<T>): T? =
        jedis.get(key)?.let { Json.decodeFromString(type, it) }

    override fun <T> set(key: String, value: T, type: KSerializer<T>, expiryInSeconds: Long?) {
        Json.encodeToString(type, value)
            .let { stringValue ->
                expiryInSeconds
                    ?.let { jedis.setex(key, it, stringValue) }
                    ?: jedis.set(key, stringValue)
            }
    }

    override fun delete(key: String) {
        jedis.del(key)
    }

    override fun clear() {
        jedis.flushAll()
    }
}
