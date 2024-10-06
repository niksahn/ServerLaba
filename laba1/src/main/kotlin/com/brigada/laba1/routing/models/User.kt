package com.brigada.laba1.routing.models

import kotlinx.serialization.Serializable

@Serializable
data class UserRequest(
    val name: String,
    val watchedFilms: List<String> = emptyList()
)

@Serializable
data class UpdateUserRequest(
    val id: String,
    val watchedFilms: List<String> = emptyList()
)
