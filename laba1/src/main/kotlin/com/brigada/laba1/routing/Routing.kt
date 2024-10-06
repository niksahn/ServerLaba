package com.brigada.laba1.routing

import com.brigada.laba1.domain.DataController
import com.brigada.laba1.domain.RecommendationController
import com.brigada.laba1.domain.UserController
import com.brigada.laba1.routing.models.*
import io.ktor.http.*
import io.ktor.server.application.*
import io.ktor.server.request.*
import io.ktor.server.response.*
import io.ktor.server.routing.*
import org.koin.ktor.ext.inject

fun Application.configureRouting() {
    val controller: DataController by inject<DataController>()
    routing {
        get("/films") {
            call.respond(HttpStatusCode.OK, controller.getAllData())
        }

        get("/film/{id}") {
            call.pathParameters["id"]
                ?.let { controller.getById(it) }
                ?.let { call.respond(HttpStatusCode.OK, it) }
                ?: call.respond(HttpStatusCode.BadRequest)
        }

        post("/film/update") {
            call.receive<FilmResponse>()
                .let { controller.update(it) }
                .let { if (it) call.respond(HttpStatusCode.OK) else call.respond(HttpStatusCode.BadRequest) }
        }

        post("/film/add") {
            try {
                call.receive<AddingFIlm>()
                    .let { controller.addFilm(it) }
                    ?.let { call.respond(HttpStatusCode.OK, it) }
                    ?: call.respond(HttpStatusCode.BadRequest)
            } catch (e: Exception) {
                call.respond(HttpStatusCode.BadRequest)
            }
        }

        delete("/film/{id}") {
            call.pathParameters["id"]
                ?.let { controller.deleteFilm(it) }
                ?.let { if (it) call.respond(HttpStatusCode.OK) else call.respond(HttpStatusCode.BadRequest) }
        }

        post("/test/{number}") {
            call.pathParameters["number"]
                ?.toIntOrNull()
                ?.let { controller.test(it) }
                ?.let { call.respond(HttpStatusCode.OK) }
                ?: call.respond(HttpStatusCode.BadRequest)
        }

        get("/films/random") {
            call.request.queryParameters["size"]
                ?.toIntOrNull()
                ?.let { size ->
                    call.request.queryParameters["genre"]
                        ?.let {
                            it.let { controller.getRandom(it, size) }
                                ?.let { call.respond(HttpStatusCode.OK, it) }
                                ?: call.respond(HttpStatusCode.NotFound)
                        }
                }
                ?: call.respond(HttpStatusCode.BadRequest)
        }

        delete("/films") {
            if (controller.deleteAll()) call.respond(HttpStatusCode.OK) else call.respond(HttpStatusCode.InternalServerError)
        }

        get("/films/count") {
            call.respond(HttpStatusCode.OK, controller.count())
        }
    }
}

fun Application.configureRecommendationRouting(){
    val controller: RecommendationController by inject<RecommendationController>()
    routing {
        get("/recommendations/{user}") {
            call.pathParameters["user"]
                ?.let { controller.getPrologRecommendation(it) }
                ?.let { call.respond(HttpStatusCode.OK, it) }
                ?: call.respond(HttpStatusCode.BadRequest)
        }

        get("/recommendations") {
            controller.getPrologRecommendations()
                .let { call.respond(HttpStatusCode.OK, it ?: "null") }
        }

        post("/recommendations/addRequest") {
            call.receive<RecommendationsRequest>()
                .let { controller.postProlog(it) }
                .let { call.respond(it) }
        }
    }
}

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
                call.receive<UpdateUserRequest>()
                    .let { controller.watchedFilm(it.watchedFilms, it.id) }
                    .takeIf { it }
                    ?.let { call.respond(HttpStatusCode.OK, it) }
                    ?: call.respond(HttpStatusCode.NotFound)
            } catch (e: Exception) {
                call.respond(HttpStatusCode.BadRequest)
            }
        }
    }
}
