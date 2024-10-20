package com.example.di

import com.example.api.controller.ApproveController
import com.example.api.controller.UserController
import com.example.data.enetities.UserDataRepository
import com.example.data.messaging.ApproveService
import com.example.data.messaging.KafkaStreamsMessageClient
import com.example.data.messaging.Messaging
import com.example.data.network.KtorNetworkClient
import com.example.data.repositories.UserRepositoryMongo
import com.mongodb.ConnectionString
import com.mongodb.MongoClientSettings
import com.mongodb.kotlin.client.coroutine.MongoClient
import com.mongodb.kotlin.client.coroutine.MongoDatabase
import kotlinx.coroutines.runBlocking
import org.bson.Document
import org.koin.dsl.module
import java.util.concurrent.TimeUnit

object DataModule {
    val data = module {
        single<KtorNetworkClient>(createdAtStart = true) { KtorNetworkClient() }
        single<MongoDatabase>(createdAtStart = true) { configureMongoDB(configurateClient()) }
        single<UserDataRepository>(createdAtStart = true) { UserRepositoryMongo(get()) }
        single<Messaging> { KafkaStreamsMessageClient() }
        single<ApproveController>(createdAtStart = true) { ApproveController(ApproveService(get()), get()) }
        single<UserController>(createdAtStart = true) { UserController(get(), get()) }
    }
}

fun configurateClient(): MongoClient {
    val connectionString = System.getenv("MONGO_URL") ?: "mongodb://localhost:27017"

    val mongoClientSettings = MongoClientSettings.builder()
        .applyConnectionString(ConnectionString(connectionString))
        .applyToClusterSettings { it.serverSelectionTimeout(1000, TimeUnit.MINUTES) }
        .build()

    return MongoClient.create(mongoClientSettings)
}

fun configureMongoDB(client: MongoClient, dataBase: String = "users"): MongoDatabase {
    val database = client.getDatabase(dataBase)
    runBlocking { println(database.runCommand(Document("ping", 1))) }
    return database
}
