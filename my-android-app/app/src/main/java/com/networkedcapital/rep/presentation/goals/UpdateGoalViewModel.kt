package com.networkedcapital.rep.presentation.goals

import android.content.Context
import android.net.Uri
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.networkedcapital.rep.data.api.GoalApiService
import com.networkedcapital.rep.data.api.UpdateFilledQuotaRequest
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import okhttp3.MediaType.Companion.toMediaTypeOrNull
import okhttp3.MultipartBody
import okhttp3.RequestBody.Companion.toRequestBody
import javax.inject.Inject

data class UpdateGoalUiState(
    val isSubmitting: Boolean = false,
    val error: String? = null,
    val success: Boolean = false
)

@HiltViewModel
class UpdateGoalViewModel @Inject constructor(
    private val goalApiService: GoalApiService
) : ViewModel() {

    private val _uiState = MutableStateFlow(UpdateGoalUiState())
    val uiState: StateFlow<UpdateGoalUiState> = _uiState

    fun submitUpdate(
        goalId: Int,
        addedValue: Double,
        note: String,
        imageUris: List<Uri>,
        context: Context
    ) {
        _uiState.value = _uiState.value.copy(isSubmitting = true, error = null)
        viewModelScope.launch {
            try {
                if (imageUris.isEmpty()) {
                    val request = UpdateFilledQuotaRequest(
                        goals_id = goalId,
                        added_value = addedValue,
                        note = note.ifBlank { null }
                    )
                    val response = goalApiService.updateFilledQuota(request)
                    if (response.isSuccessful || response.code() == 200) {
                        _uiState.value = _uiState.value.copy(isSubmitting = false, success = true)
                    } else {
                        _uiState.value = _uiState.value.copy(isSubmitting = false, error = "Failed to submit update")
                    }
                } else {
                    val goalsIdBody = goalId.toString().toRequestBody("text/plain".toMediaTypeOrNull())
                    val addedValueBody = addedValue.toString().toRequestBody("text/plain".toMediaTypeOrNull())
                    val noteBody = if (note.isBlank()) null else note.toRequestBody("text/plain".toMediaTypeOrNull())

                    val fileParts = imageUris.mapIndexedNotNull { index, uri ->
                        try {
                            val stream = context.contentResolver.openInputStream(uri) ?: return@mapIndexedNotNull null
                            val bytes = stream.readBytes()
                            stream.close()
                            val requestBody = bytes.toRequestBody("image/jpeg".toMediaTypeOrNull())
                            MultipartBody.Part.createFormData("files", "image_$index.jpg", requestBody)
                        } catch (e: Exception) {
                            null
                        }
                    }

                    val response = goalApiService.updateFilledQuotaWithImages(
                        goalsId = goalsIdBody,
                        addedValue = addedValueBody,
                        note = noteBody,
                        files = fileParts
                    )
                    if (response.isSuccessful || response.code() == 200) {
                        _uiState.value = _uiState.value.copy(isSubmitting = false, success = true)
                    } else {
                        _uiState.value = _uiState.value.copy(isSubmitting = false, error = "Failed to submit update")
                    }
                }
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(isSubmitting = false, error = e.message ?: "Unknown error")
            }
        }
    }
}
