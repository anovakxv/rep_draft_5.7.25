package com.networkedcapital.rep.di

import android.content.Context
import androidx.room.Room
import com.networkedcapital.rep.data.local.AppDatabase
import com.networkedcapital.rep.data.local.dao.*
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

/**
 * Hilt module for providing Room database and DAO instances.
 * All database-related dependencies are provided as singletons.
 */
@Module
@InstallIn(SingletonComponent::class)
object DatabaseModule {

    /**
     * Provides the main Room database instance.
     * Uses fallbackToDestructiveMigration for development - should be changed for production.
     */
    @Provides
    @Singleton
    fun provideAppDatabase(
        @ApplicationContext context: Context
    ): AppDatabase {
        return Room.databaseBuilder(
            context,
            AppDatabase::class.java,
            AppDatabase.DATABASE_NAME
        )
            .fallbackToDestructiveMigration() // For development - consider migration strategy for production
            .build()
    }

    /**
     * Provides PortalDao for portal data operations
     */
    @Provides
    @Singleton
    fun providePortalDao(database: AppDatabase): PortalDao {
        return database.portalDao()
    }

    /**
     * Provides UserDao for user data operations
     */
    @Provides
    @Singleton
    fun provideUserDao(database: AppDatabase): UserDao {
        return database.userDao()
    }

    /**
     * Provides GoalDao for goal data operations
     */
    @Provides
    @Singleton
    fun provideGoalDao(database: AppDatabase): GoalDao {
        return database.goalDao()
    }

    /**
     * Provides ActiveChatDao for chat data operations
     */
    @Provides
    @Singleton
    fun provideActiveChatDao(database: AppDatabase): ActiveChatDao {
        return database.activeChatDao()
    }
}
