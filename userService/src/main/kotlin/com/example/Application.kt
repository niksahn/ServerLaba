package com.example

import com.example.api.plugins.configureKoin
import com.example.api.plugins.configureRouting
import com.example.api.plugins.configureSerialization
import com.example.api.routing.configureUserRouting
import io.ktor.server.application.*
import io.ktor.server.engine.*
import io.ktor.server.netty.*
import io.ktor.server.metrics.micrometer.*
import io.ktor.server.routing.*
import io.ktor.server.response.*
import io.micrometer.prometheus.PrometheusConfig
import io.micrometer.prometheus.PrometheusMeterRegistry

fun main(args: Array<String>) {
    embeddedServer(
        Netty,
        port = 8070,
        module = Application::module
    ) .start(wait = true)}

fun Application.module() {
    val appMicrometerRegistry = PrometheusMeterRegistry(PrometheusConfig.DEFAULT)
    
    install(MicrometerMetrics) {
        registry = appMicrometerRegistry
    }
    
    configureSerialization()
    configureRouting()
    configureKoin()
    configureUserRouting()
    
    // Metrics endpoint
    routing {
        get("/metrics") {
            call.respond(appMicrometerRegistry.scrape())
        }
    }
}
