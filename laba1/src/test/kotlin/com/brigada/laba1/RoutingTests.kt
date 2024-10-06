package com.brigada.laba1

import com.brigada.laba1.TestDataModule.testModule
import com.brigada.laba1.data.caching.InMemoryClient
import com.brigada.laba1.data.caching.RedisClient
import com.brigada.laba1.data.messaging.PrologMessaging
import com.brigada.laba1.data.messaging.RedisMessageClient
import com.brigada.laba1.data.network.KtorNetworkClient
import com.brigada.laba1.data.repository.films.CachedRepository
import com.brigada.laba1.data.repository.films.FilmsDataRepository
import com.brigada.laba1.data.repository.films.DataRepositoryMongo
import com.brigada.laba1.data.repository.users.UserDataRepository
import com.brigada.laba1.data.repository.users.UserRepositoryMongo
import com.brigada.laba1.data.utils.configurateClient
import com.brigada.laba1.data.utils.configureMongoDB
import com.brigada.laba1.domain.DataController
import com.brigada.laba1.domain.UserController
import com.brigada.laba1.plugins.configureHTTP
import com.brigada.laba1.plugins.configureSerialization
import com.brigada.laba1.routing.configureRouting
import com.brigada.laba1.routing.models.FilmResponse
import com.mongodb.kotlin.client.coroutine.MongoDatabase
import io.ktor.client.call.*
import io.ktor.client.request.*
import io.ktor.http.*
import io.ktor.server.application.*
import io.ktor.server.testing.*
import kotlinx.datetime.Clock
import kotlinx.serialization.builtins.ListSerializer
import kotlinx.serialization.json.Json
import org.koin.dsl.module
import org.koin.ktor.plugin.Koin
import org.koin.logger.slf4jLogger
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.time.DurationUnit

class RoutingTest {
    @Test
    fun testGetAllFilms() = testApplication {
        application { testModule() }
        client.get("/films").apply { assertEquals(HttpStatusCode.OK, status) }
    }

    @Test
    fun add10_000() = testApplication {
        application { testModule() }
        val start = client.get("/films/count").body<Int>()
        client.post("/test/10000").apply { assertEquals(HttpStatusCode.OK, status) }
        val end = client.get("/films/count").body<Int>()
        assertEquals(start + 10_000, end)
    }

    @Test
    fun add100_000() = testApplication {
        application { testModule() }
        val start = client.get("/films/count").body<Int>()
        client.post("/test/100000").apply { assertEquals(HttpStatusCode.OK, status) }
        val end = client.get("/films/count").body<Int>()
        assertEquals(start + 100_000, end)
    }

    @Test
    fun delete() = testApplication {
        application { testModule() }
        val start = client.get("/films/count").body<Int>()
        assert(start > 0)
        client.delete("/films").apply { assertEquals(HttpStatusCode.OK, status) }
        val end = client.get("/films/count").body<Int>()
        assertEquals(end, 0)
    }

    @Test
    fun checkCach() = testApplication {
        application { testModule() }
        val films = client.get("/films").apply { assertEquals(HttpStatusCode.OK, status) }.body<String>()
        val id = Json.decodeFromString(ListSerializer(FilmResponse.serializer()), films).first().id
        var startTime = Clock.System.now()
        var start = client.get("/films")
        var endTime = Clock.System.now()
        println("In database " + (endTime - startTime).toLong(DurationUnit.MILLISECONDS))
        startTime = Clock.System.now()
        start = client.get("/films")
        endTime = Clock.System.now()
        println("In Cach " + (endTime - startTime).toLong(DurationUnit.MILLISECONDS))
    }
}

object TestDataModule {
    private val data = module {
        single<FilmsDataRepository>(createdAtStart = true) {
            CachedRepository(
                repository = DataRepositoryMongo(configureMongoDB(configurateClient(), "Test")),
                redisClient = InMemoryClient()
            )
        }
        single<MongoDatabase>(createdAtStart = true) { configureMongoDB(configurateClient()) }
        single<UserDataRepository>(createdAtStart = true) { UserRepositoryMongo(get()) }
        single<UserController>(createdAtStart = true) { UserController(get(), get()) }
        single<DataController>(createdAtStart = true) { DataController(get()) }
    }

    fun Application.testModule() {
        configureSerialization()
        configureHTTP()
        configureRouting()
        configureTestKoin()
    }

    private fun Application.configureTestKoin() {
        install(Koin) {
            slf4jLogger()
            modules(data)
        }
    }
}
