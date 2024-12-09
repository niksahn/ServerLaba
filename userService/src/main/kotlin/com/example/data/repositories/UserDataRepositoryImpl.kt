package com.example.data.repositories

import com.example.api.models.IdentifyUserResponse
import com.example.data.enetities.Role
import com.example.data.enetities.User
import com.example.data.enetities.UserDataRepository
import com.example.data.enetities.UserMongo
import com.mongodb.client.model.Filters.*
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

    override suspend fun addUser(user: User): String? {
        val usersAlr = users.find(eq("name", user.name)).limit(1).toList()
        return if (usersAlr.isEmpty()) {
            users.insertOne(user.toMongo()).insertedId?.asObjectId()?.value?.toHexString()
        } else {
            null
        }
    }


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

    override suspend fun identifyUser(password: String, name: String): IdentifyUserResponse? =
        users.find(and(eq("password", password), eq("name", name)))
            .limit(1)
            .toList()
            .firstOrNull()
            ?.let {
                IdentifyUserResponse(
                    id = it.id.toHexString(),
                    role = Role.valueOf(it.role)
                )
            }
}

internal fun User.toMongo() =
    UserMongo(
        if (id.isBlank()) ObjectId() else ObjectId(id),
        name,
        password,
        role.toString(),
        watchedFilms,
        registeredObjects
    )

internal fun UserMongo.toDomain() =
    User(id.toHexString(), name, password, Role.valueOf(role), watchedFilms, registeredObjects)
