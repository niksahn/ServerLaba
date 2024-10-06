package com.brigada.laba1.routing.models

import com.brigada.laba1.data.entities.Genre
import com.brigada.laba1.domain.Film
import kotlinx.serialization.Serializable

@Serializable
data class FilmResponse(
    val id: String,
    val genre: String,
    val description: String,
    val name: String,
    val link: String
)

fun Film.toResponse() = FilmResponse(id, genre.mapToString(), description, name, link)
fun FilmResponse.toData() = Film(id, genres.filterValues { it == genre }.keys.first(), description, name, link)

fun String.toGenre() = genres.filterValues { it == this }.keys.firstOrNull()
fun Genre.mapToString() = genres[this] ?: error("Can't find genre")


internal val genres = mapOf(
    Genre.HORROR to "Хоррор",
    Genre.DETECTIVE to "Детектив",
    Genre.COMEDY to "Комедия",
    Genre.FANTASY to "Фентези",
    Genre.SI_FI to "Научная фантастика"
)
