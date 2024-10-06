package com.brigada.laba1.di

import com.brigada.laba1.data.caching.RedisClient
import com.brigada.laba1.data.messaging.RedisMessageClient
import com.brigada.laba1.data.messaging.PrologMessaging
import com.brigada.laba1.data.network.KtorNetworkClient
import com.brigada.laba1.data.repository.films.CachedRepository
import com.brigada.laba1.data.repository.films.FilmsDataRepository
import com.brigada.laba1.data.repository.films.DataRepositoryMongo
import com.brigada.laba1.data.repository.users.UserDataRepository
import com.brigada.laba1.data.repository.users.UserRepositoryMongo
import com.brigada.laba1.data.utils.configurateClient
import com.brigada.laba1.data.utils.configureMongoDB
import com.brigada.laba1.domain.DataController
import com.brigada.laba1.domain.RecommendationController
import com.brigada.laba1.domain.UserController
import com.mongodb.kotlin.client.coroutine.MongoDatabase
import org.koin.dsl.module

object DataModule {
    val data = module {
        single<FilmsDataRepository>(createdAtStart = true) {
            CachedRepository(
                repository = DataRepositoryMongo(get()),
                redisClient = RedisClient()
            )
        }
        single<MongoDatabase>(createdAtStart = true) { configureMongoDB(configurateClient()) }
        single<UserDataRepository>(createdAtStart = true) { UserRepositoryMongo(get()) }
        single<UserController>(createdAtStart = true) { UserController(get(), get()) }
        single<PrologMessaging>(createdAtStart = true) { PrologMessaging(RedisMessageClient()) }
        single<RecommendationController>(createdAtStart = true) {
            RecommendationController(
                get(),
                get(),
                get(),
                KtorNetworkClient()
            )
        }
        single<DataController>(createdAtStart = true) { DataController(get()) }
    }
}