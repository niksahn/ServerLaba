package com.example.api.controller

import com.example.api.models.UpdateUserRequest
import com.example.api.models.UserRequest
import com.example.api.models.toUser
import com.example.data.enetities.User
import com.example.data.enetities.UserDataRepository
import com.example.data.network.KtorNetworkClient

class UserController(
    private val ktorNetworkClient: KtorNetworkClient,
    private val userRepository: UserDataRepository
) {
    suspend fun addUser(userRequest: UserRequest) = userRepository.addUser(
        User(
            id = "",
            name = userRequest.name,
            watchedFilms = ktorNetworkClient.checkFilmExist(userRequest.watchedFilms),
            registeredObjects = 0
        )
    )

    suspend fun watchedFilm(filmIds: List<String>, userId: String): Boolean =
        userRepository.getUser(userId)
            ?.let {
                userRepository
                    .updateUser(
                        it.copy(
                            watchedFilms = it.watchedFilms.plus(ktorNetworkClient.checkFilmExist(filmIds))
                        )
                    )
            }
            ?: false

    suspend fun getUsers() = userRepository.getUsers()

    suspend fun getUsers(ids: List<String>) = userRepository.getUsers(ids)

    suspend fun updateUser(userRequest: UpdateUserRequest) = userRepository.updateUser(userRequest.toUser())

    suspend fun getUser(id: String) = userRepository.getUser(id)
}