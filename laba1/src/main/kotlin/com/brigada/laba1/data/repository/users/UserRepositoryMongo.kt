package com.brigada.laba1.data.repository.users

import com.brigada.laba1.data.network.configureClient
import com.mongodb.client.model.Filters.eq
import com.mongodb.client.model.Filters.`in`
import com.mongodb.kotlin.client.coroutine.MongoDatabase
import io.ktor.client.*
import io.ktor.client.call.*
import io.ktor.client.request.*
import io.ktor.http.*
import kotlinx.coroutines.flow.toList
import org.bson.types.ObjectId

class UserRepositoryMongo(database: MongoDatabase) : UserDataRepository {
    private val users = database.getCollection<UserMongo>(collectionName = "users")

    override suspend fun getUsers(id: List<String>): List<User> =
        users.find(`in`("_id", id.map { ObjectId(it) })).toList().map { it.toDomain() }

    override suspend fun getUser(id: String): User? =
        users.find(eq("_id", ObjectId(id))).limit(1).toList().firstOrNull()?.toDomain()

}

class UserRepositoryKtor(private val client: HttpClient = configureClient()) : UserDataRepository {
    override suspend fun getUsers(id: List<String>): List<User> =
        client.get("http://servers-user-service-1:8070/users/selected") {
            setBody(id)
            contentType(ContentType.Application.Json)
        }.body<List<User>>()

    override suspend fun getUser(id: String): User? =
        client.get("http://servers-user-service-1:8070/user/$id").body<User?>()
}

internal fun UserMongo.toDomain() = User(id.toHexString(), name, watchedFilms)
