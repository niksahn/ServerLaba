package com.brigada.laba1.data.utils

import com.mongodb.ConnectionString
import com.mongodb.MongoClientSettings
import com.mongodb.kotlin.client.coroutine.MongoClient
import com.mongodb.kotlin.client.coroutine.MongoDatabase
import kotlinx.coroutines.runBlocking
import org.bson.Document
import java.util.concurrent.TimeUnit

fun configurateClient(): MongoClient {
    val connectionString = System.getenv("MONGO_URL") ?: "mongodb://localhost:27017"

    val mongoClientSettings = MongoClientSettings.builder()
        .applyConnectionString(ConnectionString(connectionString))
        .applyToClusterSettings { it.serverSelectionTimeout(1000, TimeUnit.MINUTES) }
        .build()

    return MongoClient.create(mongoClientSettings)
}

fun configureMongoDB(client: MongoClient, dataBase: String = "laba"): MongoDatabase {
    val database = client.getDatabase(dataBase)
    runBlocking { println(database.runCommand(Document("ping", 1))) }
    return database
}