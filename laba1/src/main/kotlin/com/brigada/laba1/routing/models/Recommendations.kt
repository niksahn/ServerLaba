package com.brigada.laba1.routing.models

import com.brigada.laba1.data.repository.users.User
import kotlinx.serialization.Serializable

@Serializable
data class RecommendationsResponse(
    val user: UserResponse?,
    val films: List<FilmResponse>
)
@Serializable
data class UserResponse(
    val id: String,
    val name: String
)

fun User.toResponse() =
    UserResponse(
        id = id,
        name = name
    )

@Serializable
data class RecommendationsRequest(
    val users: List<String>,
    val selectedFilmsCount: Int
)
