<!--
  DesktopDashboard.vue
  Rep — desktop "Rolodex Shell" (lg+ breakpoint): People · Conversation · Purpose-Value.

  Rendered by MainScreen.vue inside a "hidden lg:flex" wrapper. The mobile layout lives
  entirely in MainScreen.vue. This component is mounted (hidden) on phones too, so
  everything that loads conversations or marks messages read is gated on isDesktop.

  - Left: conversation list (Rep Coach pinned, invites, chats) or Network / All people
  - Center: the open conversation (ConversationView, or RepCoachChat), sized to read well
  - Right: ContextPane — About the open conversation, or the Purpose feed
  The open conversation lives in the URL (/main?c=dm-12 | group-7 | coach), so refresh,
  back/forward and links work. Desktop /chat/... and /coach links are routed here.
  Roadmap: WEB_CHAT_UX_ROADMAP.md (gitignored).
-->

<template>
  <div class="flex h-screen w-full overflow-hidden bg-white">

    <!-- ======================================================
         PEOPLE: conversation list
         ====================================================== -->
    <aside v-show="!focusMode" class="flex flex-col shrink-0 w-[280px] xl:w-[300px] border-r border-gray-200 bg-white">

      <!-- Header: profile menu · title · search · add -->
      <div class="shrink-0 flex items-center gap-2 h-14 px-3 border-b border-gray-200" style="background: #f7f7f7">
        <div class="relative">
          <button
            @click="handleProfileClick"
            class="flex items-center gap-0.5 focus:outline-none"
            :aria-label="isAuth ? 'Profile menu' : 'Log in or register'"
            :aria-haspopup="isAuth ? 'menu' : undefined"
            :aria-expanded="isAuth ? showProfileMenu : undefined"
          >
            <img
              v-if="currentUser?.profile_picture_url"
              :src="currentUser.profile_picture_url"
              class="w-8 h-8 rounded-full object-cover"
              :class="showProfileMenu ? 'ring-2 ring-offset-2 ring-offset-gray-100 ring-[#8cc65d]' : ''"
              alt="Profile"
            />
            <div
              v-else
              class="w-8 h-8 rounded-full bg-gray-300 flex items-center justify-center text-white text-xs font-semibold"
              :class="showProfileMenu ? 'ring-2 ring-offset-2 ring-offset-gray-100 ring-[#8cc65d]' : ''"
            >{{ getInitials(currentUser?.full_name || 'User') }}</div>
            <svg v-if="isAuth" xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5 text-gray-600" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
              <path stroke-linecap="round" stroke-linejoin="round" d="M19 9l-7 7-7-7" />
            </svg>
          </button>

          <!-- Click-away layer -->
          <div v-if="showProfileMenu" @click="showProfileMenu = false" class="fixed inset-0 z-30"></div>

          <Transition name="fade">
            <div
              v-if="showProfileMenu"
              role="menu"
              class="absolute left-0 top-full mt-2 z-40 w-72 bg-white rounded-2xl shadow-2xl border border-gray-100 overflow-hidden"
            >
              <div class="flex items-center gap-3 px-4 pt-3.5 pb-3 border-b border-gray-100">
                <img v-if="currentUser?.profile_picture_url" :src="currentUser.profile_picture_url" class="w-10 h-10 rounded-full object-cover shrink-0" alt="" />
                <div v-else class="w-10 h-10 rounded-full bg-gray-300 flex items-center justify-center text-white text-sm font-semibold shrink-0">{{ getInitials(currentUser?.full_name || 'User') }}</div>
                <p class="font-semibold text-gray-900 text-[15px] truncate">{{ currentUser?.full_name }}</p>
              </div>
              <div class="px-2 py-2">
                <button role="menuitem" @click="goToMyProfile" class="w-full flex items-center gap-3 px-2 py-2.5 rounded-xl hover:bg-gray-50 transition-colors text-left">
                  <span class="w-9 h-9 rounded-full flex items-center justify-center shrink-0" style="background: #8cc65d">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                    </svg>
                  </span>
                  <div>
                    <p class="font-semibold text-gray-900 text-[15px]">My Profile</p>
                    <p class="text-xs text-gray-500">See your page</p>
                  </div>
                </button>
                <button role="menuitem" @click="goToSettings" class="w-full flex items-center gap-3 px-2 py-2.5 rounded-xl hover:bg-gray-50 transition-colors text-left">
                  <span class="w-9 h-9 rounded-full flex items-center justify-center shrink-0" style="background: #8cc65d">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z" />
                      <path stroke-linecap="round" stroke-linejoin="round" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                    </svg>
                  </span>
                  <div>
                    <p class="font-semibold text-gray-900 text-[15px]">Settings</p>
                    <p class="text-xs text-gray-500">Account, payments, password</p>
                  </div>
                </button>
              </div>
              <div class="border-t border-gray-100 px-2 py-2">
                <button role="menuitem" @click="handleLogout" class="w-full flex items-center gap-3 px-2 py-2.5 rounded-xl hover:bg-gray-50 transition-colors text-left">
                  <span class="w-9 h-9 rounded-full flex items-center justify-center shrink-0 bg-red-600">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" />
                    </svg>
                  </span>
                  <div>
                    <p class="font-semibold text-red-600 text-[15px]">Log Out</p>
                    <p class="text-xs text-gray-500">Sign out of Rep on this device</p>
                  </div>
                </button>
              </div>
            </div>
          </Transition>
        </div>

        <!-- Mode: People (conversations and profiles in the center) or Purposes (Purpose-Value in the center) -->
        <div class="flex-1 min-w-0 flex justify-center">
          <div v-if="isAuth" class="flex p-0.5 rounded-lg bg-gray-200/70" role="tablist" aria-label="Dashboard mode">
            <button
              type="button"
              role="tab"
              :aria-selected="mode === 'chat'"
              class="relative px-2.5 h-7 rounded-md text-[13px] font-semibold transition-colors"
              :class="mode === 'chat' ? 'bg-white text-gray-900 shadow-sm' : 'text-gray-500 hover:text-gray-800'"
              @click="enterChatMode"
            >
              People
              <span v-if="mode !== 'chat' && openNeedsAttention" class="absolute top-1 right-1 w-1.5 h-1.5 rounded-full" style="background: #8cc65d"></span>
            </button>
            <button
              type="button"
              role="tab"
              :aria-selected="mode === 'purposes'"
              class="px-2.5 h-7 rounded-md text-[13px] font-semibold transition-colors"
              :class="mode === 'purposes' ? 'bg-white text-gray-900 shadow-sm' : 'text-gray-500 hover:text-gray-800'"
              @click="enterPurposeMode"
            >Purposes</button>
          </div>
          <span v-else class="text-[15px] font-semibold text-gray-900">Rep</span>
        </div>

        <button
          v-if="isAuth"
          @click="toggleLeftSearch"
          class="w-8 h-8 rounded-lg flex items-center justify-center hover:bg-gray-200/60"
          :class="showLeftSearch ? 'bg-gray-200/60' : ''"
          style="color: #8cc65d"
          :aria-label="leftTab === 0 ? 'Search conversations' : 'Search people'"
        >
          <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
            <path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
          </svg>
        </button>
        <button @click="handleAddClick" class="w-8 h-8 rounded-lg flex items-center justify-center hover:bg-gray-200/60" style="color: #8cc65d" aria-label="New">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
            <path stroke-linecap="round" stroke-linejoin="round" d="M12 4v16m8-8H4" />
          </svg>
        </button>
      </div>

      <!-- Chats / Network / All + search -->
      <div v-if="isAuth" class="shrink-0 px-3 py-2 space-y-2 border-b border-gray-100">
        <div class="flex p-0.5 rounded-lg bg-gray-100" role="tablist" aria-label="People to show">
          <button
            v-for="(label, i) in ['Chats', 'Network', 'All']"
            :key="label"
            type="button"
            role="tab"
            :aria-selected="leftTab === i"
            class="relative flex-1 h-7 rounded-md text-[13px] font-medium transition-colors"
            :class="leftTab === i ? 'bg-white text-gray-900 shadow-sm' : 'text-gray-500 hover:text-gray-800'"
            @click="setLeftTab(i)"
          >
            {{ label }}
            <span v-if="i === 0 && openNeedsAttention" class="absolute top-1 right-2 w-1.5 h-1.5 rounded-full" style="background: #8cc65d"></span>
          </button>
        </div>
        <div v-if="showLeftSearch" class="flex items-center gap-2">
          <input
            ref="leftSearchRef"
            v-model="leftSearchText"
            type="search"
            :placeholder="leftTab === 0 ? 'Search conversations…' : 'Search people…'"
            class="flex-1 h-8 px-3 rounded-lg bg-gray-100 text-sm focus:outline-none focus:ring-1 focus:ring-[#8cc65d]"
            @keydown.esc="toggleLeftSearch"
          />
        </div>
      </div>

      <!-- List -->
      <div class="flex-1 min-h-0 overflow-y-auto">
        <!-- Logged out: the pitch, then ghost rows hinting at what's inside -->
        <template v-if="!isAuth">
          <div class="px-5 pt-8 pb-6 text-center border-b border-gray-100">
            <img :src="REPLogo" alt="Rep" class="w-14 h-14 object-contain mx-auto" />
            <h1 class="mt-3 font-bold text-[19px] leading-snug text-gray-900">Accelerate prioritized Purpose</h1>
            <p class="mt-2 text-sm text-gray-500 leading-relaxed">
              Find Purposes worth your time, meet the people behind them, and build Goal Teams that move.
            </p>
            <RouterLink
              to="/register"
              class="mt-5 flex items-center justify-center h-10 rounded-full text-white text-sm font-semibold hover:opacity-90"
              style="background: #8cc65d"
            >Join Rep</RouterLink>
            <RouterLink to="/login" class="mt-3 inline-block text-xs text-gray-500 hover:text-gray-800">Already a member? Log in</RouterLink>
          </div>
          <p class="px-4 pt-4 pb-1 text-[11px] font-semibold uppercase tracking-wide text-gray-300">Your conversations will appear here</p>
          <div v-for="i in 5" :key="i" class="flex items-center gap-3 px-3 py-3 opacity-70" aria-hidden="true">
            <div class="w-10 h-10 rounded-full bg-gray-100 shrink-0"></div>
            <div class="flex-1 space-y-2">
              <div class="h-3 bg-gray-100 rounded" :style="`width:${[55, 70, 60, 75, 50][i - 1]}%`"></div>
              <div class="h-2.5 bg-gray-50 rounded" :style="`width:${[80, 65, 90, 70, 85][i - 1]}%`"></div>
            </div>
          </div>
        </template>

        <!-- Chats -->
        <template v-else-if="leftTab === 0">
          <RepCoachRow
            v-if="coachEnabled"
            variant="desktop"
            :selected="selected?.kind === 'coach'"
            :nudge="coachNudge"
            @select="openConversation({ kind: 'coach' })"
          />

          <RouterLink v-if="pendingInvites.length" to="/invites" class="flex items-center gap-3 px-3 py-3 border-b border-gray-100 hover:bg-gray-50">
            <div class="w-10 h-10 rounded-full flex items-center justify-center text-white text-base shrink-0" style="background: #8cc65d">🔔</div>
            <div class="min-w-0">
              <p class="text-sm font-semibold truncate">{{ pendingInvites.length }} pending invitation{{ pendingInvites.length > 1 ? 's' : '' }}</p>
              <p class="text-xs text-gray-500">View your invites</p>
            </div>
          </RouterLink>

          <div v-if="isLoadingPeople && !activeChats.length" class="space-y-0 animate-pulse" aria-hidden="true">
            <div v-for="i in 5" :key="i" class="flex items-center gap-3 px-3 py-3">
              <div class="w-10 h-10 rounded-full bg-gray-100 shrink-0"></div>
              <div class="flex-1 space-y-2"><div class="h-3 bg-gray-100 rounded w-1/2"></div><div class="h-2.5 bg-gray-50 rounded w-3/4"></div></div>
            </div>
          </div>
          <p v-else-if="!filteredChats.length && !pendingInvites.length" class="p-6 text-center text-gray-400 text-sm">
            {{ leftSearchText ? 'No conversations match your search' : 'No chats yet' }}
          </p>

          <div
            v-for="chat in filteredChats"
            :key="chat.id"
            role="button"
            tabindex="0"
            class="flex items-center gap-3 px-3 py-3 cursor-pointer border-b border-gray-50 transition-colors focus:outline-none focus-visible:bg-gray-50"
            :class="isSelectedChat(chat) ? 'bg-[#f3f9ee]' : 'hover:bg-gray-50'"
            :aria-current="isSelectedChat(chat) ? 'true' : undefined"
            @click="openChat(chat)"
            @keydown.enter.prevent="openChat(chat)"
          >
            <div class="shrink-0 relative" @click.stop="chat.type === 'direct' && chat.user?.id ? router.push(`/profile/${chat.user.id}`) : openChat(chat)">
              <img
                v-if="chat.type === 'direct' && chat.user?.profile_picture_url"
                :src="chat.user.profile_picture_url"
                class="w-10 h-10 rounded-full object-cover"
                :class="chat.type === 'direct' ? 'hover:opacity-80' : ''"
                alt=""
              />
              <div
                v-else
                class="w-10 h-10 rounded-full flex items-center justify-center text-white text-sm font-semibold"
                :class="chat.type === 'group' ? '' : 'bg-gray-300 hover:opacity-80'"
                :style="chat.type === 'group' ? 'background-color: #113213' : ''"
              >{{ getInitials(chat.type === 'direct' ? chat.user?.full_name || 'U' : chat.chat?.name || 'G') }}</div>
            </div>
            <div class="flex-1 min-w-0">
              <div class="flex justify-between items-baseline gap-2">
                <p class="text-sm leading-snug truncate" :class="isUnread(chat) ? 'font-bold text-gray-900' : 'font-semibold text-gray-900'">
                  {{ chat.type === 'direct' ? chat.user?.full_name : chat.chat?.name }}
                </p>
                <span class="text-[11px] shrink-0" :class="isUnread(chat) ? 'font-semibold text-[#006600]' : 'text-gray-400'">{{ timeAgo(chat.last_message_time) }}</span>
              </div>
              <div class="flex items-center gap-2 mt-0.5">
                <p class="flex-1 text-xs truncate" :class="isUnread(chat) ? 'font-semibold text-gray-800' : 'text-gray-500'">
                  {{ messagePreview(chat.last_message?.text) }}
                </p>
                <span v-if="isUnread(chat)" class="w-2 h-2 rounded-full shrink-0" style="background: #8cc65d" aria-label="Unread"></span>
              </div>
            </div>
          </div>
        </template>

        <!-- Network / All people -->
        <template v-else>
          <p v-if="!filteredPeople.length" class="p-6 text-center text-gray-400 text-sm">
            {{ leftSearchText ? 'No people match your search' : leftTab === 1 ? 'No network members yet' : 'No people found' }}
          </p>
          <div
            v-for="user in filteredPeople"
            :key="user.id"
            role="button"
            tabindex="0"
            class="flex items-center gap-3 px-3 py-2.5 cursor-pointer border-b border-gray-50 transition-colors focus:outline-none focus-visible:bg-gray-50"
            :class="selectedThread?.kind === 'direct' && selectedThread.id === user.id ? 'bg-[#f3f9ee]' : 'hover:bg-gray-50'"
            :title="`Message ${user.full_name}`"
            @click="openConversation({ kind: 'direct', id: user.id })"
            @keydown.enter.prevent="openConversation({ kind: 'direct', id: user.id })"
          >
            <RouterLink :to="`/profile/${user.id}`" class="shrink-0" @click.stop>
              <img v-if="user.profile_picture_url" :src="user.profile_picture_url" class="w-10 h-10 rounded-full object-cover hover:opacity-80" alt="" />
              <div v-else class="w-10 h-10 rounded-full bg-gray-300 flex items-center justify-center text-white text-sm font-semibold hover:opacity-80">{{ getInitials(user.full_name || 'U') }}</div>
            </RouterLink>
            <p class="flex-1 min-w-0 text-sm font-semibold truncate">{{ user.full_name }}</p>
          </div>
        </template>
      </div>
    </aside>

    <!-- ======================================================
         CONVERSATION
         ====================================================== -->
    <main class="flex-1 min-w-0 flex flex-col bg-white">

      <!-- Logged out: the public Purpose feed fills the center (the pitch is in the left column) -->
      <PurposeFeed v-if="!isAuth && isDesktop" class="flex-1 min-h-0" :user-id="0" :is-auth="false" layout="wide" />
      <template v-else-if="!isAuth"></template>

      <!-- Nothing renders (or loads) here on phones; the mobile layout is MainScreen's -->
      <template v-else-if="!isDesktop"></template>

      <!-- Purpose mode: the Purpose-Value side of the rolodex takes the center -->
      <PurposeFeed
        v-else-if="mode === 'purposes'"
        class="flex-1 min-h-0"
        :user-id="userId"
        :is-auth="isAuth"
        layout="wide"
        @open-group="(chat) => openConversation({ kind: 'group', id: chat.id })"
        @toast="triggerToast"
      />

      <!-- Person: a full profile card in the center (desktop /profile/:id links land here) -->
      <PersonView
        v-else-if="mode === 'person' && personId"
        :key="personId"
        class="flex-1 min-h-0"
        :user-id="personId"
        :current-user-id="userId"
        :coach-enabled="!!coachEnabled"
        @back="closePerson"
        @message="(id) => openConversation({ kind: 'direct', id })"
        @open-group="(chat) => openConversation({ kind: 'group', id: chat.id })"
        @ask-coach="askCoach"
        @start-onboarding="startOnboarding"
        @toast="triggerToast"
      />

      <!-- Rep Coach -->
      <template v-else-if="selected?.kind === 'coach'">
        <RepCoachChat v-if="coachEnabled" embedded class="flex-1 min-h-0">
          <template #header-actions>
            <ShellPaneControls :context-open="contextShowing" :focus-mode="focusMode" @toggle-context="toggleContext" @toggle-focus="toggleFocus" />
          </template>
        </RepCoachChat>
        <div v-else-if="coachEnabled === false" class="flex-1 flex flex-col items-center justify-center gap-3 px-8 text-center">
          <img :src="RepCoachAvatar" alt="" class="w-14 h-14 rounded-full" />
          <p class="text-gray-600">Rep Coach isn't available right now.</p>
          <button type="button" class="text-sm font-semibold hover:underline" style="color: #8cc65d" @click="clearSelection">Back to your conversations</button>
        </div>
        <div v-else class="flex-1 flex items-center justify-center">
          <span class="animate-spin h-6 w-6 border-2 border-gray-300 border-t-transparent rounded-full"></span>
        </div>
      </template>

      <!-- DM or group -->
      <ConversationView
        v-else-if="selectedThread"
        class="flex-1 min-h-0"
        :kind="selectedThread.kind"
        :id="selectedThread.id"
        :current-user-id="userId"
        :title="selectedTitle"
        :avatar="selectedAvatar"
        @refresh-chats="emit('refresh-chats')"
        @group-loaded="(info) => (groupInfo = info)"
        @left="onLeftGroup"
      >
        <template #actions>
          <ShellPaneControls :context-open="contextShowing" :focus-mode="focusMode" @toggle-context="toggleContext" @toggle-focus="toggleFocus" />
        </template>
      </ConversationView>

      <!-- Nothing open yet -->
      <div v-else class="flex-1 flex flex-col items-center justify-center px-8 text-center">
        <div class="w-14 h-14 rounded-2xl flex items-center justify-center mb-4" style="background-color: #f3f9ee">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-7 w-7" style="color: #8cc65d" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
            <path stroke-linecap="round" stroke-linejoin="round" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
          </svg>
        </div>
        <p class="font-semibold text-gray-900 text-lg">Pick up a conversation</p>
        <p class="text-sm text-gray-500 mt-1 max-w-sm">
          Choose someone on the left{{ coachEnabled ? ', or ask Rep Coach to find people and Purposes for what you’re working on' : '' }}.
        </p>
        <div class="mt-5 flex flex-wrap justify-center gap-2">
          <button
            v-if="coachEnabled"
            type="button"
            class="px-5 h-10 rounded-full text-white text-sm font-semibold hover:opacity-90 inline-flex items-center gap-2"
            style="background: #8cc65d"
            @click="openConversation({ kind: 'coach' })"
          >
            <img :src="RepCoachAvatar" alt="" class="w-5 h-5 rounded-full bg-white" />
            Open Rep Coach
          </button>
          <button
            type="button"
            class="px-5 h-10 rounded-full border border-gray-300 text-sm font-semibold text-gray-800 hover:bg-gray-50"
            @click="enterPurposeMode"
          >Browse Purposes</button>
        </div>
      </div>
    </main>

    <!-- ======================================================
         PURPOSE · VALUE: context pane (inline on wide screens)
         ====================================================== -->
    <aside
      v-if="isAuth && isDesktop && mode === 'chat' && isWide && contextOpen && !focusMode"
      class="flex flex-col shrink-0 w-[380px] 2xl:w-[420px] border-l border-gray-200"
    >
      <ContextPane
        class="flex-1 min-h-0"
        :conversation="selected"
        :current-user-id="userId"
        :is-auth="isAuth"
        :group="groupInfo"
        :coach-enabled="!!coachEnabled"
        :my-write-count="myWriteCount"
        @open-conversation="openConversation"
        @open-group="(chat) => openConversation({ kind: 'group', id: chat.id })"
        @ask-coach="askCoach"
        @start-onboarding="startOnboarding"
        @toast="triggerToast"
        @expand-purposes="enterPurposeMode"
      />
    </aside>

    <!-- Context pane as a drawer on narrower desktops -->
    <Transition name="drawer">
      <div v-if="isAuth && isDesktop && mode === 'chat' && !isWide && drawerOpen && !focusMode" class="fixed inset-0 z-40 flex justify-end">
        <div class="absolute inset-0 bg-black/30" @click="drawerOpen = false"></div>
        <div class="drawer-panel relative flex flex-col w-[380px] max-w-[90vw] h-full bg-white shadow-2xl">
          <ContextPane
            class="flex-1 min-h-0"
            closable
            :conversation="selected"
            :current-user-id="userId"
            :is-auth="isAuth"
            :group="groupInfo"
            :coach-enabled="!!coachEnabled"
            :my-write-count="myWriteCount"
            @close="drawerOpen = false"
            @open-conversation="openConversation"
            @open-group="(chat) => openConversation({ kind: 'group', id: chat.id })"
            @ask-coach="askCoach"
            @start-onboarding="startOnboarding"
            @toast="triggerToast"
            @expand-purposes="enterPurposeMode"
          />
        </div>
      </div>
    </Transition>

    <!-- Add menu -->
    <Transition name="fade">
      <div v-if="showActionSheet" @click="showActionSheet = false" class="fixed inset-0 z-30 flex items-center justify-center">
        <div class="absolute inset-0 bg-black/40"></div>
        <div @click.stop class="relative z-10 bg-white rounded-2xl shadow-2xl w-72 overflow-hidden">
          <div class="px-2 py-2">
            <button @click="navigateTo('/portal/edit/new')" class="w-full flex items-center gap-3 px-4 py-3 rounded-xl hover:bg-gray-50 transition-colors text-left">
              <span class="w-9 h-9 rounded-full flex items-center justify-center shrink-0" style="background: #8cc65d">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M12 4v16m8-8H4" />
                </svg>
              </span>
              <div>
                <p class="font-semibold text-gray-900 text-[15px]">Add Purpose</p>
                <p class="text-xs text-gray-400">Create a new portal</p>
              </div>
            </button>
            <button @click="navigateTo('/chat/group/new')" class="w-full flex items-center gap-3 px-4 py-3 rounded-xl hover:bg-gray-50 transition-colors text-left">
              <span class="w-9 h-9 rounded-full flex items-center justify-center shrink-0" style="background: #8cc65d">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0z" />
                </svg>
              </span>
              <div>
                <p class="font-semibold text-gray-900 text-[15px]">Team Chat</p>
                <p class="text-xs text-gray-400">Start a group conversation</p>
              </div>
            </button>
          </div>
          <div class="border-t border-gray-100 px-2 py-2">
            <button @click="showActionSheet = false" class="w-full px-4 py-2.5 rounded-xl text-sm text-gray-500 hover:bg-gray-50 transition-colors text-center">Cancel</button>
          </div>
        </div>
      </div>
    </Transition>

    <!-- Toast -->
    <Transition
      enter-active-class="transition-all duration-300 ease-out"
      leave-active-class="transition-all duration-200 ease-in"
      enter-from-class="opacity-0 translate-y-2"
      leave-to-class="opacity-0 translate-y-2"
    >
      <div
        v-if="showToast"
        role="status"
        class="fixed bottom-6 left-1/2 -translate-x-1/2 z-50 flex items-center gap-2 px-5 py-3 bg-gray-900 text-white text-sm font-medium rounded-full shadow-xl pointer-events-none whitespace-nowrap"
      >{{ toastMessage }}</div>
    </Transition>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch, nextTick, onMounted, onUnmounted } from 'vue';
import { useRouter, useRoute, RouterLink } from 'vue-router';
import api from '@/pages/utils/api';
import { isAuthenticated, logout } from '@/utils/auth';
import REPLogo from '@/assets/REPLogo.png';
import RepCoachAvatar from '@/assets/RepCoachAvatar.svg';
import RepCoachRow from '@/components/RepCoachRow.vue';
import RepCoachChat from '@/components/RepCoachChat.vue';
import ConversationView from '@/components/desktop/ConversationView.vue';
import ContextPane from '@/components/desktop/ContextPane.vue';
import PurposeFeed from '@/components/desktop/PurposeFeed.vue';
import ShellPaneControls from '@/components/desktop/ShellPaneControls.vue';
import PersonView from '@/components/desktop/PersonView.vue';
import { useRepCoach } from '@/pages/utils/useRepCoach';
import { useRepOnboarding, onboardingStatus } from '@/pages/utils/useRepOnboarding';
import { messagePreview } from '@/pages/utils/privateReply';
import {
  parseConversationKey,
  formatConversationKey,
  sameConversation,
  isDesktopViewport,
  WIDE_DESKTOP,
  readLastConversation,
  saveLastConversation,
  readPref,
  savePref,
  getInitials,
  timeAgo,
  type ConversationKey,
  type GroupLoaded,
} from '@/pages/utils/desktopShell';

// --- Types (minimal — just what this component needs) ---
interface User {
  id: number;
  full_name?: string;
  profile_picture_url?: string;
}
interface ChatModel { id: number; name?: string }
interface MessageModel { id: number; text?: string; read?: string; sender_id?: number; created_at?: string }
interface ActiveChat {
  id: string;
  type: 'direct' | 'group';
  user?: User;
  chat?: ChatModel;
  last_message?: MessageModel;
  last_message_time?: string;
}
interface Invite { id: number }

// --- Props (shared data from MainScreen) ---
const props = defineProps<{
  activeChats: ActiveChat[];
  filteredActiveChats: ActiveChat[];
  pendingInvites: Invite[];
  currentUser: User | null;
  userId: number;
  openNeedsAttention: boolean;
  isLoadingPeople: boolean;
}>();

const emit = defineEmits<{ (e: 'refresh-chats'): void }>();

const router = useRouter();
const route = useRoute();

// Reactive auth check — derived from props.userId so Vue re-evaluates when parent updates after login
const isAuth = computed(() => props.userId > 0);

// --- Viewport: this component is mounted on phones too (hidden), so gate all behavior ---
const isDesktop = ref(isDesktopViewport());
const isWide = ref(window.innerWidth >= WIDE_DESKTOP);
function onResize() {
  isDesktop.value = isDesktopViewport();
  isWide.value = window.innerWidth >= WIDE_DESKTOP;
}

// --- Panes ---
const contextOpen = ref(readPref('contextPane', 'open') !== 'closed');
const drawerOpen = ref(false);
const focusMode = ref(false);
const contextShowing = computed(() => !focusMode.value && (isWide.value ? contextOpen.value : drawerOpen.value));

function toggleContext() {
  if (isWide.value) {
    contextOpen.value = !contextOpen.value;
    savePref('contextPane', contextOpen.value ? 'open' : 'closed');
  } else {
    drawerOpen.value = !drawerOpen.value;
  }
}

function toggleFocus() {
  focusMode.value = !focusMode.value;
  drawerOpen.value = false;
}

function onKeydown(e: KeyboardEvent) {
  if (e.key !== 'Escape') return;
  if (drawerOpen.value) drawerOpen.value = false;
  else if (focusMode.value && !(e.target as HTMLElement)?.closest?.('textarea, input')) focusMode.value = false;
}

// --- Profile menu & add menu ---
const showProfileMenu = ref(false);
const showActionSheet = ref(false);

const handleProfileClick = () => {
  if (!isAuthenticated()) { router.push({ path: '/register', query: { returnTo: '/main' } }); return; }
  showProfileMenu.value = !showProfileMenu.value;
};
const goToMyProfile = () => { showProfileMenu.value = false; router.push(`/profile/${props.userId}`); };
const goToSettings = () => { showProfileMenu.value = false; router.push('/settings'); };
const handleLogout = () => { showProfileMenu.value = false; logout(); router.push('/login'); };
const handleAddClick = () => {
  if (!isAuthenticated()) { router.push({ path: '/register', query: { returnTo: '/main' } }); return; }
  showActionSheet.value = true;
};
const navigateTo = (path: string) => { showActionSheet.value = false; router.push(path); };

// --- Toast ---
const showToast = ref(false);
const toastMessage = ref('');
let toastTimer: ReturnType<typeof setTimeout> | null = null;
function triggerToast(msg: string) {
  if (toastTimer) clearTimeout(toastTimer);
  toastMessage.value = msg;
  showToast.value = true;
  toastTimer = setTimeout(() => { showToast.value = false; }, 3000);
}

// --- Left list: Chats / Network / All ---
const leftTab = ref<0 | 1 | 2>(0);
const showLeftSearch = ref(false);
const leftSearchText = ref('');
const leftSearchRef = ref<HTMLInputElement | null>(null);
const people = ref<User[]>([]);

function setLeftTab(tab: number) {
  if (!isAuthenticated()) { router.push({ path: '/register', query: { returnTo: '/main' } }); return; }
  leftTab.value = tab as 0 | 1 | 2;
  leftSearchText.value = '';
  if (tab === 1) fetchPeople('ntwk');
  if (tab === 2) fetchPeople('all');
}

function toggleLeftSearch() {
  showLeftSearch.value = !showLeftSearch.value;
  if (!showLeftSearch.value) leftSearchText.value = '';
  else nextTick(() => leftSearchRef.value?.focus());
}

async function fetchPeople(tab: 'ntwk' | 'all') {
  if (!isAuthenticated()) return;
  try {
    const res = await api.get(`/api/filter_people?user_id=${props.userId}&tab=${tab}&limit=200`);
    people.value = res.data.result || [];
  } catch { /* silent */ }
}

const filteredChats = computed(() => {
  const q = leftSearchText.value.trim().toLowerCase();
  if (!q) return props.filteredActiveChats;
  return props.filteredActiveChats.filter((c) =>
    (c.type === 'direct' ? c.user?.full_name || '' : c.chat?.name || '').toLowerCase().includes(q)
  );
});

const filteredPeople = computed(() => {
  const q = leftSearchText.value.trim().toLowerCase();
  const list = people.value.filter((u) => u.id !== props.userId);
  return q ? list.filter((u) => (u.full_name || '').toLowerCase().includes(q)) : list;
});

const isUnread = (chat: ActiveChat) =>
  chat.last_message?.read === '0' && chat.last_message?.sender_id !== props.userId;

function chatKey(chat: ActiveChat): ConversationKey | null {
  if (chat.type === 'direct' && chat.user?.id) return { kind: 'direct', id: chat.user.id };
  if (chat.type === 'group' && chat.chat?.id) return { kind: 'group', id: chat.chat.id };
  return null;
}

const isSelectedChat = (chat: ActiveChat) => sameConversation(selected.value, chatKey(chat));

function openChat(chat: ActiveChat) {
  const key = chatKey(chat);
  if (key) openConversation(key);
}

// --- Rep Coach ---
const { enabled: coachEnabled, checkStatus: checkCoachStatus, send: sendToCoach, sending: coachSending } = useRepCoach();
const { setView: setCoachView, skipped: setupSkipped } = useRepOnboarding();

// Profile setup is the next step for nearly every member, so anyone who hasn't completed
// it lands in it. (The Write count is still shown in Coach's About pane.)
const myWriteCount = ref<number | null>(null);
async function loadMyWriteCount() {
  if (!isAuth.value) return;
  try {
    const res = await api.get(`/api/user/writes?users_id=${props.userId}`);
    myWriteCount.value = (res.data.result || []).length;
  } catch {
    myWriteCount.value = null;
  }
}
const needsOnboarding = computed(() => onboardingStatus.value !== 'complete');
const coachNudge = computed(() => (needsOnboarding.value ? 'Finish your profile with Rep Coach' : undefined));

function askCoach(text: string) {
  if (!coachEnabled.value) return;
  setCoachView('coach');
  openConversation({ kind: 'coach' });
  if (!coachSending.value) sendToCoach(text);
}

// "Set up my profile" / "Write it with Coach": open Rep Coach on the profile-setup interview
function startOnboarding(opts: { replace?: boolean } = {}) {
  if (!coachEnabled.value) return;
  setCoachView('onboarding');
  openConversation({ kind: 'coach' }, opts);
}

// Saving the setup draft (or writing elsewhere) changes the Write count
function onWriteUpdated() {
  if (isAuth.value) loadMyWriteCount();
}

// --- The open conversation (driven by the URL) ---
const selected = ref<ConversationKey | null>(null);
const groupInfo = ref<GroupLoaded | null>(null);

// A DM or group (anything but Rep Coach) — what ConversationView renders
const selectedThread = computed(() => {
  const key = selected.value;
  return key && key.kind !== 'coach' ? key : null;
});

const selectedChat = computed(() => {
  const key = selected.value;
  if (!key || key.kind === 'coach') return null;
  return props.activeChats.find((c) => sameConversation(chatKey(c), key)) || null;
});
const selectedTitle = computed(() => {
  const c = selectedChat.value;
  if (c) return c.type === 'direct' ? c.user?.full_name : c.chat?.name;
  const key = selected.value;
  if (key?.kind === 'direct') return people.value.find((u) => u.id === key.id)?.full_name;
  return undefined;
});
const selectedAvatar = computed(() => {
  const c = selectedChat.value;
  if (c?.type === 'direct') return c.user?.profile_picture_url || null;
  const key = selected.value;
  if (key?.kind === 'direct') return people.value.find((u) => u.id === key.id)?.profile_picture_url || null;
  return null;
});

function openConversation(key: ConversationKey, opts: { replace?: boolean } = {}) {
  const c = formatConversationKey(key);
  if (route.path === '/main' && route.query.c === c) {
    applyKey(key);
    return;
  }
  const to = { path: '/main', query: { c } };
  if (opts.replace) router.replace(to);
  else router.push(to);
}

function applyKey(key: ConversationKey | null) {
  drawerOpen.value = false;
  if (sameConversation(selected.value, key)) return;
  selected.value = key;
  groupInfo.value = null;
  if (key && isAuth.value) saveLastConversation(props.userId, key);
}

// --- Mode: what the center shows ---
//   chat     — a conversation (/main?c=…)
//   purposes — the Purpose feed (/main?view=purposes)
//   person   — a full profile card (/main?person=45)
// Only updated while on /main, so a cached (keep-alive) dashboard never mounts a
// conversation behind another page.
const mode = ref<'chat' | 'purposes' | 'person'>('chat');
const personId = ref(0);

// Back from a profile: to wherever the member came from, or to their conversations
function closePerson() {
  if (window.history.state?.back) router.back();
  else enterChatMode();
}

function enterPurposeMode() {
  if (route.path === '/main' && route.query.view === 'purposes') return;
  router.push({ path: '/main', query: { view: 'purposes' } });
}

function enterChatMode() {
  if (mode.value === 'chat') return;
  if (selected.value) openConversation(selected.value);
  else openDefaultConversation();
}

// People mode with nothing open yet: Rep Coach on profile setup for members who haven't
// finished it, otherwise the conversation they last had open, else Rep Coach, else an
// empty chat view. Never auto-opens (or marks read) anything else.
async function openDefaultConversation() {
  await checkCoachStatus();
  if (coachEnabled.value && needsOnboarding.value && !setupSkipped.value) {
    startOnboarding();
    return;
  }
  const last = readLastConversation(props.userId);
  if (last && (last.kind !== 'coach' || coachEnabled.value)) openConversation(last);
  else if (coachEnabled.value) openConversation({ kind: 'coach' });
  else router.push({ path: '/main', query: { view: 'chat' } });
}

function clearSelection() {
  applyKey(null);
  saveLastConversation(props.userId, null);
  router.replace({ path: '/main', query: { view: 'chat' } });
}

function onLeftGroup() {
  clearSelection();
}

// Landing (plain /main with nothing open): the Purpose feed is Rep's home screen. Members
// move to People, Rep Coach or a chat from the left column.
function chooseLanding() {
  router.replace({ path: '/main', query: { view: 'purposes' } });
}

function syncFromRoute() {
  if (!isDesktop.value || !isAuth.value || route.path !== '/main') return;
  const person = Number(route.query.person) || 0;
  if (person) {
    mode.value = 'person';
    personId.value = person;
    focusMode.value = false;
    drawerOpen.value = false;
    return;
  }
  if (route.query.view === 'purposes') {
    mode.value = 'purposes';
    focusMode.value = false;
    drawerOpen.value = false;
    return;
  }
  mode.value = 'chat';
  const key = parseConversationKey(route.query.c);
  if (key) {
    applyKey(key);
    return;
  }
  if (selected.value) {
    // Plain /main (logo, back links): keep what's open and put it back in the URL
    router.replace({ path: '/main', query: { c: formatConversationKey(selected.value) } });
    return;
  }
  if (route.query.view === 'chat') return; // People mode, nothing open yet
  chooseLanding();
}

watch(
  () => [route.path, route.query.c, route.query.view, route.query.person, isDesktop.value, isAuth.value],
  syncFromRoute,
  { immediate: true }
);

// Signed in: load the Write count (Coach's About pane). Signed out: forget the open
// conversation and onboarding state.
watch(isAuth, (auth) => {
  if (auth) {
    loadMyWriteCount();
    return;
  }
  selected.value = null;
  groupInfo.value = null;
  myWriteCount.value = null;
  focusMode.value = false;
  mode.value = 'chat';
});

// Back from writing your story (or anywhere else): refresh the onboarding check
watch(() => route.path, (path) => {
  if (path === '/main' && isDesktop.value && isAuth.value && myWriteCount.value === 0) loadMyWriteCount();
});

// --- Lifecycle ---
onMounted(() => {
  window.addEventListener('resize', onResize);
  window.addEventListener('keydown', onKeydown);
  window.addEventListener('rep:write-updated', onWriteUpdated);
  if (isAuth.value) {
    checkCoachStatus();
    loadMyWriteCount();
  }
});

onUnmounted(() => {
  window.removeEventListener('resize', onResize);
  window.removeEventListener('keydown', onKeydown);
  window.removeEventListener('rep:write-updated', onWriteUpdated);
  if (toastTimer) clearTimeout(toastTimer);
});
</script>

<style scoped>
.drawer-enter-active,
.drawer-leave-active {
  transition: opacity 0.2s ease;
}
.drawer-enter-active .drawer-panel,
.drawer-leave-active .drawer-panel {
  transition: transform 0.25s ease-out;
}
.drawer-enter-from,
.drawer-leave-to {
  opacity: 0;
}
.drawer-enter-from .drawer-panel,
.drawer-leave-to .drawer-panel {
  transform: translateX(100%);
}
</style>
