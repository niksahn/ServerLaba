package com.example.data.messaging

import kotlinx.coroutines.flow.StateFlow

interface Messaging {
    fun subscribe(channel: String): StateFlow<Message?>
    fun push(channel: String, message: String)
    data class Message(
        val channel: String,
        val message: String
    )
}
