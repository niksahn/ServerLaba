package com.example.api.models

import com.example.data.enetities.Role
import com.example.data.enetities.User
import kotlinx.serialization.Serializable

@Serializable
data class UserRequest(
    val name: String,
    val password: String,
    val role: Role,
    val watchedFilms: List<String> = emptyList()
)

@Serializable
data class UpdateUserFilmRequest(
    val id: String,
    val watchedFilms: List<String> = emptyList()
)

@Serializable
data class UpdateUserRequest(
    val id: String,
    val watchedFilms: List<String>,
    val name: String,
)

@Serializable
data class IdentifyUserRequest(
    val name: String,
    val password: String
)

@Serializable
data class IdentifyUserResponse(
    val id: String,
    val role: Role
)

fun UpdateUserRequest.toUser() = User(
    id = id,
    watchedFilms = watchedFilms,
    name = name,
    registeredObjects = 0,
    password = "",
    role = Role.USER
)
