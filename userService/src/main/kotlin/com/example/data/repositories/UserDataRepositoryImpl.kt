package com.example.data.repositories

import com.example.data.enetities.User
import com.example.data.enetities.UserDataRepository
import com.example.data.enetities.UserMongo
import com.mongodb.client.model.Filters.eq
import com.mongodb.client.model.Filters.`in`
import com.mongodb.client.model.Updates
import com.mongodb.kotlin.client.coroutine.MongoDatabase
import kotlinx.coroutines.flow.toList
import org.bson.types.ObjectId

class UserRepositoryMongo(database: MongoDatabase) : UserDataRepository {
    private val users = database.getCollection<UserMongo>(collectionName = "users")

    override suspend fun getUsers(): List<User> =
        users.find().limit(100).toList().map { it.toDomain() }

    override suspend fun getUsers(id: List<String>): List<User> =
        users.find(`in`("_id", id.map { ObjectId(it) })).toList().map { it.toDomain() }

    override suspend fun getUser(id: String): User? =
        users.find(eq("_id", ObjectId(id))).limit(1).toList().firstOrNull()?.toDomain()

    override suspend fun addUser(user: User): String? =
        users.insertOne(user.toMongo()).insertedId?.asObjectId()?.value?.toHexString()

    override suspend fun updateUser(user: User): Boolean {

        var updateParams = Updates.combine(
            Updates.set(User::name.name, user.name),
            Updates.set(User::watchedFilms.name, user.watchedFilms),
        )
        if (user.registeredObjects != 0L) updateParams =
            Updates.combine(updateParams, Updates.set(User::registeredObjects.name, user.registeredObjects))

        return try {
            users.updateOne(eq("_id", ObjectId(user.id)), updateParams).wasAcknowledged()
        } catch (e: Exception) {
            false
        }
    }

    override suspend fun deleteUser(id: String): Boolean =
        users.deleteOne(eq("_id", ObjectId(id))).wasAcknowledged()
}

internal fun User.toMongo() =
    UserMongo(if (id.isBlank()) ObjectId() else ObjectId(id), name, watchedFilms, registeredObjects)

internal fun UserMongo.toDomain() = User(id.toHexString(), name, watchedFilms, registeredObjects)
