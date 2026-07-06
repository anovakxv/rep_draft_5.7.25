package com.networkedcapital.rep.presentation.profile

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.networkedcapital.rep.data.repository.AuthRepository
import com.networkedcapital.rep.data.repository.ProfileRepository
import com.networkedcapital.rep.domain.model.*
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import okhttp3.MediaType.Companion.toMediaTypeOrNull
import okhttp3.MultipartBody
import okhttp3.RequestBody.Companion.asRequestBody
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileOutputStream
import javax.inject.Inject

data class ProfileUiState(
    val user: User? = null,
    val portals: List<Portal> = emptyList(),
    val goals: List<Goal> = emptyList(),
    val writeBlocks: List<WriteBlock> = emptyList(),
    val userPhotos: List<UserPhoto> = emptyList(),
    val isUploadingPhoto: Boolean = false,
    val photoError: String? = null,
    val availableSkills: List<Skill> = emptyList(),
    val isBlocked: Boolean = false,
    val isLoading: Boolean = false,
    val isLoaded: Boolean = false,
    val errorMessage: String? = null,
    val selectedTab: Int = 0,
    val writeTitle: String = "",
    val writeContent: String = "",
    val editingWrite: WriteBlock? = null,
    val currentUserId: Int = 0,
    val viewedUserId: Int = 0,
    val actionResultMessage: String? = null
)

@HiltViewModel
class ProfileViewModel @Inject constructor(
    private val profileRepository: ProfileRepository,
    private val authRepository: AuthRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(ProfileUiState())
    val uiState: StateFlow<ProfileUiState> = _uiState.asStateFlow()

    val isCurrentUser: Boolean
        get() = _uiState.value.currentUserId == _uiState.value.viewedUserId && _uiState.value.currentUserId > 0

    // S3 base URL for image patching (same as backend and iOS)
    private val s3BaseUrl = "https://rep-app-dbbucket.s3.us-west-2.amazonaws.com/"

    /**
     * Patch image URL - convert filename to full S3 URL if needed
     */
    private fun patchImageUrl(imageNameOrUrl: String?): String? {
        if (imageNameOrUrl.isNullOrBlank()) return null
        return if (imageNameOrUrl.startsWith("http")) {
            imageNameOrUrl
        } else {
            s3BaseUrl + imageNameOrUrl
        }
    }

    /**
     * Patch all image URLs in User profile
     */
    private fun patchUserImages(user: User): User {
        val patchedUrl = patchImageUrl(user.profile_picture_url ?: user.imageName)
        return user.copy(
            profile_picture_url = patchedUrl,
            imageUrl = patchedUrl,
            avatarUrl = patchedUrl
        )
    }

    /**
     * Patch main image URL in Portal
     * Backend returns mainImageUrl, but UI uses imageUrl, so we must copy it over.
     */
    private fun patchPortalImages(portal: Portal): Portal {
        val patchedMainImage = patchImageUrl(portal.mainImageUrl)
        return portal.copy(
            mainImageUrl = patchedMainImage,
            imageUrl = patchedMainImage  // Copy mainImageUrl to imageUrl for UI compatibility
        )
    }

    fun initialize(viewedUserId: Int) {
        viewModelScope.launch {
            // Get current logged-in user ID
            authRepository.getCurrentUser()
                .catch { /* Handle silently */ }
                .firstOrNull()?.fold(
                        onSuccess = { currentUser ->
                            _uiState.value = _uiState.value.copy(
                                currentUserId = currentUser.id,
                                viewedUserId = viewedUserId
                            )
                            // If viewing own profile, use the current user data directly
                            if (viewedUserId == currentUser.id) {
                                val patchedUser = patchUserImages(currentUser)
                                _uiState.value = _uiState.value.copy(
                                    user = patchedUser,
                                    isLoaded = true,
                                    isLoading = false
                                )
                                // Still fetch other data (portals, goals, writes, photos)
                                fetchPortals()
                                fetchGoals()
                                fetchWrites()
                                fetchPhotos()
                                fetchAvailableSkills()
                            } else {
                                // Viewing another user's profile - fetch all data
                                loadProfile()
                            }
                        },
                        onFailure = {
                            _uiState.value = _uiState.value.copy(
                                viewedUserId = viewedUserId
                            )
                            loadProfile()
                        }
                    )
        }
    }

    fun loadProfile() {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, isLoaded = false)

            // Load all profile data in parallel
            fetchUser()
            fetchPortals()
            fetchGoals()
            fetchWrites()
            fetchPhotos()
            fetchAvailableSkills()
            fetchBlockStatus()
        }
    }

    private fun fetchUser() {
        viewModelScope.launch {
            profileRepository.getUserProfile(_uiState.value.viewedUserId)
                .catch { throwable ->
                    _uiState.value = _uiState.value.copy(
                        errorMessage = throwable.message ?: "Failed to load user profile"
                    )
                }
                .firstOrNull()?.fold(
                        onSuccess = { user ->
                            val patchedUser = patchUserImages(user)
                            _uiState.value = _uiState.value.copy(
                                user = patchedUser,
                                isLoaded = true,
                                isLoading = false
                            )
                        },
                        onFailure = { throwable ->
                            _uiState.value = _uiState.value.copy(
                                errorMessage = throwable.message ?: "Failed to load user profile",
                                isLoaded = true,
                                isLoading = false
                            )
                        }
                    )
        }
    }

    private fun fetchPortals() {
        viewModelScope.launch {
            profileRepository.getUserPortals(_uiState.value.viewedUserId)
                .catch { /* Handle silently */ }
                .firstOrNull()?.fold(
                        onSuccess = { portals ->
                            val patchedPortals = portals.map { patchPortalImages(it) }
                            _uiState.value = _uiState.value.copy(portals = patchedPortals)
                        },
                        onFailure = { /* Handle silently */ }
                    )
        }
    }

    private fun fetchGoals() {
        viewModelScope.launch {
            profileRepository.getUserGoals(_uiState.value.viewedUserId)
                .catch { /* Handle silently */ }
                .firstOrNull()?.fold(
                        onSuccess = { goals ->
                            _uiState.value = _uiState.value.copy(goals = goals)
                        },
                        onFailure = { /* Handle silently */ }
                    )
        }
    }

    private fun fetchWrites() {
        viewModelScope.launch {
            profileRepository.getWrites(_uiState.value.viewedUserId)
                .catch { /* Handle silently */ }
                .firstOrNull()?.fold(
                        onSuccess = { writeBlocks ->
                            _uiState.value = _uiState.value.copy(writeBlocks = writeBlocks)
                        },
                        onFailure = { /* Handle silently */ }
                    )
        }
    }

    private fun fetchAvailableSkills() {
        viewModelScope.launch {
            profileRepository.getSkills()
                .catch { /* Handle silently */ }
                .firstOrNull()?.fold(
                        onSuccess = { skills ->
                            _uiState.value = _uiState.value.copy(availableSkills = skills)
                        },
                        onFailure = { /* Handle silently */ }
                    )
        }
    }

    private fun fetchBlockStatus() {
        if (isCurrentUser) return // Don't check block status for own profile

        viewModelScope.launch {
            profileRepository.isBlocked(_uiState.value.viewedUserId)
                .catch { /* Handle silently */ }
                .firstOrNull()?.fold(
                        onSuccess = { isBlocked ->
                            _uiState.value = _uiState.value.copy(isBlocked = isBlocked)
                        },
                        onFailure = { /* Handle silently */ }
                    )
        }
    }

    fun selectTab(index: Int) {
        _uiState.value = _uiState.value.copy(selectedTab = index)
    }

    // Write block management
    fun updateWriteTitle(title: String) {
        _uiState.value = _uiState.value.copy(writeTitle = title)
    }

    fun updateWriteContent(content: String) {
        _uiState.value = _uiState.value.copy(writeContent = content)
    }

    fun startEditingWrite(write: WriteBlock) {
        _uiState.value = _uiState.value.copy(
            editingWrite = write,
            writeTitle = write.title ?: "",
            writeContent = write.content
        )
    }

    fun cancelEditingWrite() {
        _uiState.value = _uiState.value.copy(
            editingWrite = null,
            writeTitle = "",
            writeContent = ""
        )
    }

    fun saveWrite() {
        val currentState = _uiState.value
        if (currentState.writeContent.isEmpty()) return

        viewModelScope.launch {
            if (currentState.editingWrite != null) {
                // Edit existing write
                profileRepository.editWrite(
                    writeId = currentState.editingWrite.id,
                    title = currentState.writeTitle,
                    content = currentState.writeContent,
                    order = currentState.editingWrite.order
                )
                    .catch { throwable ->
                        _uiState.value = _uiState.value.copy(
                            errorMessage = throwable.message ?: "Failed to update write"
                        )
                    }
                    .collect { result ->
                        result.fold(
                            onSuccess = {
                                _uiState.value = _uiState.value.copy(
                                    editingWrite = null,
                                    writeTitle = "",
                                    writeContent = ""
                                )
                                fetchWrites()
                            },
                            onFailure = { throwable ->
                                _uiState.value = _uiState.value.copy(
                                    errorMessage = throwable.message ?: "Failed to update write"
                                )
                            }
                        )
                    }
            } else {
                // Add new write
                profileRepository.addWrite(
                    title = currentState.writeTitle,
                    content = currentState.writeContent
                )
                    .catch { throwable ->
                        _uiState.value = _uiState.value.copy(
                            errorMessage = throwable.message ?: "Failed to add write"
                        )
                    }
                    .collect { result ->
                        result.fold(
                            onSuccess = {
                                _uiState.value = _uiState.value.copy(
                                    writeTitle = "",
                                    writeContent = ""
                                )
                                fetchWrites()
                            },
                            onFailure = { throwable ->
                                _uiState.value = _uiState.value.copy(
                                    errorMessage = throwable.message ?: "Failed to add write"
                                )
                            }
                        )
                    }
            }
        }
    }

    fun deleteWrite(write: WriteBlock) {
        viewModelScope.launch {
            profileRepository.deleteWrite(write.id)
                .catch { throwable ->
                    _uiState.value = _uiState.value.copy(
                        errorMessage = throwable.message ?: "Failed to delete write"
                    )
                }
                .firstOrNull()?.fold(
                        onSuccess = {
                            fetchWrites()
                        },
                        onFailure = { throwable ->
                            _uiState.value = _uiState.value.copy(
                                errorMessage = throwable.message ?: "Failed to delete write"
                            )
                        }
                    )
        }
    }

    // User actions
    fun blockUser(onComplete: (Boolean, String?) -> Unit) {
        viewModelScope.launch {
            profileRepository.blockUser(_uiState.value.viewedUserId)
                .catch { throwable ->
                    onComplete(false, throwable.message ?: "Failed to block user")
                }
                .firstOrNull()?.fold(
                        onSuccess = {
                            _uiState.value = _uiState.value.copy(
                                isBlocked = true,
                                actionResultMessage = "User blocked"
                            )
                            onComplete(true, null)
                        },
                        onFailure = { throwable ->
                            onComplete(false, throwable.message ?: "Failed to block user")
                        }
                    )
        }
    }

    fun unblockUser(onComplete: (Boolean, String?) -> Unit) {
        viewModelScope.launch {
            profileRepository.unblockUser(_uiState.value.viewedUserId)
                .catch { throwable ->
                    onComplete(false, throwable.message ?: "Failed to unblock user")
                }
                .firstOrNull()?.fold(
                        onSuccess = {
                            _uiState.value = _uiState.value.copy(
                                isBlocked = false,
                                actionResultMessage = "User unblocked"
                            )
                            onComplete(true, null)
                        },
                        onFailure = { throwable ->
                            onComplete(false, throwable.message ?: "Failed to unblock user")
                        }
                    )
        }
    }

    fun flagUser(reason: String = "", onComplete: (Boolean, String?) -> Unit) {
        viewModelScope.launch {
            profileRepository.flagUser(_uiState.value.viewedUserId, reason)
                .catch { throwable ->
                    onComplete(false, throwable.message ?: "Failed to flag user")
                }
                .firstOrNull()?.fold(
                        onSuccess = {
                            _uiState.value = _uiState.value.copy(
                                actionResultMessage = "User flagged as inappropriate"
                            )
                            onComplete(true, null)
                        },
                        onFailure = { throwable ->
                            onComplete(false, throwable.message ?: "Failed to flag user")
                        }
                    )
        }
    }

    fun addToNetwork(onComplete: (Boolean, String?) -> Unit) {
        viewModelScope.launch {
            profileRepository.addToNetwork(_uiState.value.currentUserId, _uiState.value.viewedUserId)
                .catch { throwable ->
                    onComplete(false, throwable.message ?: "Failed to add to network")
                }
                .firstOrNull()?.fold(
                        onSuccess = {
                            _uiState.value = _uiState.value.copy(
                                actionResultMessage = "Added to your network!"
                            )
                            onComplete(true, null)
                        },
                        onFailure = { throwable ->
                            onComplete(false, throwable.message ?: "Failed to add to network")
                        }
                    )
        }
    }

    // Photos
    fun fetchPhotos() {
        viewModelScope.launch {
            profileRepository.getUserPhotos(_uiState.value.viewedUserId)
                .catch { /* Handle silently */ }
                .firstOrNull()?.fold(
                    onSuccess = { photos ->
                        _uiState.value = _uiState.value.copy(userPhotos = photos)
                    },
                    onFailure = { /* Handle silently */ }
                )
        }
    }

    fun uploadPhoto(uri: Uri, caption: String, context: Context) {
        _uiState.value = _uiState.value.copy(isUploadingPhoto = true, photoError = null)
        viewModelScope.launch {
            try {
                val bitmap = context.contentResolver.openInputStream(uri)?.use {
                    BitmapFactory.decodeStream(it)
                } ?: run {
                    _uiState.value = _uiState.value.copy(isUploadingPhoto = false, photoError = "Could not read image")
                    return@launch
                }
                val file = File(context.cacheDir, "user_photo_upload.jpg")
                FileOutputStream(file).use { out ->
                    val stream = ByteArrayOutputStream()
                    bitmap.compress(Bitmap.CompressFormat.JPEG, 85, stream)
                    out.write(stream.toByteArray())
                }
                val requestFile = file.asRequestBody("image/jpeg".toMediaTypeOrNull())
                val photoPart = MultipartBody.Part.createFormData("photo", "photo.jpg", requestFile)
                profileRepository.uploadPhoto(photoPart, caption.ifBlank { null })
                    .catch { e ->
                        _uiState.value = _uiState.value.copy(isUploadingPhoto = false, photoError = e.message)
                    }
                    .firstOrNull()?.fold(
                        onSuccess = { newPhoto ->
                            _uiState.value = _uiState.value.copy(
                                isUploadingPhoto = false,
                                userPhotos = listOf(newPhoto) + _uiState.value.userPhotos
                            )
                        },
                        onFailure = { e ->
                            _uiState.value = _uiState.value.copy(isUploadingPhoto = false, photoError = e.message)
                        }
                    )
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(isUploadingPhoto = false, photoError = e.message)
            }
        }
    }

    fun deletePhoto(photo: UserPhoto) {
        viewModelScope.launch {
            profileRepository.deletePhoto(photo.id)
                .catch { /* Handle silently */ }
                .firstOrNull()?.fold(
                    onSuccess = {
                        _uiState.value = _uiState.value.copy(
                            userPhotos = _uiState.value.userPhotos.filter { it.id != photo.id }
                        )
                    },
                    onFailure = { /* Handle silently */ }
                )
        }
    }

    fun movePhotoUp(index: Int) {
        if (index <= 0) return
        val photos = _uiState.value.userPhotos.toMutableList()
        val temp = photos[index]; photos[index] = photos[index - 1]; photos[index - 1] = temp
        _uiState.value = _uiState.value.copy(userPhotos = photos)
        viewModelScope.launch {
            profileRepository.reorderPhotos(_uiState.value.viewedUserId, photos)
                .catch { }.firstOrNull()
        }
    }

    fun movePhotoDown(index: Int) {
        val photos = _uiState.value.userPhotos
        if (index >= photos.size - 1) return
        val mutable = photos.toMutableList()
        val temp = mutable[index]; mutable[index] = mutable[index + 1]; mutable[index + 1] = temp
        _uiState.value = _uiState.value.copy(userPhotos = mutable)
        viewModelScope.launch {
            profileRepository.reorderPhotos(_uiState.value.viewedUserId, mutable)
                .catch { }.firstOrNull()
        }
    }

    fun clearError() {
        _uiState.value = _uiState.value.copy(errorMessage = null)
    }

    fun clearActionResult() {
        _uiState.value = _uiState.value.copy(actionResultMessage = null)
    }
}
