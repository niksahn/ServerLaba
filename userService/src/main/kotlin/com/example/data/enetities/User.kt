package com.example.data.enetities

import com.example.api.models.IdentifyUserResponse
import kotlinx.serialization.Serializable
import org.bson.codecs.pojo.annotations.BsonId
import org.bson.types.ObjectId

interface UserDataRepository {
    suspend fun getUsers(): List<User>
    suspend fun getUser(id: String): User?
    suspend fun getUsers(id: List<String>): List<User>
    suspend fun addUser(user: User): String?
    suspend fun updateUser(user: User): Boolean
    suspend fun deleteUser(id: String): Boolean
    suspend fun identifyUser(password: String, name: String): IdentifyUserResponse?
}

@Serializable
data class User(
    val id: String,
    val name: String,
    val password: String,
    val role: Role,
    val watchedFilms: List<String>,
    val registeredObjects: Long
)

@Serializable
enum class Role {
    ADMIN, USER, MODERATOR
}

data class UserMongo(
    @BsonId
    val id: ObjectId,
    val name: String,
    val password: String,
    val role: String,
    val watchedFilms: List<String>,
    val registeredObjects: Long
)