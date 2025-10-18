package com.brigada.laba1.routing.graphql.types

import com.apurebase.kgraphql.GraphQL
import com.brigada.laba1.domain.DataController
import com.brigada.laba1.domain.RecommendationController
import com.brigada.laba1.routing.models.AddingFIlm
import com.brigada.laba1.routing.models.FilmResponse
import com.brigada.laba1.routing.models.RecommendationsRequest
import com.brigada.laba1.routing.models.RecommendationsResponse
import com.brigada.laba1.routing.models.UpdateUserRequest
import com.brigada.laba1.routing.models.UserRequest
import com.brigada.laba1.routing.models.UserResponse
import io.ktor.http.HttpStatusCode
import io.ktor.server.application.Application
import io.ktor.server.application.install
import org.koin.ktor.ext.inject
import kotlin.getValue

fun Application.configureGraphQl() {
    install(GraphQL) {
        endpoint = "/"
        playground = true
        schema {
            val recController: RecommendationController by inject<RecommendationController>()

            val controller: DataController by inject<DataController>()

            configure {
                useDefaultPrettyPrinter = true
            }

            // Define scalar types for primitive types
            intScalar<Long> {
                serialize = { it.toInt() }
                deserialize = { it.toLong() }
            }
            

            
            // Define HttpStatusCode as string scalar
            stringScalar<HttpStatusCode> {
                serialize = { it.value.toString() }
                deserialize = { HttpStatusCode.fromValue(it.toInt()) }
            }

            // Register all model types
            type<FilmResponse>()
            type<AddingFIlm>()
            type<UserRequest>()
            type<UpdateUserRequest>()
            type<RecommendationsResponse>()
            type<UserResponse>()
            type<RecommendationsRequest>()

            // Film Queries
            query("films") {
                description = "Returns all films in the database"
                resolver { ->
                    controller.getAllData()
                }
            }

            query("film") {
                description = "Returns a single film by ID"
                resolver { id: String ->
                    controller.getById(id)
                }
            }

            query("filmsRandom") {
                description = "Returns random films by genre and size"
                resolver { genre: String?, size: Int ->
                    if (genre != null && genre.isNotEmpty()) {
                        controller.getRandom(genre, size)
                    } else {
                        controller.getRandom("", size)
                    }
                }
            }

            query("filmsCount") {
                description = "Returns the total number of films"
                resolver { ->
                    controller.count()
                }
            }

            query("filmsExist") {
                description = "Checks if films with given IDs exist"
                resolver { ids: List<String> ->
                    controller.exist(ids)
                }
            }

            // Recommendation Queries
            query("recommendations") {
                description = "Returns recommendations for a specific user"
                resolver { user: String ->
                    recController.getPrologRecommendation(user) ?: emptyList()
                }
            }

            // Film Mutations
            mutation("addFilm") {
                description = "Adds a new film to the database"
                resolver { film: AddingFIlm ->
                    controller.addFilm(film)
                }
            }

            mutation("updateFilm") {
                description = "Updates an existing film"
                resolver { film: FilmResponse ->
                    controller.update(film)
                }
            }

            mutation("deleteFilm") {
                description = "Deletes a film by ID"
                resolver { id: String ->
                    controller.deleteFilm(id)
                }
            }

            mutation("deleteAllFilms") {
                description = "Deletes all films from the database"
                resolver { ->
                    controller.deleteAll()
                }
            }

            mutation("testFilms") {
                description = "Generates test films for development purposes"
                resolver { number: Int ->
                    controller.test(number)
                    "Successfully generated $number test films"
                }
            }

            // Recommendation Mutations
            mutation("addRecommendationRequest") {
                description = "Adds a new recommendation request"
                resolver { request: RecommendationsRequest ->
                    recController.postProlog(request)
                }
            }
        }
    }
}