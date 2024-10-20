package com.example.data.messaging

import kotlinx.coroutines.flow.filterNotNull
import kotlinx.coroutines.flow.map
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import java.time.LocalDateTime

class ApproveService(val messager: Messaging) {
    fun subscribe() = messager.subscribe("film_approve_requests")
        .filterNotNull()
        .map { Json.decodeFromString<ApproveRequest>(it.message) }

    fun approve(filmId: String) = messager.push(
        "film_approve_responses",
        Json.encodeToString(
            ApproveResponse.serializer(),
            ApproveResponse(filmId, LocalDateTime.now().toString())
        )
    )
}

@Serializable
data class ApproveRequest(
    val filmId: String,
    val userId: String
)

@Serializable
data class ApproveResponse(
    val filmId: String,
    val date: String
)