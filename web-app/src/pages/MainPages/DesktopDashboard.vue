<!--
  DesktopDashboard.vue
  Rep — Desktop-only dashboard layout (lg+ breakpoint)

  Rendered exclusively by MainScreen.vue inside a "hidden lg:flex" wrapper.
  The mobile layout lives entirely in MainScreen.vue — editing this file
  cannot break mobile.

  Props: shared data from MainScreen (chats, portals, user, etc.)
  Internal: all desktop-specific state, fetching, and UI logic.
-->

<template>
  <div class="flex flex-col h-screen" style="background: #f7f7f7">

    <!-- Two-column body -->
    <div class="flex flex-1 overflow-hidden">

      <!-- ======================================================
           LEFT PANEL (50%): Chat sidebar + inline chat view
           ====================================================== -->
      <div class="flex flex-col overflow-hidden border-r border-gray-200" style="width:50%">

        <!-- Left panel header -->
        <div class="relative flex items-center h-12 px-3 border-b border-gray-200 bg-gray-100 shrink-0">
          <!-- Left: profile pic + search + add -->
          <div class="flex items-center gap-2">
            <button @click="handleProfileClick" class="focus:outline-none">
              <img
                v-if="currentUser?.profile_picture_url"
                :src="currentUser.profile_picture_url"
                class="w-8 h-8 rounded-full object-cover"
                alt="Profile"
              />
              <div
                v-else
                class="w-8 h-8 rounded-full bg-gray-300 flex items-center justify-center text-white text-xs font-semibold"
              >{{ getInitials(currentUser?.full_name || 'User') }}</div>
            </button>
            <button @click="showLeftSearch = !showLeftSearch" class="p-1 rounded hover:bg-gray-100" style="color:#8cc65d">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
              </svg>
            </button>
            <button @click="handleAddClick" class="p-1 hover:opacity-75" style="color:#8cc65d">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
                <path stroke-linecap="round" stroke-linejoin="round" d="M12 4v16m8-8H4" />
              </svg>
            </button>
          </div>

          <!-- Right: People label -->
          <span class="ml-auto text-sm font-semibold text-gray-500 tracking-wide">People</span>

          <!-- Center: Chats / Network / All toggle -->
          <div class="absolute left-1/2 -translate-x-1/2 flex items-center h-7 border border-gray-300 rounded overflow-hidden">
            <button
              @click="setLeftTab(0)"
              class="relative w-[72px] text-center h-full text-sm font-medium transition-colors"
              :class="desktopLeftTab === 0 ? 'bg-black text-white' : 'bg-white text-black hover:bg-gray-50'"
            >
              Chats
              <span
                v-if="openNeedsAttention"
                class="absolute top-0.5 left-1 w-2 h-2 rounded-full"
                style="background:#8cc65d"
              ></span>
            </button>
            <div class="w-px h-full bg-gray-300"></div>
            <button
              @click="setLeftTab(1)"
              class="w-[72px] text-center h-full text-sm font-medium transition-colors"
              :class="desktopLeftTab === 1 ? 'bg-black text-white' : 'bg-white text-black hover:bg-gray-50'"
            >Network</button>
            <div class="w-px h-full bg-gray-300"></div>
            <button
              @click="setLeftTab(2)"
              class="w-[72px] text-center h-full text-sm font-medium transition-colors"
              :class="desktopLeftTab === 2 ? 'bg-black text-white' : 'bg-white text-black hover:bg-gray-50'"
            >All</button>
          </div>
        </div>

        <!-- Left search bar (slides in below header) -->
        <Transition name="slide-down">
          <div v-if="showLeftSearch" class="px-3 py-2 border-b border-gray-100 bg-white shrink-0">
            <div class="flex items-center gap-2">
              <input
                v-model="leftSearchText"
                type="search"
                :placeholder="desktopLeftTab === 0 ? 'Search conversations…' : 'Search people…'"
                class="flex-1 h-8 px-3 border rounded-lg bg-gray-100 text-sm focus:outline-none focus:ring-1"
                style="--tw-ring-color: #8cc65d"
                autofocus
              />
              <button
                @click="showLeftSearch = false; leftSearchText = ''"
                class="text-sm text-gray-500 hover:text-gray-700 shrink-0"
              >Cancel</button>
            </div>
          </div>
        </Transition>

        <!-- Sidebar + inline chat (fills remaining left-panel height) -->
        <div class="flex flex-1 overflow-hidden">

        <!-- Narrow sidebar (~280px): chat or network list -->
        <div class="flex flex-col bg-white border-r border-gray-100 shrink-0 overflow-hidden" style="width:280px">

          <!-- Ghost skeleton rows (unauthenticated) — hints at what's inside without fake data -->
          <div v-if="!isAuth" class="flex-1 overflow-y-auto">
            <div
              v-for="i in 7" :key="i"
              class="flex items-center gap-3 px-3 py-3 border-b border-gray-100 animate-pulse"
            >
              <div class="w-10 h-10 rounded-full bg-gray-200 shrink-0"></div>
              <div class="flex-1 space-y-2">
                <div class="h-3 bg-gray-200 rounded" :style="`width:${[55,70,60,75,50,65,58][i-1]}%`"></div>
                <div class="h-2.5 bg-gray-100 rounded" :style="`width:${[80,65,90,70,85,60,75][i-1]}%`"></div>
              </div>
            </div>
          </div>

          <!-- Chats list -->
          <div v-else-if="desktopLeftTab === 0" class="flex-1 overflow-y-auto">
            <!-- Pending invites banner -->
            <RouterLink
              v-if="pendingInvites.length"
              to="/invites"
              class="flex items-center gap-3 px-3 py-3 border-b border-gray-100 hover:bg-gray-50"
            >
              <div
                class="w-10 h-10 rounded-full flex items-center justify-center text-white text-base shrink-0"
                style="background:#8cc65d"
              >🔔</div>
              <div class="min-w-0">
                <p class="text-sm font-semibold truncate">
                  {{ pendingInvites.length }} pending invitation{{ pendingInvites.length > 1 ? 's' : '' }}
                </p>
                <p class="text-xs text-gray-500">Tap to view</p>
              </div>
            </RouterLink>

            <div
              v-if="isLoadingPeople && !activeChats.length"
              class="p-4 text-center text-gray-400 text-sm"
            >Loading…</div>
            <div
              v-else-if="!desktopFilteredChats.length && !pendingInvites.length"
              class="p-6 text-center text-gray-400 text-sm"
            >{{ leftSearchText ? 'No conversations match your search' : 'No chats yet' }}</div>

            <div
              v-for="chat in desktopFilteredChats"
              :key="chat.id"
              @click="loadInlineChat(chat)"
              class="flex items-center gap-3 px-3 py-3 cursor-pointer border-b border-gray-100 hover:bg-gray-50 transition-colors"
              :class="selectedChat?.id === chat.id ? 'bg-gray-100' : ''"
            >
              <div
                class="shrink-0"
                @click.stop="chat.type === 'direct' && chat.user?.id ? router.push(`/profile/${chat.user.id}`) : null"
              >
                <img
                  v-if="chat.type === 'direct' && chat.user?.profile_picture_url"
                  :src="chat.user.profile_picture_url"
                  class="w-10 h-10 rounded-full object-cover"
                  :class="chat.type === 'direct' ? 'cursor-pointer hover:opacity-80' : ''"
                />
                <div
                  v-else
                  class="w-10 h-10 rounded-full bg-gray-300 flex items-center justify-center text-white text-sm font-semibold"
                  :class="chat.type === 'direct' ? 'cursor-pointer hover:opacity-80' : ''"
                >
                  {{ getInitials(chat.type === 'direct' ? (chat.user?.full_name || 'U') : (chat.chat?.name || 'G')) }}
                </div>
              </div>
              <div class="flex-1 min-w-0">
                <!-- Row 1+2: name (up to 2 lines) + time aligned to top-right -->
                <div class="flex justify-between items-start gap-1">
                  <p class="text-sm font-semibold leading-snug line-clamp-2">
                    {{ chat.type === 'direct' ? chat.user?.full_name : chat.chat?.name }}
                  </p>
                  <span class="text-xs text-gray-400 shrink-0 mt-0.5">{{ timeAgoDisplay(chat.last_message_time) }}</span>
                </div>
                <!-- Row 3: message preview -->
                <p
                  class="text-xs truncate mt-1"
                  :class="chat.last_message?.read === '0' && chat.last_message?.sender_id !== userId
                    ? 'font-semibold text-green-600'
                    : 'text-gray-500'"
                >{{ chat.last_message?.text || '' }}</p>
              </div>
            </div>
          </div>

          <!-- Network / All people list -->
          <div v-else-if="isAuth && (desktopLeftTab === 1 || desktopLeftTab === 2)" class="flex-1 overflow-y-auto">
            <div
              v-if="!desktopFilteredNetworkUsers.length"
              class="p-6 text-center text-gray-400 text-sm"
            >{{ leftSearchText ? 'No people match your search' : 'No network members yet' }}</div>
            <RouterLink
              v-for="user in desktopFilteredNetworkUsers"
              :key="user.id"
              :to="`/profile/${user.id}`"
              class="flex items-center gap-3 px-3 py-3 border-b border-gray-100 hover:bg-gray-50 transition-colors"
            >
              <img
                v-if="user.profile_picture_url"
                :src="user.profile_picture_url"
                class="w-10 h-10 rounded-full object-cover shrink-0"
              />
              <div
                v-else
                class="w-10 h-10 rounded-full bg-gray-300 flex items-center justify-center text-white text-sm font-semibold shrink-0"
              >
                {{ getInitials(user.full_name || 'U') }}
              </div>
              <p class="text-sm font-semibold truncate">{{ user.full_name }}</p>
            </RouterLink>
          </div>
        </div>

        <!-- Inline chat view (fills remaining left-panel space) -->
        <div class="flex flex-col flex-1 bg-white overflow-hidden">

          <!-- Unauthenticated: value prop panel -->
          <div v-if="!isAuth" class="flex-1 flex flex-col items-center justify-center px-8 text-center">
            <img :src="REPLogo" alt="Rep" class="w-16 h-16 object-contain mb-2" />
            <h2 class="font-bold text-[17px] text-gray-900">Accelerate prioritized Purpose</h2>
            <p class="text-sm text-gray-400 mt-2 leading-relaxed max-w-[220px]">
              Build Goal Teams, accelerate your Purpose.
            </p>
            <RouterLink
              to="/register"
              class="mt-5 px-7 py-2.5 rounded-full text-white text-sm font-semibold hover:opacity-90 transition-opacity"
              style="background:#8cc65d"
            >Log in / Register</RouterLink>
            <RouterLink
              to="/login"
              class="mt-2.5 text-xs text-gray-400 hover:text-gray-600 transition-colors"
            >Already have an account? Log in</RouterLink>
          </div>

          <!-- No chat selected (authenticated) -->
          <div
            v-else-if="!selectedChat"
            class="flex-1 flex flex-col items-center justify-center text-gray-400"
          >
            <svg xmlns="http://www.w3.org/2000/svg" class="h-12 w-12 mb-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
            </svg>
            <p class="text-sm">Select a conversation to start chatting</p>
          </div>

          <!-- Chat open (authenticated) -->
          <template v-else-if="isAuth && selectedChat">
            <!-- Chat header -->
            <div class="flex items-center gap-3 px-4 py-3 border-b border-gray-200 shrink-0 bg-white">
              <img
                v-if="inlineChatAvatar"
                :src="inlineChatAvatar"
                class="w-8 h-8 rounded-full object-cover cursor-pointer hover:opacity-80"
                @click="selectedChat?.type === 'direct' && selectedChat.user?.id ? router.push(`/profile/${selectedChat.user.id}`) : null"
              />
              <div
                v-else
                class="w-8 h-8 rounded-full bg-gray-300 flex items-center justify-center text-white text-sm font-semibold"
                :class="selectedChat?.type === 'direct' ? 'cursor-pointer hover:opacity-80' : ''"
                @click="selectedChat?.type === 'direct' && selectedChat.user?.id ? router.push(`/profile/${selectedChat.user.id}`) : null"
              >
                {{ getInitials(inlineChatName) }}
              </div>
              <span class="font-semibold text-base flex-1 truncate">{{ inlineChatName }}</span>
              <RouterLink
                :to="selectedChat.type === 'direct'
                  ? `/chat/dm/${selectedChat.user?.id}`
                  : `/chat/group/${selectedChat.chat?.id}`"
                class="text-xs shrink-0 hover:underline"
                style="color:#8cc65d"
              >Open full chat ↗</RouterLink>
            </div>

            <!-- Messages -->
            <div
              ref="inlineChatScrollRef"
              class="flex-1 overflow-y-auto px-4 py-3 space-y-2"
            >
              <div
                v-if="inlineChatLoading"
                class="text-center text-gray-400 text-sm py-8"
              >Loading messages…</div>
              <div
                v-else-if="!inlineChatMessages.length"
                class="text-center text-gray-400 text-sm py-8"
              >No messages yet — say hello!</div>
              <template v-else>
                <div
                  v-for="msg in inlineChatMessages"
                  :key="msg.id"
                  class="flex"
                  :class="isInlineMessageFromMe(msg) ? 'justify-end' : 'justify-start'"
                >
                  <div
                    class="max-w-xs xl:max-w-sm rounded-2xl px-3 py-2 text-sm"
                    :class="isInlineMessageFromMe(msg)
                      ? 'bg-black rounded-br-sm'
                      : 'bg-gray-100 text-gray-900 rounded-bl-sm'"
                    :style="isInlineMessageFromMe(msg) ? 'color:#8cc65d' : ''"
                  >
                    <p
                      v-if="!isInlineMessageFromMe(msg) && selectedChat?.type === 'group' && getInlineMessageSenderName(msg)"
                      class="text-xs text-gray-500 mb-0.5 font-medium"
                    >{{ getInlineMessageSenderName(msg) }}</p>
                    <p>{{ msg.text }}</p>
                    <p class="text-right text-xs mt-0.5 opacity-60">
                      {{ timeAgoDisplay(msg.created_at || msg.timestamp) }}
                    </p>
                  </div>
                </div>
              </template>
            </div>

            <!-- Message input -->
            <div class="px-3 py-2 border-t border-gray-200 shrink-0 bg-white">
              <div class="flex items-end gap-2">
                <textarea
                  ref="messageInputRef"
                  v-model="inlineChatInput"
                  @keydown.enter.exact.prevent="sendInlineMessage"
                  @input="growMessageInput"
                  placeholder="Message…"
                  rows="1"
                  class="flex-1 resize-none rounded-2xl border border-gray-200 px-4 py-2 text-sm bg-gray-50 focus:outline-none focus:ring-1"
                  style="--tw-ring-color: #8cc65d; overflow-y: hidden; max-height: 96px;"
                ></textarea>
                <button
                  @click="sendInlineMessage"
                  :disabled="!inlineChatInput.trim()"
                  class="h-9 w-9 rounded-full flex items-center justify-center text-white transition-colors shrink-0"
                  :class="inlineChatInput.trim() ? 'hover:opacity-80' : 'bg-gray-300'"
                  :style="inlineChatInput.trim() ? 'background:#8cc65d' : ''"
                >
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 rotate-90" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 19l9 2-9-18-9 18 9-2zm0 0v-8" />
                  </svg>
                </button>
              </div>
            </div>
          </template>
        </div>
        </div><!-- end sidebar + inline chat row -->
      </div>

      <!-- ======================================================
           RIGHT PANEL (50%): Scrollable portal card list
           ====================================================== -->
      <div class="flex flex-col overflow-hidden" style="width:50%">

        <!-- Right panel header -->
        <div class="relative flex items-center h-12 px-3 border-b border-gray-200 bg-gray-100 shrink-0">

          <!-- Left: Purpose label -->
          <span class="text-sm font-semibold text-gray-500 tracking-wide">Purpose</span>

          <!-- Center: Me / Network / All toggle -->
          <div class="absolute left-1/2 -translate-x-1/2 flex items-center h-7 border border-gray-300 rounded overflow-hidden">
            <button
              @click="isAuth ? desktopRightTab = 0 : router.push({ path: '/register', query: { returnTo: '/main' } })"
              class="w-[72px] text-center h-full text-sm font-medium transition-colors"
              :class="desktopRightTab === 0 ? 'bg-black text-white' : 'bg-white text-black hover:bg-gray-50'"
            >Me</button>
            <div class="w-px h-full bg-gray-300"></div>
            <button
              @click="isAuth ? desktopRightTab = 1 : router.push({ path: '/register', query: { returnTo: '/main' } })"
              class="w-[72px] text-center h-full text-sm font-medium transition-colors"
              :class="desktopRightTab === 1 ? 'bg-black text-white' : 'bg-white text-black hover:bg-gray-50'"
            >Network</button>
            <div class="w-px h-full bg-gray-300"></div>
            <button
              @click="desktopRightTab = 2"
              class="w-[72px] text-center h-full text-sm font-medium transition-colors"
              :class="desktopRightTab === 2 ? 'bg-black text-white' : 'bg-white text-black hover:bg-gray-50'"
            >All</button>
          </div>

          <!-- Right: search + add -->
          <div class="ml-auto flex items-center gap-2">
            <button
              @click="showSearch = !showSearch"
              class="p-1 rounded hover:bg-gray-100"
              style="color:#8cc65d"
            >
              <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
              </svg>
            </button>
            <button @click="handleAddClick" class="p-1 hover:opacity-75" style="color:#8cc65d">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
                <path stroke-linecap="round" stroke-linejoin="round" d="M12 4v16m8-8H4" />
              </svg>
            </button>
          </div>
        </div>

        <!-- Search bar (drops below header when active) -->
        <Transition name="slide-down">
          <div v-if="showSearch" class="px-3 py-2 border-b border-gray-100 bg-white shrink-0">
            <div class="flex items-center gap-2">
              <input
                v-model="searchText"
                type="search"
                placeholder="Search portals…"
                class="flex-1 h-8 px-3 border rounded-lg bg-gray-100 text-sm focus:outline-none focus:ring-1"
                style="--tw-ring-color: #8cc65d"
                autofocus
              />
              <button
                @click="showSearch = false; searchText = ''"
                class="text-sm text-gray-500 hover:text-gray-700 shrink-0"
              >Cancel</button>
            </div>
          </div>
        </Transition>

        <div class="relative flex-1 min-h-0">
        <div ref="portalListRef" @scroll="onPortalListScroll" class="h-full overflow-y-auto">

          <div
            v-if="isLoadingPortals"
            class="p-8 text-center text-gray-400 text-sm"
          >Loading portals…</div>
          <div
            v-else-if="!desktopPortals.length"
            class="p-8 text-center text-gray-400 text-sm leading-relaxed"
          >
            <template v-if="desktopRightTab === 0">
              No Purposes here for you yet.<br>
              <span class="text-xs">Join a Goal Team on an existing Purpose, or add your own.</span>
            </template>
            <template v-else-if="desktopRightTab === 1">
              No Purposes in your network yet.<br>
              <span class="text-xs">Connect with others to see their Purposes here.</span>
            </template>
            <template v-else>No Purposes found.</template>
          </div>

          <RouterLink
            v-for="portal in desktopFilteredPortals"
            :key="portal.id"
            :data-portal-id="portal.id"
            :to="`/portal/${portal.id}`"
            class="block border-b border-gray-300 bg-white"
          >
            <!-- Portal title strip — name + subtitle on one line -->
            <div class="px-3 pt-3 pb-2">
              <p class="text-[15px] leading-snug line-clamp-1 text-gray-900">
                <span class="font-bold">{{ portal.name }}</span>
                <span v-if="portal.subtitle?.trim()" class="font-normal text-gray-400"> — {{ portal.subtitle }}</span>
              </p>
            </div>

            <!-- Card body: image left + goal cards right -->
            <div class="flex" style="height:180px">

              <!-- Single portal image with ← → to cycle pitch deck slides -->
              <div class="relative flex-shrink-0 bg-gray-200" style="width:320px">
                <img
                  v-if="getCardImage(portal)"
                  :src="getCardImage(portal)"
                  :alt="portal.name"
                  class="w-full h-full object-cover"
                />
                <!-- ← prev -->
                <button
                  v-if="(portalCardImageIndex[portal.id] ?? 0) > 0"
                  @click.prevent.stop="prevCardImage(portal.id)"
                  class="absolute left-1.5 top-1/2 -translate-y-1/2 w-7 h-7 rounded-full bg-black/40 hover:bg-black/70 text-white flex items-center justify-center transition-colors"
                >
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M15 19l-7-7 7-7" />
                  </svg>
                </button>
                <!-- → next -->
                <button
                  v-if="(portalCardImageIndex[portal.id] ?? 0) < (portalCardImages[portal.id]?.length ?? 1) - 1"
                  @click.prevent.stop="nextCardImage(portal.id)"
                  class="absolute right-1.5 top-1/2 -translate-y-1/2 w-7 h-7 rounded-full bg-black/40 hover:bg-black/70 text-white flex items-center justify-center transition-colors"
                >
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M9 5l7 7-7 7" />
                  </svg>
                </button>
                <!-- Pagination dots -->
                <div
                  v-if="(portalCardImages[portal.id]?.length ?? 0) > 1"
                  class="absolute bottom-1.5 left-0 right-0 flex justify-center gap-1 pointer-events-none"
                >
                  <div
                    v-for="(_, i) in portalCardImages[portal.id]" :key="i"
                    class="w-1.5 h-1.5 rounded-full"
                    :class="i === (portalCardImageIndex[portal.id] ?? 0) ? 'bg-white' : 'bg-white/40'"
                  ></div>
                </div>
              </div>

              <!-- Goal cards -->
              <div class="flex-1 min-w-0 flex flex-col justify-center gap-3 px-3 py-2">

                <!-- Loading state -->
                <div v-if="!portalCardGoals[portal.id]" class="space-y-3 animate-pulse">
                  <div v-for="i in 2" :key="i" class="space-y-1.5">
                    <div class="h-3 bg-gray-200 rounded w-3/4"></div>
                    <div class="h-2 bg-gray-100 rounded w-full"></div>
                  </div>
                </div>

                <!-- No goals -->
                <p
                  v-else-if="portalCardGoals[portal.id].length === 0"
                  class="text-xs text-gray-400 italic"
                >No active Goal Teams yet</p>

                <!-- Goal rows -->
                <template v-else>
                  <div
                    v-for="goal in portalCardGoals[portal.id]"
                    :key="goal.id"
                    class="space-y-1"
                  >
                    <!-- Goal title -->
                    <p class="text-xs font-semibold text-gray-800 leading-tight line-clamp-1">{{ goal.title }}</p>
                    <!-- Team membership error -->
                    <p v-if="goalChatError[goal.id]" class="text-[10px] text-red-500 leading-tight">
                      {{ goalChatError[goal.id] }}
                    </p>
                    <!-- Progress bar + % + message icon -->
                    <div class="flex items-center gap-1.5">
                      <div class="flex-1 bg-gray-200 rounded-full h-2 overflow-hidden">
                        <div
                          class="h-full rounded-full transition-all duration-300"
                          style="background:#8cc65d"
                          :style="{ width: `${Math.min(100, Math.max(0, (goal.progress ?? 0) * 100))}%` }"
                        ></div>
                      </div>
                      <span class="text-[11px] text-gray-500 shrink-0 w-7 text-right">
                        {{ Math.round((goal.progress ?? 0) * 100) }}%
                      </span>
                      <button
                        @click.prevent.stop="openGoalTeamChat(goal, portal.name)"
                        :disabled="goalChatCreating[goal.id]"
                        class="shrink-0 w-5 h-5 rounded-full flex items-center justify-center hover:opacity-80 transition-opacity"
                        style="background:#8cc65d"
                        :title="goal.chats_id ? 'Message this Goal Team' : 'Start Goal Team chat'"
                      >
                        <svg v-if="goalChatCreating[goal.id]" class="h-3 w-3 text-white animate-spin" fill="none" viewBox="0 0 24 24">
                          <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                          <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8H4z"></path>
                        </svg>
                        <svg v-else xmlns="http://www.w3.org/2000/svg" class="h-3 w-3 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
                        </svg>
                      </button>
                    </div>
                  </div>
                </template>

              </div>
            </div>
            <div class="pb-2"></div>
          </RouterLink>

          <div
            v-if="desktopFilteredPortals.length === 0 && desktopPortals.length > 0"
            class="p-6 text-center text-gray-400 text-sm"
          >No portals match your search</div>

        </div><!-- end scroll container -->

        <!-- ▲ scroll hint -->
        <button
          v-if="!isAtTop"
          @click="scrollPortalListBy(-1)"
          class="absolute right-3 top-2 z-10 w-8 h-8 rounded-full bg-white shadow-md border border-gray-200 flex items-center justify-center hover:bg-gray-50 transition-opacity"
          aria-label="Scroll up"
        >
          <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 text-gray-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 15l7-7 7 7" />
          </svg>
        </button>

        <!-- ▼ scroll hint -->
        <button
          v-if="!isAtBottom"
          @click="scrollPortalListBy(1)"
          class="absolute right-3 bottom-2 z-10 w-8 h-8 rounded-full bg-white shadow-md border border-gray-200 flex items-center justify-center hover:bg-gray-50 transition-opacity"
          aria-label="Scroll down"
        >
          <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 text-gray-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
          </svg>
        </button>

        </div><!-- end relative wrapper -->
      </div>

    </div>

    <!-- Action menu (desktop: centered floating card) -->
    <Transition name="fade">
      <div
        v-if="showActionSheet"
        @click="showActionSheet = false"
        class="fixed inset-0 z-30 flex items-center justify-center"
      >
        <div class="absolute inset-0 bg-black/40"></div>
        <div
          @click.stop
          class="relative z-10 bg-white rounded-2xl shadow-2xl w-72 overflow-hidden"
        >
          <div class="px-2 py-2">
            <button
              @click="navigateTo('/portal/edit/new')"
              class="w-full flex items-center gap-3 px-4 py-3 rounded-xl hover:bg-gray-50 transition-colors text-left"
            >
              <span class="w-9 h-9 rounded-full flex items-center justify-center shrink-0" style="background:#8cc65d">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M12 4v16m8-8H4" />
                </svg>
              </span>
              <div>
                <p class="font-semibold text-gray-900 text-[15px]">Add Purpose</p>
                <p class="text-xs text-gray-400">Create a new portal</p>
              </div>
            </button>
            <button
              @click="navigateTo('/chat/group/new')"
              class="w-full flex items-center gap-3 px-4 py-3 rounded-xl hover:bg-gray-50 transition-colors text-left"
            >
              <span class="w-9 h-9 rounded-full flex items-center justify-center shrink-0" style="background:#8cc65d">
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
            <button
              @click="showActionSheet = false"
              class="w-full px-4 py-2.5 rounded-xl text-sm text-gray-500 hover:bg-gray-50 transition-colors text-center"
            >Cancel</button>
          </div>
        </div>
      </div>
    </Transition>

    <!-- Toast notification (permission errors etc.) -->
    <Transition
      enter-active-class="transition-all duration-300 ease-out"
      leave-active-class="transition-all duration-200 ease-in"
      enter-from-class="opacity-0 translate-y-2"
      leave-to-class="opacity-0 translate-y-2"
    >
      <div
        v-if="showToast"
        class="fixed bottom-6 left-1/2 -translate-x-1/2 z-50 flex items-center gap-2 px-5 py-3 bg-gray-900 text-white text-sm font-medium rounded-full shadow-xl pointer-events-none whitespace-nowrap"
      >
        <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
          <path stroke-linecap="round" stroke-linejoin="round" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
        </svg>
        {{ toastMessage }}
      </div>
    </Transition>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, nextTick, watch, onMounted, onUnmounted } from 'vue';
import { useRouter, RouterLink } from 'vue-router';
import api from '@/pages/utils/api';
import { isAuthenticated } from '@/utils/auth';
import { useSocketManager } from '../utils/useSocketManager';
import REPLogo from '@/assets/REPLogo.png';

// --- Types (minimal — just what this component needs) ---
interface User {
  id: number;
  full_name?: string;
  profile_picture_url?: string;
}
interface ChatModel { id: number; name?: string; }
interface MessageModel { id: number; text?: string; read?: string; sender_id?: number; created_at?: string; }
interface ActiveChat {
  id: string;
  type: 'direct' | 'group';
  user?: User;
  chat?: ChatModel;
  last_message?: MessageModel;
  last_message_time?: string;
}
interface Invite { id: number; }
interface Portal { id: number; name: string; subtitle?: string; mainImageUrl?: string; }

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

// Reactive auth check — derived from props.userId so Vue re-evaluates when parent updates after login
const isAuth = computed(() => props.userId > 0);

// --- Internal navigation ---
const handleProfileClick = () => {
  if (!isAuthenticated()) { router.push({ path: '/register', query: { returnTo: '/main' } }); return; }
  router.push(`/profile/${props.userId}`);
};

const handleAddClick = () => {
  if (!isAuthenticated()) { router.push({ path: '/register', query: { returnTo: '/main' } }); return; }
  showActionSheet.value = true;
};

const navigateTo = (path: string) => { showActionSheet.value = false; router.push(path); };

// --- Internal UI state ---
const showActionSheet = ref(false);

// Toast notification
const showToast = ref(false);
const toastMessage = ref('');
let toastTimer: ReturnType<typeof setTimeout> | null = null;
const triggerToast = (msg: string) => {
  if (toastTimer) clearTimeout(toastTimer);
  toastMessage.value = msg;
  showToast.value = true;
  toastTimer = setTimeout(() => { showToast.value = false; }, 3000);
};

// Left panel search (people: chats + network)
const showLeftSearch = ref(false);
const leftSearchText = ref('');

// Right panel search (portals)
const showSearch = ref(false);
const searchText = ref('');

// --- Left panel ---
const desktopLeftTab = ref<0 | 1 | 2>(0);
const desktopNetworkUsers = ref<User[]>([]);

const setLeftTab = (tab: 0 | 1 | 2) => {
  if (!isAuthenticated()) {
    router.push({ path: '/register', query: { returnTo: '/main' } });
    return;
  }
  desktopLeftTab.value = tab;
  leftSearchText.value = '';
  if (tab === 1) fetchDesktopNetworkUsers('ntwk');
  if (tab === 2) fetchDesktopNetworkUsers('all');
};

const fetchDesktopNetworkUsers = async (tab: 'ntwk' | 'all' = 'ntwk') => {
  if (!isAuthenticated()) return;
  try {
    const res = await api.get(`/api/filter_people?user_id=${props.userId}&tab=${tab}&limit=200`);
    desktopNetworkUsers.value = res.data.result || [];
  } catch { /* silent */ }
};

const desktopFilteredChats = computed(() => {
  const q = leftSearchText.value.trim().toLowerCase();
  if (!q) return props.filteredActiveChats;
  return props.filteredActiveChats.filter(c => {
    const name = c.type === 'direct'
      ? (c.user?.full_name || '')
      : (c.chat?.name || '');
    return name.toLowerCase().includes(q);
  });
});

const desktopFilteredNetworkUsers = computed(() => {
  const q = leftSearchText.value.trim().toLowerCase();
  if (!q) return desktopNetworkUsers.value;
  return desktopNetworkUsers.value.filter(u =>
    (u.full_name || '').toLowerCase().includes(q)
  );
});

// --- Right panel: portals ---
const desktopPortals = ref<Portal[]>([]);

const desktopFilteredPortals = computed(() => {
  if (!searchText.value.trim()) return desktopPortals.value;
  return desktopPortals.value.filter(p =>
    p.name.toLowerCase().includes(searchText.value.toLowerCase())
  );
});

// 0 = My portals (open), 1 = Network portals (ntwk), 2 = All portals (all)
// Default to All (public) when not logged in so public content loads immediately
const desktopRightTab = ref(2);

watch(desktopRightTab, () => {
  desktopPortals.value = [];
  portalCardImages.value = {};
  portalCardImageIndex.value = {};
  portalCardGoals.value = {};
  fetchDesktopPortals();
});

const isLoadingPortals = ref(false);

const fetchDesktopPortals = async () => {
  isLoadingPortals.value = true;
  try {
    const tab = ({ 0: 'open', 1: 'ntwk', 2: 'all' } as const)[desktopRightTab.value];
    const res = isAuthenticated()
      ? await api.get(`/api/portal/filter_network_portals?user_id=${props.userId}&tab=${tab}&limit=200`)
      : await api.get(`/api/public/portals?safe_only=false&limit=200`);
    desktopPortals.value = res.data.result || [];
    await nextTick();
    const el = portalListRef.value;
    if (el) isAtBottom.value = el.scrollHeight > el.clientHeight;
    setupPortalImageObserver();
  } catch { /* silent */ }
  finally { isLoadingPortals.value = false; }
};

// Re-observe whenever the filtered list changes (e.g. search input) so newly visible cards get loaded
watch(desktopFilteredPortals, async () => {
  await nextTick();
  setupPortalImageObserver();
});

// IntersectionObserver — loads portal images just before each card scrolls into view.
// Observes [data-portal-id] elements within the portal scroll container;
// unobserves each card once its images are fetched so it only fires once per card.
let portalImageObserver: IntersectionObserver | null = null;

const setupPortalImageObserver = () => {
  portalImageObserver?.disconnect();
  const container = portalListRef.value;
  if (!container) return;
  // Use the container's own height as the lookahead margin — one full visible
  // area of preload regardless of screen size or card height.
  const lookahead = `${container.clientHeight}px`;
  portalImageObserver = new IntersectionObserver(
    (entries) => {
      entries.forEach(entry => {
        if (!entry.isIntersecting) return;
        const portalId = Number((entry.target as HTMLElement).dataset.portalId);
        if (portalId) loadPortalCardData(portalId);
        portalImageObserver?.unobserve(entry.target);
      });
    },
    {
      root: container,
      rootMargin: `0px 0px ${lookahead} 0px`,
      threshold: 0
    }
  );
  container.querySelectorAll<HTMLElement>('[data-portal-id]').forEach(el => {
    portalImageObserver!.observe(el);
  });
};

const portalListRef = ref<HTMLElement | null>(null);
const isAtTop = ref(true);
const isAtBottom = ref(false);

const onPortalListScroll = () => {
  const el = portalListRef.value;
  if (!el) return;
  isAtTop.value = el.scrollTop <= 0;
  isAtBottom.value = el.scrollTop + el.clientHeight >= el.scrollHeight - 4;
};

const scrollPortalListBy = (direction: 1 | -1) => {
  portalListRef.value?.scrollBy({ top: direction * 195, behavior: 'smooth' });
};

// Per-portal card data — images + top 2 goals, loaded lazily via IntersectionObserver
const portalCardImages = ref<Record<number, string[]>>({});
const portalCardImageIndex = ref<Record<number, number>>({});
const portalCardGoals = ref<Record<number, any[]>>({});

const getCardImage = (portal: Portal): string =>
  portalCardImages.value[portal.id]?.[portalCardImageIndex.value[portal.id] ?? 0]
  ?? portal.mainImageUrl ?? '';

const prevCardImage = (portalId: number) => {
  const idx = portalCardImageIndex.value[portalId] ?? 0;
  if (idx > 0) portalCardImageIndex.value = { ...portalCardImageIndex.value, [portalId]: idx - 1 };
};

const nextCardImage = (portalId: number) => {
  const images = portalCardImages.value[portalId] ?? [];
  const idx = portalCardImageIndex.value[portalId] ?? 0;
  if (idx < images.length - 1) portalCardImageIndex.value = { ...portalCardImageIndex.value, [portalId]: idx + 1 };
};

// Load images + goals together using the public portal detail endpoint (works for all users,
// no separate auth-gated graphic_sections call needed)
const loadPortalCardData = async (portalId: number) => {
  if (portalCardImages.value[portalId]) return;
  try {
    const res = await api.get(`/api/public/portal/${portalId}`);
    const data = res.data.result;
    // Images
    const sections: any[] = data?.aSections || [];
    const main = sections.find((s: any) => s.title === 'Main Section');
    const urls = (main?.aFiles || []).map((f: any) => f.url).filter(Boolean);
    portalCardImages.value = { ...portalCardImages.value, [portalId]: urls };
    // Top 2 goals by recency (backend returns aGoals ordered by id DESC)
    const goals: any[] = data?.aGoals || [];
    portalCardGoals.value = { ...portalCardGoals.value, [portalId]: goals.slice(0, 3) };
  } catch { /* silent */ }
};

// Tracks which goal chat buttons are mid-creation to prevent double-clicks
const goalChatCreating = ref<Record<string, boolean>>({});
// Per-goal error message (e.g. not a team member)
const goalChatError = ref<Record<string, string>>({});

const showGoalChatError = (goalId: number, msg: string) => {
  goalChatError.value = { ...goalChatError.value, [goalId]: msg };
  setTimeout(() => {
    const updated = { ...goalChatError.value };
    delete updated[goalId];
    goalChatError.value = updated;
  }, 3500);
};

// Open or create a Goal Team chat in the inline pane.
// Only Goal Team members may message the team — mirrors GoalsDetailView behaviour.
const openGoalTeamChat = async (goal: any, portalName: string) => {
  if (!isAuthenticated()) {
    router.push({ path: '/register', query: { returnTo: '/main' } });
    return;
  }
  const key = goal.id;
  if (goalChatCreating.value[key]) return;
  goalChatCreating.value = { ...goalChatCreating.value, [key]: true };

  try {
    // Always fetch team details first — check membership before opening or creating any chat
    let memberIds: number[] = [];
    let isOnTeam = false;
    try {
      const teamRes = await api.get(`/api/goals/details?goals_id=${goal.id}`);
      const result = teamRes.data.result;
      const teamMembers: any[] = result?.team || [];
      const creatorId = result?.creatorId ?? goal.creatorId;
      isOnTeam = props.userId === creatorId ||
        teamMembers.some((m: any) => m.id === props.userId);
      memberIds = teamMembers
        .map((m: any) => m.id)
        .filter((id: any) => id && id !== props.userId);
    } catch { /* if fetch fails, fall through to backend enforcement */ }

    if (!isOnTeam) {
      triggerToast('Only Goal Team members can message this team.');
      return;
    }

    // Member confirmed — open existing chat or create a new one
    if (goal.chats_id) {
      loadInlineChat({ id: `group-${goal.chats_id}`, type: 'group', chat: { id: goal.chats_id, name: goal.title } });
      return;
    }

    const chatTitle = portalName ? `${portalName}: ${goal.title}` : goal.title;
    const res = await api.post('/api/message/manage_chat', { title: chatTitle, aAddIDs: memberIds });
    const newChatsId = res.data.chats_id;
    if (!newChatsId) throw new Error('No chats_id returned');
    api.post('/api/goals/link_chat', { goals_id: goal.id, chats_id: newChatsId }).catch(() => {});
    goal.chats_id = newChatsId;
    loadInlineChat({ id: `group-${newChatsId}`, type: 'group', chat: { id: newChatsId, name: chatTitle } });
  } catch (err: any) {
    const status = err?.response?.status;
    if (status === 403 || status === 401) {
      triggerToast('Only Goal Team members can message this team.');
    }
  } finally {
    goalChatCreating.value = { ...goalChatCreating.value, [key]: false };
  }
};

// --- Inline chat ---
const selectedChat = ref<ActiveChat | null>(null);
const inlineChatMessages = ref<any[]>([]);
const inlineChatInput = ref('');
const inlineChatLoading = ref(false);
const inlineChatScrollRef = ref<HTMLElement | null>(null);
const messageInputRef = ref<HTMLTextAreaElement | null>(null);

const growMessageInput = () => {
  const el = messageInputRef.value;
  if (!el) return;
  el.style.height = 'auto';
  el.style.height = Math.min(el.scrollHeight, 96) + 'px'; // cap at 4 lines (~96px)
};

const resetMessageInput = () => {
  const el = messageInputRef.value;
  if (!el) return;
  el.style.height = 'auto';
};

const scrollInlineChatToBottom = () => {
  nextTick(() => { const el = inlineChatScrollRef.value; if (el) el.scrollTop = el.scrollHeight; });
};

const loadInlineChat = async (chat: ActiveChat) => {
  // Leave previous group chat room, join new one
  if (selectedChat.value?.type === 'group' && selectedChat.value.chat?.id) {
    leaveChat(selectedChat.value.chat.id);
  }
  selectedChat.value = chat;
  if (chat.type === 'group' && chat.chat?.id) {
    joinChat(chat.chat.id);
  }
  inlineChatMessages.value = [];
  inlineChatLoading.value = true;
  try {
    if (chat.type === 'direct' && chat.user) {
      const res = await api.get(`/api/message/get_messages?users_id=${chat.user.id}&order=ASC&limit=200&mark_as_read=1`);
      inlineChatMessages.value = res.data.result?.messages || [];
    } else if (chat.type === 'group' && chat.chat) {
      const res = await api.get(`/api/message/group_chat?chats_id=${chat.chat.id}&limit=50`);
      inlineChatMessages.value = res.data.result?.messages || [];
    }
  } catch (err) {
    console.error('loadInlineChat error:', err);
  } finally {
    inlineChatLoading.value = false;
    scrollInlineChatToBottom();
  }
};

const sendInlineMessage = async () => {
  const text = inlineChatInput.value.trim();
  if (!text || !selectedChat.value) return;
  inlineChatInput.value = '';
  resetMessageInput();
  try {
    if (selectedChat.value.type === 'direct' && selectedChat.value.user) {
      const res = await api.post('/api/message/send_message', { users_id: selectedChat.value.user.id, message: text });
      if (res.data.message) {
        inlineChatMessages.value.push(res.data.message);
        scrollInlineChatToBottom();
        emit('refresh-chats'); // update sidebar order + preview text
      }
    } else if (selectedChat.value.type === 'group' && selectedChat.value.chat) {
      const res = await api.post('/api/message/send_chat_message', { chats_id: selectedChat.value.chat.id, message: text });
      if (res.data.message) {
        inlineChatMessages.value.push(res.data.message);
        scrollInlineChatToBottom();
        emit('refresh-chats'); // update sidebar order + preview text
      }
    }
  } catch (err) {
    console.error('sendInlineMessage error:', err);
    inlineChatInput.value = text;
    growMessageInput(); // restore height if send failed
  }
};

const inlineChatName = computed(() => {
  if (!selectedChat.value) return '';
  return selectedChat.value.type === 'direct'
    ? selectedChat.value.user?.full_name || 'Chat'
    : selectedChat.value.chat?.name || 'Group Chat';
});

const inlineChatAvatar = computed(() =>
  selectedChat.value?.type === 'direct' ? selectedChat.value.user?.profile_picture_url || null : null
);

const isInlineMessageFromMe = (msg: any) => (msg.sender_id ?? msg.senderId) === props.userId;
const getInlineMessageSenderName = (msg: any) => msg.sender_name || msg.senderName || '';

// Silently appends new messages from socket events without clearing the list or showing a loading flash.
// Deduplicates by message ID so re-fetching never causes duplicates.
const appendFromSocketIfNeeded = async (chat: ActiveChat) => {
  if (inlineChatLoading.value) return; // already loading, skip
  try {
    let incoming: any[] = [];
    if (chat.type === 'direct' && chat.user) {
      const res = await api.get(
        `/api/message/get_messages?users_id=${chat.user.id}&order=ASC&limit=200&mark_as_read=1`
      );
      incoming = res.data.result?.messages || [];
    } else if (chat.type === 'group' && chat.chat) {
      const res = await api.get(
        `/api/message/group_chat?chats_id=${chat.chat.id}&limit=50`
      );
      incoming = res.data.result?.messages || [];
    }
    const existingIds = new Set(inlineChatMessages.value.map((m: any) => m.id));
    const newMsgs = incoming.filter((m: any) => !existingIds.has(m.id));
    if (newMsgs.length > 0) {
      inlineChatMessages.value = [...inlineChatMessages.value, ...newMsgs];
      scrollInlineChatToBottom();
    }
  } catch { /* silent — socket refresh is best-effort */ }
};

// --- Utilities ---
const getInitials = (name: string) => {
  const parts = name.trim().split(' ');
  return parts.length >= 2
    ? (parts[0][0] + parts[parts.length - 1][0]).toUpperCase()
    : name.substring(0, 2).toUpperCase();
};

const timeAgoDisplay = (dateString: string | undefined): string => {
  if (!dateString) return '';
  try {
    const date = new Date(dateString);
    const diffMs = Date.now() - date.getTime();
    const diffSec = Math.floor(diffMs / 1000);
    const diffMin = Math.floor(diffSec / 60);
    const diffHour = Math.floor(diffMin / 60);
    const diffDay = Math.floor(diffHour / 24);
    if (diffSec < 60) return 'just now';
    if (diffMin < 60) return `${diffMin}m`;
    if (diffHour < 24) return `${diffHour}h`;
    if (diffDay < 7) return `${diffDay}d`;
    return date.toLocaleDateString(undefined, { month: 'short', day: 'numeric' });
  } catch { return dateString; }
};

// Auto-select the first chat so the inline pane is never a blank placeholder on load
watch(
  () => props.filteredActiveChats,
  (chats) => { if (!selectedChat.value && chats.length > 0) loadInlineChat(chats[0]); },
  { immediate: true }
);

// --- Real-time messaging ---
// Mirrors iOS MainScreen: subscribe to all three events, refresh sidebar + append to open chat.
// useSocketManager is a shared singleton — no duplicate connection created.
const { onDirectMessageNotification, onGroupMessage, onGroupMessageNotification, joinChat, leaveChat } = useSocketManager();

let unsubDM: (() => void) | null = null;
let unsubGroupMsg: (() => void) | null = null;
let unsubGroupNotif: (() => void) | null = null;

// Refresh sidebar after a short delay (matches iOS 0.3s pattern — lets backend settle)
const refreshChatsDelayed = () => setTimeout(() => emit('refresh-chats'), 300);

// --- Lifecycle ---
onMounted(() => {
  fetchDesktopPortals();

  // 1. DM received — refresh sidebar + append to open DM pane
  unsubDM = onDirectMessageNotification((payload: Record<string, any>) => {
    const senderId = Number(payload.sender_id ?? payload.senderId ?? -1);
    if (senderId === props.userId) return; // ignore own messages echoed back
    refreshChatsDelayed();
    if (!selectedChat.value || selectedChat.value.type !== 'direct') return;
    if (selectedChat.value.user?.id !== senderId) return;
    appendFromSocketIfNeeded(selectedChat.value);
  });

  // 2. Group message (fires when joined the chat room via joinChat)
  unsubGroupMsg = onGroupMessage((payload: Record<string, any>) => {
    const senderId = Number(payload.sender_id ?? payload.senderId ?? -1);
    if (senderId === props.userId) return;
    refreshChatsDelayed();
    const incomingChatId = Number(payload.chat_id ?? payload.chatId ?? -1);
    if (!selectedChat.value || selectedChat.value.type !== 'group') return;
    if (selectedChat.value.chat?.id !== incomingChatId) return;
    appendFromSocketIfNeeded(selectedChat.value);
  });

  // 3. Group notification (user-room broadcast — always fires for group members)
  unsubGroupNotif = onGroupMessageNotification((payload: Record<string, any>) => {
    const senderId = Number(payload.sender_id ?? payload.senderId ?? -1);
    if (senderId === props.userId) return;
    refreshChatsDelayed();
    const incomingChatId = Number(payload.chat_id ?? payload.chatId ?? -1);
    if (!selectedChat.value || selectedChat.value.type !== 'group') return;
    if (selectedChat.value.chat?.id !== incomingChatId) return;
    appendFromSocketIfNeeded(selectedChat.value);
  });
});

onUnmounted(() => {
  portalImageObserver?.disconnect();
  if (unsubDM) { unsubDM(); unsubDM = null; }
  if (unsubGroupMsg) { unsubGroupMsg(); unsubGroupMsg = null; }
  if (unsubGroupNotif) { unsubGroupNotif(); unsubGroupNotif = null; }
  // Leave any open group chat room
  if (selectedChat.value?.type === 'group' && selectedChat.value.chat?.id) {
    leaveChat(selectedChat.value.chat.id);
  }
});
</script>

<style scoped>

.slide-up-enter-active,
.slide-up-leave-active {
  transition: transform 0.25s ease-out;
}
.slide-up-enter-from,
.slide-up-leave-to {
  transform: translateY(100%);
}

.slide-down-enter-active,
.slide-down-leave-active {
  transition: transform 0.2s ease-out, opacity 0.2s ease-out;
}
.slide-down-enter-from,
.slide-down-leave-to {
  transform: translateY(-8px);
  opacity: 0;
}
</style>
