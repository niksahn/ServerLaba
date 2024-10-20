package com.example.api.routing

import com.example.api.controller.UserController
import com.example.api.models.UpdateUserFilmRequest
import com.example.api.models.UpdateUserRequest
import com.example.api.models.UserRequest
import io.ktor.http.*
import io.ktor.server.application.*
import io.ktor.server.request.*
import io.ktor.server.response.*
import io.ktor.server.routing.*
import org.koin.ktor.ext.inject

fun Application.configureUserRouting() {
    val controller: UserController by inject<UserController>()
    routing {
        post("user") {
            try {
                call.receive<UserRequest>()
                    .let { controller.addUser(it) }
                    ?.let { call.respond(HttpStatusCode.OK, it) }
                    ?: call.respond(HttpStatusCode.BadRequest)
            } catch (e: Exception) {
                call.respond(HttpStatusCode.BadRequest)
            }
        }

        post("user/films") {
            try {
                call.receive<UpdateUserFilmRequest>()
                    .let { controller.watchedFilm(it.watchedFilms, it.id) }
                    .takeIf { it }
                    ?.let { call.respond(HttpStatusCode.OK, it) }
                    ?: call.respond(HttpStatusCode.NotFound)
            } catch (e: Exception) {
                call.respond(HttpStatusCode.BadRequest)
            }
        }

        get("users") {
            call.respond(HttpStatusCode.OK, controller.getUsers())
        }

        get("user/{id}") {
            call.pathParameters["id"]
                ?.let { controller.getUser(it) }
                ?.let { call.respond(HttpStatusCode.OK, it) }
                ?: call.respond(HttpStatusCode.BadRequest)
        }

        get("users/selected") {
            call.receive<List<String>>()
                .let { controller.getUsers(it) }
                .let { call.respond(HttpStatusCode.OK, it) }
        }

        patch("user") {
            try {
                call.receive<UpdateUserRequest>()
                    .let { controller.updateUser(it) }
                    .takeIf { it }
                    ?.let { call.respond(HttpStatusCode.OK, it) }
                    ?: call.respond(HttpStatusCode.NotFound)
            } catch (e: Exception) {
                call.respond(HttpStatusCode.BadRequest)
            }
        }
    }
}