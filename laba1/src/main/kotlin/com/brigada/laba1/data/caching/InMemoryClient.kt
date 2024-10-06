package com.brigada.laba1.data.caching

import kotlinx.serialization.KSerializer
import kotlinx.serialization.json.Json

class InMemoryClient : CacheClient {
    private val dataStore: MutableMap<String, String> = HashMap()

    override fun <T> get(key: String, type: KSerializer<T>): T? =
        dataStore[key]?.let { Json.decodeFromString(type, it) }

    override fun <T> set(key: String, value: T, type: KSerializer<T>, expiryInSeconds: Long?) {
        Json.encodeToString(type, value).let { stringValue ->
            dataStore[key] = stringValue
        }
    }

    override fun delete(key: String) {
        dataStore.remove(key)
    }

    override fun clear() {
        dataStore.clear()
    }
}