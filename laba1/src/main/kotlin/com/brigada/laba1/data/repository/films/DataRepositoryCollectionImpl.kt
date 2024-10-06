package com.brigada.laba1.data.repository.films

import com.brigada.laba1.data.entities.Genre
import com.brigada.laba1.domain.Film

class DataRepositoryCollectionImpl : FilmsDataRepository {
    private val films = mutableListOf(
        Film(
            id = "0",
            genre = Genre.SI_FI,
            description = "американский анимационный телесериал, созданный Дэном Хармоном и Джастином Ройландом," +
                    " премьера которого состоялась 2 декабря 2013 года в программном блоке " +
                    "Cartoon Network [adult swim].",
            name = "Рик и морти",
            link = "https://rick-i-morty.online/"
        ),
        Film("1", Genre.SI_FI, "фильм Нолана", "Начало", "https://rick-i-morty.online/"),
        Film("2", Genre.DETECTIVE, "детектив", "Шерлок", "https://rick-i-morty.online/"),
    )

    override suspend fun getFilms(): List<Film> = films
    override suspend fun getFilms(id: List<String>): List<Film> = films.filter { id.contains(it.id) }

    override suspend fun getFilm(id: String): Film? = films.firstOrNull { it.id == id }

    override suspend fun changeFilm(newFilmData: Film): Boolean {
        if (!films.any { it.id == newFilmData.id }) return false
        films.replaceAll { if (it.id == newFilmData.id) newFilmData else it }
        return true
    }

    override suspend fun addFilm(newFilmData: Film) =
        films.add(newFilmData.copy(id = (films.lastIndex + 1).toString())).let { (films.lastIndex + 1).toString() }

    override suspend fun addFilm(newFilmData: List<Film>) {
        films.addAll(newFilmData)
    }

    override suspend fun deleteFIlm(id: String): Boolean {
        if (!films.any { it.id == id }) return false
        films.removeAll { it.id == id }
        return true
    }

    override suspend fun getRandom(genre: Genre?, size: Int): List<Film> {
        return listOf()
    }

    override suspend fun clear(): Boolean {
        films.clear()
        return true
    }

    override suspend fun count(): Long = films.count().toLong()
    override suspend fun exist(ids: List<String>): List<String> = films.filter { ids.contains(it.id) }.map { it.id }

}