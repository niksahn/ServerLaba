package com.brigada.laba1.domain

import com.brigada.laba1.data.entities.FilmMongo
import com.brigada.laba1.data.entities.Genre
import kotlinx.serialization.Serializable
import org.bson.types.ObjectId
import kotlin.random.Random

@Serializable
data class Film(
    val id: String,
    val genre: Genre,
    val description: String,
    val name: String,
    val link: String
) {
    companion object{
        fun random() = Film(
            "",
            Genre.entries.random(),
            Random.Default.nextBytes(10).toString(),
            Random.Default.nextBytes(10).toString(),
            "AAAAAAAAAAAAAAAAAAAAAAA"
        )
    }
}
fun FilmMongo.toDomain() = Film(id.toHexString(), genre, description, name, link)

fun Film.toMongo() = FilmMongo(if (id.isBlank()) ObjectId() else ObjectId(id),genre, description, name, link)
