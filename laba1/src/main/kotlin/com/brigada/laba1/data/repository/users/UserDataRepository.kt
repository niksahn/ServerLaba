package com.brigada.laba1.data.repository.users

import kotlinx.serialization.Serializable
import org.bson.codecs.pojo.annotations.BsonId
import org.bson.types.ObjectId

interface UserDataRepository {
    suspend fun getUsers(): List<User>
    suspend fun getUser(id: String): User?
    suspend fun getUsers(id: List<String>): List<User>
    suspend fun addUser(user: User) : String?
    suspend fun updateUser(user: User): Boolean
}

@Serializable
data class User(
    val id: String,
    val name: String,
    val watchedFilms: List<String>,
)

data class UserMongo(
    @BsonId
    val id: ObjectId,
    val name: String,
    val watchedFilms: List<String>,
)