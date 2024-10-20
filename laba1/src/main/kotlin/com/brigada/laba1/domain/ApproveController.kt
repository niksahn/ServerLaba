package com.brigada.laba1.domain

import com.brigada.laba1.data.messaging.ApproveResponse
import com.brigada.laba1.data.messaging.ApproveService
import com.brigada.laba1.data.repository.films.FilmsDataRepository
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

class ApproveController(private val approveService: ApproveService, private val dataRepository: FilmsDataRepository) {
    private val scope = CoroutineScope(Dispatchers.IO)

    init {
        scope.launch { approveService.subscribe().collect { approve(it) } }
    }

    private suspend fun approve(request: ApproveResponse) {
        dataRepository
            .getFilm(request.filmId)
            ?.let { dataRepository.changeFilm(it.copy(dateApprove = request.date)) }
    }
}