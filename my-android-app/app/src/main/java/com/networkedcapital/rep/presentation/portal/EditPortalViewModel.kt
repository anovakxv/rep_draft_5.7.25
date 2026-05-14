package com.networkedcapital.rep.presentation.portal

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.networkedcapital.rep.data.repository.PortalRepository
import com.networkedcapital.rep.domain.model.Portal
import com.networkedcapital.rep.domain.model.PortalDetail
import com.networkedcapital.rep.domain.model.User
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import okhttp3.MediaType.Companion.toMediaTypeOrNull
import okhttp3.MultipartBody
import okhttp3.RequestBody.Companion.asRequestBody
import okhttp3.RequestBody.Companion.toRequestBody
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileOutputStream
import java.util.UUID
import javax.inject.Inject

// Story block data model
data class PortalStoryBlock(
    val id: String = UUID.randomUUID().toString(),
    val title: String = "",
    val content: String = "",
    val order: Int = 0
)

data class EditPortalUiState(
    val isLoading: Boolean = false,
    val isSaving: Boolean = false,
    val errorMessage: String? = null,
    val successMessage: String? = null,
    val name: String = "",
    val subtitle: String = "",
    val about: String = "",
    val selectedImages: List<Bitmap> = emptyList(),
    val mainImageIndex: Int = 0,
    val storyBlocks: List<PortalStoryBlock> = emptyList(),
    val selectedLeads: List<User> = emptyList(),
    val portalDetail: PortalDetail? = null,
    val networkMembers: List<User> = emptyList(),
    val isLoadingMembers: Boolean = false
)

@HiltViewModel
class EditPortalViewModel @Inject constructor(
    private val portalRepository: PortalRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(EditPortalUiState())
    val uiState: StateFlow<EditPortalUiState> = _uiState.asStateFlow()

    private val maxImages = 10

    fun initializeWithPortal(portalDetail: PortalDetail) {
        _uiState.value = _uiState.value.copy(
            portalDetail = portalDetail,
            name = portalDetail.name,
            subtitle = portalDetail.subtitle ?: "",
            about = portalDetail.about ?: "",
            storyBlocks = portalDetail.aTexts?.filter { it.section == "story" }?.mapIndexed { idx, text ->
                PortalStoryBlock(
                    title = text.title ?: "",
                    content = text.text ?: "",
                    order = idx
                )
            } ?: emptyList()
        )
    }

    fun updateName(name: String) {
        _uiState.value = _uiState.value.copy(name = name)
    }

    fun updateSubtitle(subtitle: String) {
        _uiState.value = _uiState.value.copy(subtitle = subtitle)
    }

    fun updateAbout(about: String) {
        _uiState.value = _uiState.value.copy(about = about)
    }

    fun addImages(uris: List<Uri>, context: Context) {
        viewModelScope.launch {
            val currentCount = _uiState.value.selectedImages.size
            val availableSlots = maxImages - currentCount
            val urisToLoad = uris.take(availableSlots)

            val newImages = urisToLoad.mapNotNull { uri ->
                try {
                    context.contentResolver.openInputStream(uri)?.use { inputStream ->
                        BitmapFactory.decodeStream(inputStream)
                    }
                } catch (e: Exception) {
                    null
                }
            }

            _uiState.value = _uiState.value.copy(
                selectedImages = _uiState.value.selectedImages + newImages
            )
        }
    }

    fun removeImage(index: Int) {
        val currentImages = _uiState.value.selectedImages.toMutableList()
        if (index in currentImages.indices && index != 0) { // Can't remove main image
            currentImages.removeAt(index)
            val newMainIndex = if (_uiState.value.mainImageIndex >= currentImages.size) {
                if (currentImages.isEmpty()) 0 else currentImages.size - 1
            } else {
                _uiState.value.mainImageIndex
            }
            _uiState.value = _uiState.value.copy(
                selectedImages = currentImages,
                mainImageIndex = newMainIndex
            )
        }
    }

    fun setMainImageIndex(index: Int) {
        _uiState.value = _uiState.value.copy(mainImageIndex = index)
    }

    // Story block functions
    fun addStoryBlock(title: String, content: String) {
        val newBlock = PortalStoryBlock(
            title = title,
            content = content,
            order = _uiState.value.storyBlocks.size
        )
        _uiState.value = _uiState.value.copy(
            storyBlocks = _uiState.value.storyBlocks + newBlock
        )
    }

    fun updateStoryBlock(blockId: String, title: String, content: String) {
        _uiState.value = _uiState.value.copy(
            storyBlocks = _uiState.value.storyBlocks.map { block ->
                if (block.id == blockId) {
                    block.copy(title = title, content = content)
                } else {
                    block
                }
            }
        )
    }

    fun deleteStoryBlock(blockId: String) {
        _uiState.value = _uiState.value.copy(
            storyBlocks = _uiState.value.storyBlocks.filter { it.id != blockId }
        )
    }

    // Leads management
    fun loadNetworkMembers(userId: Int) {
        _uiState.value = _uiState.value.copy(isLoadingMembers = true)
        viewModelScope.launch {
            try {
                val members = portalRepository.getFilteredPeople(userId, "ntwk")
                _uiState.value = _uiState.value.copy(
                    networkMembers = members,
                    isLoadingMembers = false
                )
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    isLoadingMembers = false,
                    errorMessage = "Failed to load network members: ${e.message}"
                )
            }
        }
    }

    fun toggleLeadSelection(user: User) {
        val currentLeads = _uiState.value.selectedLeads.toMutableList()
        val existingIndex = currentLeads.indexOfFirst { it.id == user.id }
        if (existingIndex >= 0) {
            currentLeads.removeAt(existingIndex)
        } else {
            currentLeads.add(user)
        }
        _uiState.value = _uiState.value.copy(selectedLeads = currentLeads)
    }

    fun savePortal(userId: Int, portalId: Int, context: Context, onSuccess: (Int) -> Unit) {
        _uiState.value = _uiState.value.copy(isSaving = true, errorMessage = null)

        viewModelScope.launch {
            try {
                // Create multipart request
                val parts = mutableListOf<MultipartBody.Part>()

                // Add form fields
                if (portalId != 0) {
                    parts.add(createFormDataPart("portal_id", portalId.toString()))
                }
                parts.add(createFormDataPart("users_id", userId.toString()))
                parts.add(createFormDataPart("name", _uiState.value.name))
                parts.add(createFormDataPart("subtitle", _uiState.value.subtitle))
                parts.add(createFormDataPart("about", _uiState.value.about))

                // Add story blocks as aTexts JSON
                if (_uiState.value.storyBlocks.isNotEmpty()) {
                    val textsJsonArray = buildString {
                        append("[")
                        _uiState.value.storyBlocks.forEachIndexed { index, block ->
                            if (index > 0) append(",")
                            append("{")
                            append("\"title\":\"${block.title.replace("\"", "\\\"")}\",")
                            append("\"text\":\"${block.content.replace("\"", "\\\"")}\",")
                            append("\"section\":\"story\"")
                            append("}")
                        }
                        append("]")
                    }
                    parts.add(createFormDataPart("aTexts", textsJsonArray))
                }

                // Add leads IDs
                if (_uiState.value.selectedLeads.isNotEmpty()) {
                    val leadsJsonArray = buildString {
                        append("[")
                        _uiState.value.selectedLeads.forEachIndexed { index, user ->
                            if (index > 0) append(",")
                            append(user.id)
                        }
                        append("]")
                    }
                    parts.add(createFormDataPart("aLeadsIDs", leadsJsonArray))
                }

                // Add images
                _uiState.value.selectedImages.forEachIndexed { idx, bitmap ->
                    val file = createTempImageFile(context, bitmap, idx)
                    val requestFile = file.asRequestBody("image/jpeg".toMediaTypeOrNull())
                    parts.add(
                        MultipartBody.Part.createFormData(
                            "images",
                            "portal_image_$idx.jpg",
                            requestFile
                        )
                    )
                }

                // Call repository to upload
                portalRepository.savePortalWithImages(portalId, parts).collect { result ->
                    result.fold(
                        onSuccess = { portal ->
                            _uiState.value = _uiState.value.copy(
                                isSaving = false,
                                successMessage = "Portal saved successfully"
                            )
                            onSuccess(portal.id)
                        },
                        onFailure = { throwable ->
                            _uiState.value = _uiState.value.copy(
                                isSaving = false,
                                errorMessage = throwable.message ?: "Failed to save portal"
                            )
                        }
                    )
                }
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    isSaving = false,
                    errorMessage = e.message ?: "Failed to save portal"
                )
            }
        }
    }

    fun deletePortal(userId: Int, portalId: Int, onSuccess: () -> Unit) {
        _uiState.value = _uiState.value.copy(isSaving = true, errorMessage = null)
        viewModelScope.launch {
            try {
                portalRepository.deletePortal(portalId, userId).collect { result ->
                    result.fold(
                        onSuccess = {
                            _uiState.value = _uiState.value.copy(
                                isSaving = false,
                                successMessage = "Portal deleted successfully"
                            )
                            onSuccess()
                        },
                        onFailure = { throwable ->
                            _uiState.value = _uiState.value.copy(
                                isSaving = false,
                                errorMessage = throwable.message ?: "Failed to delete portal"
                            )
                        }
                    )
                }
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    isSaving = false,
                    errorMessage = e.message ?: "Failed to delete portal"
                )
            }
        }
    }

    private fun createFormDataPart(name: String, value: String): MultipartBody.Part {
        return MultipartBody.Part.createFormData(name, value)
    }

    private fun createTempImageFile(context: Context, bitmap: Bitmap, index: Int): File {
        val file = File(context.cacheDir, "portal_image_$index.jpg")
        FileOutputStream(file).use { out ->
            val stream = ByteArrayOutputStream()
            bitmap.compress(Bitmap.CompressFormat.JPEG, 85, stream)
            out.write(stream.toByteArray())
        }
        return file
    }

    fun clearError() {
        _uiState.value = _uiState.value.copy(errorMessage = null)
    }

    fun clearSuccess() {
        _uiState.value = _uiState.value.copy(successMessage = null)
    }
}
