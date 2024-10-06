package com.brigada.laba1.data.entities

import org.bson.codecs.pojo.annotations.BsonId
import org.bson.types.ObjectId

data class FilmMongo(
    @BsonId
    val id: ObjectId,
    val genre: Genre,
    val description: String,
    val name: String,
    val link: String
)
