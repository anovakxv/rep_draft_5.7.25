package com.networkedcapital.rep.data.api

import android.content.Context
import com.networkedcapital.rep.domain.model.SkillsJsonAdapter
import com.squareup.moshi.Moshi
import com.squareup.moshi.kotlin.reflect.KotlinJsonAdapterFactory
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Retrofit
import retrofit2.converter.moshi.MoshiConverterFactory
import java.util.concurrent.TimeUnit
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object NetworkModule {

    @Provides
    @Singleton
    fun provideMoshi(): Moshi {
        return Moshi.Builder()
            .add(SkillsJsonAdapter())
            .add(KotlinJsonAdapterFactory())
            .build()
    }

    @Provides
    @Singleton
    fun provideHttpLoggingInterceptor(): HttpLoggingInterceptor {
        return HttpLoggingInterceptor().apply {
            level = HttpLoggingInterceptor.Level.BODY
        }
    }

    @Provides
    @Singleton
    fun provideAuthInterceptor(
        @ApplicationContext context: Context
    ): AuthInterceptor {
        return AuthInterceptor(context)
    }

    @Provides
    @Singleton
    fun provideOkHttpClient(
        loggingInterceptor: HttpLoggingInterceptor,
        authInterceptor: AuthInterceptor
    ): OkHttpClient {
        return OkHttpClient.Builder()
            .addInterceptor(authInterceptor)
            .addInterceptor(loggingInterceptor)
            .connectTimeout(30, TimeUnit.SECONDS)
            .readTimeout(30, TimeUnit.SECONDS)
            .writeTimeout(30, TimeUnit.SECONDS)
            .build()
    }

    @Provides
    @Singleton
    fun provideRetrofit(
        okHttpClient: OkHttpClient,
        moshi: Moshi
    ): Retrofit {
        return Retrofit.Builder()
            .baseUrl(ApiConfig.BASE_URL)
            .client(okHttpClient)
            .addConverterFactory(MoshiConverterFactory.create(moshi))
            .build()
    }

    @Provides
    @Singleton
    fun provideAuthApiService(retrofit: Retrofit): AuthApiService {
        return retrofit.create(AuthApiService::class.java)
    }

    @Provides
    @Singleton
    fun providePortalApiService(retrofit: Retrofit): PortalApiService {
        return retrofit.create(PortalApiService::class.java)
    }

    @Provides
    @Singleton
    fun provideGoalApiService(retrofit: Retrofit): GoalApiService {
        return retrofit.create(GoalApiService::class.java)
    }

    @Provides
    @Singleton
    fun provideMessagingApiService(retrofit: Retrofit): MessagingApiService {
        return retrofit.create(MessagingApiService::class.java)
    }

    @Provides
    @Singleton
    fun providePaymentApiService(retrofit: Retrofit): PaymentApiService {
        return retrofit.create(PaymentApiService::class.java)
    }

    @Provides
    @Singleton
    fun provideInviteApiService(retrofit: Retrofit): InviteApiService {
        return retrofit.create(InviteApiService::class.java)
    }

    @Provides
    @Singleton
    fun provideUserApiService(retrofit: Retrofit): UserApiService {
        return retrofit.create(UserApiService::class.java)
    }

    @Provides
    @Singleton
    fun provideProfileApiService(retrofit: Retrofit): ProfileApiService {
        return retrofit.create(ProfileApiService::class.java)
    }
}
