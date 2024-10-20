val mongo = "5.1.4"

val kotlin_version: String by project
val logback_version: String by project
val koin_version = "3.5.6"

plugins {
    kotlin("jvm") version "2.0.21"
    id("io.ktor.plugin") version "3.0.0"
    id("org.jetbrains.kotlin.plugin.serialization") version "2.0.21"
}

group = "com.example"
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

    implementation ("io.insert-koin:koin-ktor:$koin_version")
    implementation("io.ktor:ktor-server-status-pages")
    implementation ("io.insert-koin:koin-logger-slf4j:$koin_version")

    implementation("org.apache.kafka:kafka-streams:3.0.0")

    implementation("io.ktor:ktor-client-java")
    implementation("io.ktor:ktor-client-core-jvm")
    implementation("io.ktor:ktor-client-content-negotiation-jvm")

    implementation("io.ktor:ktor-server-content-negotiation-jvm")
    implementation("io.ktor:ktor-server-core-jvm")
    implementation("io.ktor:ktor-serialization-kotlinx-json-jvm")
    implementation("io.ktor:ktor-server-webjars-jvm")
    implementation("io.ktor:ktor-server-netty-jvm")
    implementation("ch.qos.logback:logback-classic:$logback_version")
    implementation("io.ktor:ktor-server-config-yaml")
    testImplementation("io.ktor:ktor-server-test-host-jvm")
    testImplementation("org.jetbrains.kotlin:kotlin-test-junit:$kotlin_version")
    implementation("io.ktor:ktor-server-swagger")
}
