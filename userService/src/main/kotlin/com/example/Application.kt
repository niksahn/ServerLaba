package com.example

import com.example.api.plugins.configureKoin
import com.example.api.plugins.configureRouting
import com.example.api.plugins.configureSerialization
import com.example.api.routing.configureUserRouting
import io.ktor.server.application.*
import io.ktor.server.engine.*
import io.ktor.server.netty.*

fun main(args: Array<String>) {
    embeddedServer(
        Netty,
        port = 8070,
        module = Application::module
    ) .start(wait = true)}

fun Application.module() {
    configureSerialization()
    configureRouting()
    configureKoin()
    configureUserRouting()
}
