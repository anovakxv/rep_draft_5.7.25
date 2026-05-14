package com.networkedcapital.rep.di

import com.networkedcapital.rep.data.repository.UserRepository
import com.networkedcapital.rep.data.repository.UserRepositoryImpl
import com.networkedcapital.rep.data.repository.ProfileRepository
import com.networkedcapital.rep.data.repository.ProfileRepositoryImpl
import dagger.Binds
import dagger.Module
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

/**
 * Hilt module for repository bindings.
 *
 * Note: Most repositories (Auth, Portal, Payment, etc.) are concrete classes
 * annotated with @Singleton and @Inject, so they don't need bindings here.
 * Only interface-based repositories need @Binds declarations.
 */
@Module
@InstallIn(SingletonComponent::class)
abstract class RepositoryModule {

    @Binds
    @Singleton
    abstract fun bindUserRepository(
        userRepositoryImpl: UserRepositoryImpl
    ): UserRepository

    @Binds
    @Singleton
    abstract fun bindProfileRepository(
        profileRepositoryImpl: ProfileRepositoryImpl
    ): ProfileRepository
}
