package com.brigada.laba1.plugins

import com.brigada.laba1.di.DataModule
import io.ktor.server.application.*
import org.koin.ktor.plugin.Koin
import org.koin.logger.slf4jLogger

fun Application.configureKoin() {
    install(Koin) {
        slf4jLogger()
        modules(DataModule.data)
    }
}