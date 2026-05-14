# Rep Android App - Copilot Instructions

<!-- Use this file to provide workspace-specific custom instructions to Copilot. For more details, visit https://code.visualstudio.com/docs/copilot/copilot-customization#_use-a-githubcopilotinstructionsmd-file -->

## Project Overview
This is an Android app built with Kotlin and Jetpack Compose, converted from a Swift iOS app. The app is a social networking platform for "Reps" (representatives) featuring:

- User authentication and registration
- User profiles with skills and locations
- Portals (group spaces) for collaboration
- Goals tracking with progress visualization
- Real-time messaging
- Content sharing and image uploads

## Architecture Guidelines
- Use **MVVM architecture** with Repository pattern
- Use **Jetpack Compose** for all UI components
- Use **Dagger Hilt** for dependency injection
- Use **Room** for local database storage
- Use **Retrofit** with **Moshi** for API communication
- Follow **Material 3** design system
- Use **Coil** for image loading
- Use **Navigation Compose** for screen navigation

## Code Style Guidelines
- Use Kotlin coroutines for asynchronous operations
- Implement proper error handling with sealed classes
- Use data classes for models
- Follow Android Architecture Components best practices
- Use StateFlow and SharedFlow for reactive programming
- Implement proper loading and error states in ViewModels

## API Integration
- The app connects to a Python Flask backend at APIConfig.baseURL
- Use JWT tokens for authentication
- All API calls should handle network errors gracefully
- Implement token refresh logic for expired sessions

## Key Features to Implement
1. **Authentication Flow**: Registration, Login, Onboarding
2. **Profile Management**: Edit profile, skills selection, image upload
3. **Main Screen**: Portals and People tabs with segmented control
4. **Portal Details**: Image gallery, goals, story sections
5. **Goals Management**: Create, edit, update progress, team management
6. **Messaging**: Real-time chat with individuals
7. **Content Creation**: Portal creation with image uploads and story blocks
