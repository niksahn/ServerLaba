package com.brigada.laba1.data.messaging

import kotlinx.coroutines.flow.filterNotNull
import kotlinx.coroutines.flow.map
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json

class ApproveService(private val messager: Messaging) {
    fun subscribe() = messager.subscribe("film_approve_responses")
        .filterNotNull()
        .map { Json.decodeFromString<ApproveResponse>(it.message) }

    fun sendToApprove(filmId: String, userId: String) = messager.push(
        "film_approve_requests",
        Json.encodeToString(
            ApproveRequest.serializer(),
            ApproveRequest(filmId, userId)
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