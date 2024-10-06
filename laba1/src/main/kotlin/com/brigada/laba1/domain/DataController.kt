package com.brigada.laba1.domain

import com.brigada.laba1.data.messaging.PrologMessaging
import com.brigada.laba1.data.network.KtorNetworkClient
import com.brigada.laba1.data.network.PrologRecommendationData
import com.brigada.laba1.data.repository.films.FilmsDataRepository
import com.brigada.laba1.data.repository.users.User
import com.brigada.laba1.data.repository.users.UserDataRepository
import com.brigada.laba1.routing.models.*
import io.ktor.http.*
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.async

class DataController(private val dataRepository: FilmsDataRepository) {
    suspend fun getAllData() = dataRepository.getFilms().map { it.toResponse() }
    suspend fun addFilm(film: AddingFIlm) = dataRepository.addFilm(film.toData())
    suspend fun deleteFilm(id: String): Boolean = dataRepository.deleteFIlm(id)
    suspend fun getById(id: String) = dataRepository.getFilm(id)?.toResponse()
    suspend fun update(film: FilmResponse): Boolean = dataRepository.changeFilm(film.toData())
    fun genereRandom(number: Int): List<Film> = List(number) { Film.random() }
    suspend fun addRange(films: List<Film>) = dataRepository.addFilm(films)
    suspend fun test(number: Int) = addRange(genereRandom(number))
    suspend fun getRandom(genre: String, size: Int) =
        genre.toGenre()?.let { dataRepository.getRandom(it, size) }?.map { it.toResponse() }

    suspend fun deleteAll() = dataRepository.clear()
    suspend fun count() = dataRepository.count()
}

class RecommendationController(
    private val dataRepository: FilmsDataRepository,
    private val userRepository: UserDataRepository,
    private val prologMessaging: PrologMessaging,
    private val ktorClient: KtorNetworkClient
) {
    suspend fun getPrologRecommendations() =
        prologMessaging
            .getLastMessage()
            ?.groupBy { it.user }
            ?.mapValues { it.value.map { it.recomendation } }
            ?.mapValues { CoroutineScope(Dispatchers.IO).async { dataRepository.getFilms(it.value) } }
            ?.mapKeys { CoroutineScope(Dispatchers.IO).async { userRepository.getUser(it.key) } }
            ?.map {
                RecommendationsResponse(
                    user = it.key.await()?.toResponse(),
                    films = it.value.await().map { it.toResponse() }
                )
            }

    suspend fun getPrologRecommendation(user: String) =
        prologMessaging.getLastMessage()?.filter { it.user == user }
            ?.map { it.recomendation }
            ?.let { dataRepository.getFilms(it) }
            ?.map { it.toResponse() }

    suspend fun postProlog(request: RecommendationsRequest): HttpStatusCode {
        val scope = CoroutineScope(Dispatchers.IO)
        val users = scope.async { userRepository.getUsers(request.users) }
        val films = scope.async { dataRepository.getRandom(null, request.selectedFilmsCount) }
        val watchedFilms = scope.async { dataRepository.getFilms(users.await().flatMap { it.watchedFilms }) }
        val prequest = PrologRecommendationData(
            users = users.await().flatMap { user ->
                user.watchedFilms.map { film ->
                    PrologRecommendationData.User(user = user.id, movie = film)
                }
            },
            films = films.await().plus(watchedFilms.await())
                .map { PrologRecommendationData.Film(genre = it.genre, movie = it.id) }
        )
        return ktorClient.addPrologRecommendationData(prequest)
    }
}

class UserController(
    private val dataRepository: FilmsDataRepository,
    private val userRepository: UserDataRepository
) {
    suspend fun addUser(userRequest: UserRequest) = userRepository.addUser(
        User(
            id = "",
            name = userRequest.name,
            watchedFilms = dataRepository.exist(userRequest.watchedFilms)
        )
    )

    suspend fun watchedFilm(filmIds: List<String>, userId: String): Boolean =
        userRepository.getUser(userId)
            ?.let {
                userRepository
                    .updateUser(
                        it.copy(
                            watchedFilms = it.watchedFilms.plus(dataRepository.exist(filmIds))
                        )
                    )
            }
            ?: false
}
