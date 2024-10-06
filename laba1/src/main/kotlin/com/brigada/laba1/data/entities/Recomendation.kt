package com.brigada.laba1.data.entities

import kotlinx.serialization.Serializable

@Serializable
data class Recommendation(
    val recomendation: String,
    val user: String
)