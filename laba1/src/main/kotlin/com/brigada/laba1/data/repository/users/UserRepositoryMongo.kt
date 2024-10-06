package com.brigada.laba1.data.repository.users

import com.mongodb.client.model.Filters.eq
import com.mongodb.client.model.Filters.`in`
import com.mongodb.client.model.Updates
import com.mongodb.kotlin.client.coroutine.MongoDatabase
import kotlinx.coroutines.flow.toList
import org.bson.types.ObjectId

class UserRepositoryMongo(database: MongoDatabase) : UserDataRepository {
    private val users = database.getCollection<UserMongo>(collectionName = "users")

    override suspend fun getUsers(): List<User> =
        users.find().toList().map { it.toDomain() }

    override suspend fun getUsers(id: List<String>): List<User> =
        users.find(`in`("_id", id.map { ObjectId(it) })).toList().map { it.toDomain() }

    override suspend fun getUser(id: String): User? =
        users.find(eq("_id", ObjectId(id))).limit(1).toList().firstOrNull()?.toDomain()

    override suspend fun addUser(user: User): String? =
        users.insertOne(user.toMongo()).insertedId?.asObjectId()?.value?.toHexString()


    override suspend fun updateUser(user: User): Boolean {
        val updateParams = Updates.combine(
            Updates.set(User::name.name, user.name),
            Updates.set(User::watchedFilms.name, user.watchedFilms),
        )
        return try {
            users.updateOne(eq("_id", ObjectId(user.id)), updateParams).wasAcknowledged()
        } catch (e: Exception) {
            false
        }
    }
}

internal fun User.toMongo() = UserMongo(if (id.isBlank()) ObjectId() else ObjectId(id), name, watchedFilms)
internal fun UserMongo.toDomain() = User(id.toHexString(), name, watchedFilms)
