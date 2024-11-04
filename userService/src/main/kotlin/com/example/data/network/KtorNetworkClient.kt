package com.example.data.network

import io.ktor.client.*
import io.ktor.client.call.*
import io.ktor.client.engine.java.*
import io.ktor.client.plugins.contentnegotiation.*
import io.ktor.client.request.*
import io.ktor.http.*
import io.ktor.serialization.kotlinx.json.*
import kotlinx.serialization.json.Json

class KtorNetworkClient(private val client: HttpClient = configureClient()) {
    suspend fun checkFilmExist(ids: List<String>): List<String> {
        val request1 = client.get("http://servers-app-1:8080/film/exist") {
       //val request1 = client.get("http://localhost:8080/film/exist") {
            contentType(ContentType.Application.Json)
            setBody(ids)
        }
        return request1.body()
    }
}

fun configureClient() = HttpClient(Java) {
    install(ContentNegotiation) {
        json(Json { ignoreUnknownKeys = true })
    }
}
