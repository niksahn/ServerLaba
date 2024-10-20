package com.example.api.controller

import com.example.data.enetities.UserDataRepository
import com.example.data.messaging.ApproveRequest
import com.example.data.messaging.ApproveService
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

class ApproveController(
    val approveService: ApproveService,
    val userRepositoryMongo: UserDataRepository
) {
    private val scope = CoroutineScope(Dispatchers.IO)

    init {
        scope.launch {
            approveService
                .subscribe()
                .collect { approve(it) }
        }
    }

    private suspend fun approve(request: ApproveRequest) {
        userRepositoryMongo
            .getUser(request.userId)
            ?.let { userRepositoryMongo.updateUser(it.copy(registeredObjects = it.registeredObjects + 1)) }
            ?.let { if (it) approveService.approve(request.filmId) }
    }
}