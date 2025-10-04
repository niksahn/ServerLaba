package com.brigada.laba1

import com.brigada.laba1.plugins.configureHTTP
import com.brigada.laba1.plugins.configureKoin
import com.brigada.laba1.plugins.configureSerialization
import com.brigada.laba1.routing.configureRecommendationRouting
import com.brigada.laba1.routing.configureRouting
import io.ktor.server.application.*
import io.ktor.server.engine.*
import io.ktor.server.netty.*
import io.ktor.server.metrics.micrometer.*
import io.ktor.server.routing.*
import io.ktor.server.response.*
import io.micrometer.prometheus.PrometheusConfig
import io.micrometer.prometheus.PrometheusMeterRegistry

fun main() {
    embeddedServer(
        Netty,
        port = 8080,
        module = Application::module
    ) .start(wait = true)
}

fun Application.module() {
    val appMicrometerRegistry = PrometheusMeterRegistry(PrometheusConfig.DEFAULT)
    
    install(MicrometerMetrics) {
        registry = appMicrometerRegistry
    }
    
    configureSerialization()
    configureHTTP()
    configureRouting()
    configureRecommendationRouting()
    configureKoin()
    
    // Metrics endpoint
    routing {
        get("/metrics") {
            call.respond(appMicrometerRegistry.scrape())
        }
    }
}
