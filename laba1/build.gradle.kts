val kotlin_version: String by project
val logback_version: String by project
val koin_version = "3.5.6"
val mongo = "5.1.4"
val ktor_version = "3.0.0"

plugins {
    kotlin("jvm") version "2.0.21"
    id("io.ktor.plugin") version "3.0.0"
    id("org.jetbrains.kotlin.plugin.serialization") version "2.0.21"
}

group = "com.brigada.laba1"
version = "0.0.1"

application {
    mainClass.set("io.ktor.server.netty.EngineMain")

    val isDevelopment: Boolean = project.ext.has("development")
    applicationDefaultJvmArgs = listOf("-Dio.ktor.development=$isDevelopment")
}

repositories {
    mavenCentral()
}

dependencies {
    implementation("org.mongodb:mongodb-driver-kotlin-coroutine:$mongo")
    implementation("org.mongodb:bson-kotlin:$mongo")
    
    // Ktor dependencies with explicit versions
    implementation("io.ktor:ktor-server-swagger:$ktor_version")
    implementation("io.ktor:ktor-server-content-negotiation:$ktor_version")
    implementation("io.ktor:ktor-server-core:$ktor_version")
    implementation("io.ktor:ktor-client-core:$ktor_version")
    implementation("io.ktor:ktor-client-content-negotiation:$ktor_version")
    implementation("io.ktor:ktor-serialization-kotlinx-json:$ktor_version")
    implementation("io.ktor:ktor-server-netty:$ktor_version")
    implementation("io.ktor:ktor-client-java:$ktor_version")
    implementation("io.ktor:ktor-server-config-yaml:$ktor_version")
    // implementation("io.ktor:ktor-server-status-pages:$ktor_version")  // Temporarily disabled due to version conflict
    implementation("io.ktor:ktor-server-metrics-micrometer:$ktor_version")
    
    // Other dependencies
    implementation("ch.qos.logback:logback-classic:$logback_version")
    implementation("io.insert-koin:koin-ktor:$koin_version")
    implementation("io.insert-koin:koin-logger-slf4j:$koin_version")
    implementation("redis.clients:jedis:4.2.3")
    implementation("org.apache.kafka:kafka-streams:3.0.0")
    
    // Prometheus metrics
    implementation("io.micrometer:micrometer-registry-prometheus:1.11.5")
    
    // Test dependencies
    testImplementation("io.ktor:ktor-server-test-host:$ktor_version")
    testImplementation("org.jetbrains.kotlin:kotlin-test:$kotlin_version")
    testImplementation("io.mockk:mockk:1.12.0")
}
