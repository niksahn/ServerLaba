package com.brigada.laba1.data.caching

import kotlinx.serialization.KSerializer

interface CacheClient {
    fun <T > get(key: String, type: KSerializer<T>): T?
    fun <T> set(key: String, value: T, type: KSerializer<T>, expiryInSeconds: Long? = null)
    fun delete(key: String)
    fun clear()
}
