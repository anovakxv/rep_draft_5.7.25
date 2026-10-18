<!--
  PurposePageDesktop.vue
  Desktop layout of a Purpose (portal) page (lg+). Rendered by PortalPage.vue, which keeps
  all the data, actions and modals; this component only lays them out and emits intents.
  Phones keep PortalPage's own layout.

  Same structure as before (the pitch deck on the left, the tabs on the right), with the
  right column widened so Goal Teams and Story get real room:
    left  — the pitch deck, as large as fits, with thumbnails (stays put while you scroll)
    right — a compact Purpose header (name, event, Leads, actions), then the
            Goal Teams | Story toggle (sticky) over full-size content
  The open tab lives in the URL (?view=goals | story).
-->

<template>
  <div class="flex flex-col h-screen w-full bg-white">
    <!-- ===================== Top bar ===================== -->
    <header class="shrink-0 flex items-center gap-3 h-14 px-4 border-b border-gray-200" style="background-color: #f7f7f7">
      <button
        type="button"
        class="flex items-center gap-1 h-9 pl-1.5 pr-3 rounded text-sm font-medium text-gray-600 hover:bg-gray-200/60 hover:text-gray-900 shrink-0"
        @click="emit('back')"
      >
        <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" style="color: #8cc65d" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
          <path stroke-linecap="round" stroke-linejoin="round" d="M15 19l-7-7 7-7" />
        </svg>
        Purposes
      </button>
      <span class="text-gray-300">/</span>
      <span class="text-sm font-semibold text-gray-900 truncate min-w-0">{{ portal.name }}</span>

      <div class="ml-auto flex items-center gap-1 shrink-0">
        <!-- Leads manage it from here -->
        <button
          v-if="isAuth && isOwner"
          type="button"
          class="h-8 px-3 inline-flex items-center rounded-sm border border-gray-300 bg-white text-sm font-semibold text-gray-800 hover:bg-gray-50"
          @click="emit('edit')"
        >Edit Purpose</button>
        <button
          v-if="isAuth && isLead"
          type="button"
          class="h-8 px-3 inline-flex items-center rounded-sm border border-gray-300 bg-white text-sm font-semibold text-gray-800 hover:bg-gray-50"
          @click="emit('add-goal')"
        >+ Add Goal</button>
        <button
          type="button"
          class="h-9 px-3 inline-flex items-center gap-1.5 rounded text-sm font-medium text-gray-700 hover:bg-gray-200/60"
          @click="emit('share')"
        >
          <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M8.684 13.342C8.886 12.938 9 12.482 9 12c0-.482-.114-.938-.316-1.342m0 2.684a3 3 0 110-2.684m0 2.684l6.632 3.316m-6.632-6l6.632-3.316m0 0a3 3 0 105.367-2.684 3 3 0 00-5.367 2.684zm0 9.316a3 3 0 105.368 2.684 3 3 0 00-5.368-2.684z" /></svg>
          Share
        </button>
        <div v-if="isAuth" class="relative">
          <button
            type="button"
            class="w-9 h-9 rounded flex items-center justify-center text-gray-500 hover:bg-gray-200/60 hover:text-gray-800"
            aria-label="More options"
            :aria-expanded="showMenu"
            @click="showMenu = !showMenu"
          >
            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor"><path d="M6 10a2 2 0 11-4 0 2 2 0 014 0zM12 10a2 2 0 11-4 0 2 2 0 014 0zM16 12a2 2 0 100-4 2 2 0 000 4z" /></svg>
          </button>
          <div v-if="showMenu" class="fixed inset-0 z-30" @click="showMenu = false"></div>
          <div v-if="showMenu" role="menu" class="absolute right-0 top-full mt-1 z-40 w-52 bg-white rounded shadow-xl border border-gray-100 py-1">
            <button role="menuitem" class="w-full text-left px-4 py-2.5 text-sm text-red-600 hover:bg-red-50" @click="showMenu = false; emit('flag')">
              Flag as inappropriate
            </button>
          </div>
        </div>
      </div>
    </header>

    <div class="flex flex-1 min-h-0">
      <!-- ===================== LEFT: the pitch deck ===================== -->
      <!-- Charcoal "screening room": light slides read as a clear screen, thumbnails stand out -->
      <section class="flex-1 min-w-0 flex flex-col bg-[#141414]" aria-label="Pitch deck">
        <div class="flex-1 min-h-0 flex items-center justify-center px-6 pt-6 pb-3">
          <div
            v-if="slides.length"
            class="relative aspect-video bg-black rounded-sm overflow-hidden shadow-2xl group"
            :style="{ width: 'min(100%, calc((100vh - 200px) * 16 / 9))' }"
          >
            <img
              :src="slides[slide]"
              :alt="`${portal.name}, slide ${slide + 1}`"
              class="absolute inset-0 w-full h-full object-contain cursor-zoom-in select-none"
              draggable="false"
              @click="emit('open-fullscreen', slide)"
            />
            <span v-if="slides.length > 1" class="absolute top-3 right-3 px-2 py-0.5 rounded-sm bg-black/55 text-white text-xs font-medium">{{ slide + 1 }} / {{ slides.length }}</span>
            <button
              v-if="slide > 0"
              type="button"
              aria-label="Previous slide"
              class="absolute left-3 top-1/2 -translate-y-1/2 w-10 h-10 rounded-full bg-black/40 hover:bg-black/70 text-white flex items-center justify-center"
              @click="step(-1)"
            >
              <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5"><path stroke-linecap="round" stroke-linejoin="round" d="M15 19l-7-7 7-7" /></svg>
            </button>
            <button
              v-if="slide < slides.length - 1"
              type="button"
              aria-label="Next slide"
              class="absolute right-3 top-1/2 -translate-y-1/2 w-10 h-10 rounded-full bg-black/40 hover:bg-black/70 text-white flex items-center justify-center"
              @click="step(1)"
            >
              <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5"><path stroke-linecap="round" stroke-linejoin="round" d="M9 5l7 7-7 7" /></svg>
            </button>
            <button
              type="button"
              aria-label="View fullscreen"
              title="Fullscreen"
              class="absolute bottom-3 right-3 w-9 h-9 rounded-sm bg-black/55 hover:bg-black/75 text-white flex items-center justify-center opacity-0 group-hover:opacity-100 transition"
              @click="emit('open-fullscreen', slide)"
            >
              <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M4 9V5a1 1 0 011-1h4M20 9V5a1 1 0 00-1-1h-4M4 15v4a1 1 0 001 1h4M20 15v4a1 1 0 01-1 1h-4" /></svg>
            </button>
          </div>
          <div v-else class="text-center">
            <p class="font-semibold text-gray-300">No pitch deck yet</p>
            <button v-if="isOwner" type="button" class="mt-2 text-sm font-semibold hover:underline" style="color: #8cc65d" @click="emit('edit')">Add slides</button>
          </div>
        </div>

        <!-- Thumbnails -->
        <div v-if="slides.length > 1" class="shrink-0 px-6 pb-5">
          <div class="flex gap-2 justify-center overflow-x-auto py-1">
            <button
              v-for="(url, i) in slides"
              :key="i"
              type="button"
              :aria-label="`Slide ${i + 1}`"
              :aria-current="i === slide ? 'true' : undefined"
              class="shrink-0 w-20 aspect-video bg-black rounded-sm overflow-hidden ring-offset-2 ring-offset-[#141414] transition"
              :class="i === slide ? 'ring-2 ring-[#8cc65d]' : 'opacity-50 hover:opacity-100'"
              @click="slide = i"
            >
              <img :src="url" alt="" loading="lazy" class="w-full h-full object-contain" />
            </button>
          </div>
        </div>
      </section>

      <!-- ===================== RIGHT: Purpose + Goal Teams | Story ===================== -->
      <section
        ref="rightRef"
        class="w-[44%] min-w-[460px] max-w-[680px] shrink-0 border-l border-gray-200 overflow-y-auto bg-white"
      >
        <!-- Compact Purpose header -->
        <div class="px-6 pt-5 pb-4">
          <h1 class="text-2xl font-bold text-gray-900 leading-tight">{{ portal.name }}</h1>
          <p v-if="portal.subtitle?.trim()" class="mt-1 text-[15px] text-gray-600 leading-snug">{{ portal.subtitle }}</p>

          <!-- Event · Leads, on one line where it fits -->
          <div v-if="isEvent || leads.length" class="mt-3 flex flex-wrap items-center gap-x-5 gap-y-2 text-sm text-gray-700">
            <span v-if="portal.event_datetime" class="flex items-center gap-1.5">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 shrink-0" style="color: #006600" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" /></svg>
              {{ eventWhenShort }}
            </span>
            <span v-if="portal.event_location" class="flex items-center gap-1.5 min-w-0">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 shrink-0" style="color: #006600" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" /><path stroke-linecap="round" stroke-linejoin="round" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" /></svg>
              <span class="truncate">{{ portal.event_location }}</span>
            </span>
            <span v-if="leads.length" class="flex items-center gap-2">
              <span class="flex -space-x-1.5">
                <RouterLink
                  v-for="lead in leads.slice(0, 4)"
                  :key="lead.id"
                  :to="`/profile/${lead.id}`"
                  :title="leadName(lead)"
                  class="w-7 h-7 rounded-full ring-2 ring-white overflow-hidden bg-gray-300 flex items-center justify-center text-white text-[10px] font-semibold hover:z-10"
                >
                  <img v-if="lead.profile_picture_url" :src="lead.profile_picture_url" alt="" class="w-full h-full object-cover" />
                  <template v-else>{{ getInitials(leadName(lead)) }}</template>
                </RouterLink>
              </span>
              <span>Led by <span class="font-semibold text-gray-900">{{ leadSummary }}</span></span>
            </span>
          </div>

          <!-- Actions: one row -->
          <div class="mt-4 flex items-center gap-2">
            <button
              v-if="attendeesGoal && !isEventRegistered"
              type="button"
              class="flex-1 h-10 rounded-sm text-sm font-bold text-white hover:opacity-90"
              style="background-color: #8cc65d"
              @click="emit('rsvp')"
            >Register for Event</button>

            <div v-else-if="isEventRegistered && portal.event_datetime" class="relative flex-1">
              <button
                type="button"
                class="w-full h-10 inline-flex items-center justify-center gap-2 rounded-sm text-sm font-bold text-white hover:opacity-90"
                style="background-color: #006600"
                :aria-expanded="showCalendar"
                @click="showCalendar = !showCalendar"
              >
                <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" /></svg>
                Registered · Add to Calendar
              </button>
              <div v-if="showCalendar" class="fixed inset-0 z-30" @click="showCalendar = false"></div>
              <div v-if="showCalendar" class="absolute left-0 right-0 top-full mt-1 z-40 bg-white rounded shadow-xl border border-gray-100 py-1">
                <a v-if="googleCalUrl" :href="googleCalUrl" target="_blank" rel="noopener noreferrer" class="block px-4 py-2.5 text-sm font-semibold hover:bg-gray-50" style="color: #006600" @click="showCalendar = false">Google Calendar</a>
                <a :href="icsUrl" class="block px-4 py-2.5 text-sm font-semibold hover:bg-gray-50" style="color: #006600" @click="showCalendar = false">Apple Calendar</a>
                <a :href="icsUrl" class="block px-4 py-2.5 text-sm font-semibold hover:bg-gray-50" style="color: #006600" @click="showCalendar = false">Microsoft / Outlook</a>
              </div>
            </div>

            <template v-else-if="supportersGoal && !attendeesGoal">
              <span v-if="supportersGoal.is_member" class="flex-1 h-10 inline-flex items-center justify-center rounded-sm border text-sm font-semibold" style="border-color: #006600; color: #006600">
                ✓ You’re a Supporter
              </span>
              <button
                v-else
                type="button"
                class="flex-1 h-10 rounded-sm text-sm font-bold text-white hover:opacity-90"
                style="background-color: #8cc65d"
                @click="emit('join-supporters')"
              >Join Supporters</button>
            </template>

            <button
              v-if="supportGoal"
              type="button"
              class="h-10 px-4 inline-flex items-center justify-center gap-1 rounded-sm border text-sm font-semibold hover:bg-[#f3f9ee]"
              :class="hasPrimary ? '' : 'flex-1'"
              style="border-color: #006600; color: #006600"
              @click="emit('support')"
            ><span class="font-bold">$</span> Support</button>
            <button
              v-if="goals.length"
              type="button"
              class="h-10 px-4 inline-flex items-center justify-center rounded-sm border text-sm font-semibold hover:bg-[#f3f9ee]"
              :class="hasPrimary ? '' : 'flex-1'"
              style="border-color: #006600; color: #006600"
              @click="emit('join-team')"
            >Join a Team</button>
            <button
              type="button"
              class="h-10 px-3 inline-flex items-center justify-center gap-1.5 rounded-sm border border-gray-300 text-sm font-semibold text-gray-800 hover:bg-gray-50"
              title="Message the lead"
              aria-label="Message the lead"
              @click="emit('message')"
            >
              <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" /></svg>
              <span v-if="!hasPrimary && !supportGoal && !goals.length">Message the lead</span>
            </button>
          </div>
        </div>

        <!-- Goal Teams | Story: full width, sticky -->
        <div ref="tabsRef" class="sticky top-0 z-10 bg-white px-6 pt-1 pb-3 border-b border-gray-100">
          <div class="flex border border-black rounded-sm overflow-hidden" role="tablist" aria-label="Purpose content">
            <button
              v-for="t in tabs"
              :key="t.id"
              type="button"
              role="tab"
              :aria-selected="tab === t.id"
              class="flex-1 h-9 text-sm font-semibold border-l border-black first:border-l-0 transition-colors"
              :class="tab === t.id ? 'bg-black text-white' : 'bg-white text-black hover:bg-gray-50'"
              @click="selectTab(t.id)"
            >
              {{ t.label }}
              <span v-if="t.count !== undefined" class="ml-0.5 font-normal" :class="tab === t.id ? 'text-white/70' : 'text-gray-400'">{{ t.count }}</span>
            </button>
          </div>
        </div>

        <!-- ---------- Goal Teams ---------- -->
        <div v-if="tab === 'goals'" class="px-6 pt-4 pb-8 bg-[#f7f7f7] min-h-full">
          <div v-if="goals.length" class="flex items-center justify-between mb-3 text-sm">
            <span class="text-gray-500">{{ goals.length }} Goal Team{{ goals.length === 1 ? '' : 's' }} · <span class="font-semibold text-gray-900">{{ avgProgress }}%</span> average progress</span>
          </div>
          <div v-if="!goals.length" class="bg-white border border-gray-200 rounded p-10 text-center text-sm text-gray-500">
            No Goal Teams for this Purpose yet.
          </div>
          <div v-else class="space-y-3">
            <GoalCard
              v-for="g in sortedGoals"
              :key="g.id"
              :goal="g"
              :team="teams[g.id]"
              :show-message="isAuth"
              :busy="busyGoalId === g.id"
              :highlight="supportersGoal && g.id === supportersGoal.id ? 'Supporters' : undefined"
              @message="messageTeam"
            />
          </div>
        </div>

        <!-- ---------- Story ---------- -->
        <div v-else class="px-6 pt-5 pb-10 space-y-6">
          <!-- Event details -->
          <section v-if="isEvent" class="rounded-sm border border-gray-200 bg-[#f7f7f7] px-5 py-4 space-y-2.5">
            <div v-if="portal.event_datetime" class="flex items-start gap-3">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 mt-0.5 shrink-0" style="color: #006600" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8"><path stroke-linecap="round" stroke-linejoin="round" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" /></svg>
              <div>
                <p class="font-semibold text-gray-900">{{ eventWhen }}</p>
                <p v-if="portal.event_timezone" class="text-xs text-gray-500 mt-0.5">{{ portal.event_timezone }}</p>
              </div>
            </div>
            <div v-if="portal.event_location" class="flex items-start gap-3">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 mt-0.5 shrink-0" style="color: #006600" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8"><path stroke-linecap="round" stroke-linejoin="round" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" /><path stroke-linecap="round" stroke-linejoin="round" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" /></svg>
              <p class="font-semibold text-gray-900">{{ portal.event_location }}</p>
            </div>
          </section>

          <!-- The story -->
          <p v-if="!storyTexts.length" class="text-gray-500">
            No story yet.
            <button v-if="isOwner" type="button" class="ml-1 font-semibold hover:underline" style="color: #006600" @click="emit('edit')">Write it</button>
          </p>
          <article v-for="(block, i) in storyTexts" :key="block.id ?? i" :class="i ? 'pt-6 border-t border-gray-100' : ''">
            <h2 v-if="block.title" class="text-xl font-bold text-gray-900 leading-snug">{{ block.title }}</h2>
            <p v-if="block.text" class="text-[16px] text-gray-800 leading-relaxed whitespace-pre-line break-words" :class="block.title ? 'mt-2.5' : ''">
              <template v-for="(seg, j) in linkSegments(block.text)" :key="j">
                <a v-if="seg.href" :href="seg.href" target="_blank" rel="noopener noreferrer" class="text-blue-600 underline hover:text-blue-800">{{ seg.text }}</a>
                <template v-else>{{ seg.text }}</template>
              </template>
            </p>
          </article>

          <!-- Leads, as people -->
          <section v-if="leads.length" class="pt-6 border-t border-gray-100">
            <h3 class="text-[11px] font-semibold uppercase tracking-wide text-gray-400">Leads</h3>
            <div class="mt-3 grid grid-cols-2 gap-2">
              <RouterLink
                v-for="lead in leads"
                :key="lead.id"
                :to="`/profile/${lead.id}`"
                class="flex items-center gap-3 rounded-sm border border-gray-200 px-3 py-2.5 hover:border-gray-300 hover:bg-gray-50"
              >
                <img v-if="lead.profile_picture_url" :src="lead.profile_picture_url" alt="" class="w-10 h-10 rounded-full object-cover shrink-0" />
                <span v-else class="w-10 h-10 rounded-full bg-gray-300 flex items-center justify-center text-white text-sm font-semibold shrink-0">{{ getInitials(leadName(lead)) }}</span>
                <span class="text-sm font-semibold text-gray-900 truncate">{{ leadName(lead) }}</span>
              </RouterLink>
            </div>
          </section>

          <!-- Galleries -->
          <section v-for="g in galleries" :key="g.id" class="pt-6 border-t border-gray-100">
            <h3 class="font-bold text-lg text-gray-900">{{ g.title }}</h3>
            <div class="mt-3 grid grid-cols-2 gap-2">
              <button
                v-for="(file, i) in g.aFiles"
                :key="file.id ?? i"
                type="button"
                class="aspect-video bg-gray-100 rounded-sm overflow-hidden hover:opacity-90"
                @click="openGallery(g, i)"
              >
                <img :src="file.url" alt="" loading="lazy" class="w-full h-full object-contain" />
              </button>
            </div>
          </section>
        </div>
      </section>
    </div>

    <!-- Gallery lightbox -->
    <Transition name="fade">
      <div v-if="lightbox" class="fixed inset-0 z-50 bg-black/95 flex items-center justify-center" @click="lightbox = null">
        <button type="button" class="absolute top-4 right-4 w-10 h-10 text-white text-3xl leading-none" aria-label="Close" @click.stop="lightbox = null">×</button>
        <button
          v-if="lightbox.index > 0"
          type="button"
          aria-label="Previous image"
          class="absolute left-4 top-1/2 -translate-y-1/2 w-12 h-12 rounded-full bg-white/10 hover:bg-white/20 text-white text-3xl"
          @click.stop="lightbox.index--"
        >‹</button>
        <img :src="lightbox.urls[lightbox.index]" alt="" class="max-w-[90vw] max-h-[85vh] object-contain" @click.stop />
        <button
          v-if="lightbox.index < lightbox.urls.length - 1"
          type="button"
          aria-label="Next image"
          class="absolute right-4 top-1/2 -translate-y-1/2 w-12 h-12 rounded-full bg-white/10 hover:bg-white/20 text-white text-3xl"
          @click.stop="lightbox.index++"
        >›</button>
        <span class="absolute bottom-6 text-white/70 text-sm">{{ lightbox.index + 1 }} / {{ lightbox.urls.length }}</span>
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
        v-if="toast"
        role="status"
        class="fixed bottom-6 left-1/2 -translate-x-1/2 z-50 px-5 py-3 bg-gray-900 text-white text-sm font-medium rounded-full shadow-xl pointer-events-none whitespace-nowrap"
      >{{ toast }}</div>
    </Transition>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch, onMounted, onUnmounted } from 'vue';
import { useRoute, useRouter, RouterLink } from 'vue-router';
import api from '@/pages/utils/api';
import GoalCard from './GoalCard.vue';
import { getInitials } from '@/pages/utils/desktopShell';
import { openGoalTeamChat } from '@/pages/utils/goalTeamChat';

type Tab = 'goals' | 'story';

const props = defineProps<{
  portal: any;
  goals: any[];
  supportersGoal?: any | null;
  attendeesGoal?: any | null;
  supportGoal?: any | null;
  isLead: boolean;
  isOwner: boolean;
  isEventRegistered: boolean;
  isAuth: boolean;
  userId: number;
  googleCalUrl: string;
  icsUrl: string;
}>();

const emit = defineEmits<{
  (e: 'back'): void;
  (e: 'rsvp'): void;
  (e: 'join-supporters'): void;
  (e: 'message'): void;
  (e: 'support'): void;
  (e: 'join-team'): void;
  (e: 'share'): void;
  (e: 'edit'): void;
  (e: 'add-goal'): void;
  (e: 'flag'): void;
  (e: 'open-fullscreen', index: number): void;
}>();

const route = useRoute();
const router = useRouter();

const showMenu = ref(false);
const showCalendar = ref(false);
const rightRef = ref<HTMLElement | null>(null);
const tabsRef = ref<HTMLElement | null>(null);

// --- Toast ---
const toast = ref('');
let toastTimer: ReturnType<typeof setTimeout> | null = null;
function showToast(message: string) {
  if (toastTimer) clearTimeout(toastTimer);
  toast.value = message;
  toastTimer = setTimeout(() => { toast.value = ''; }, 3000);
}

// --- Event ---
const isEvent = computed(() => props.portal.portal_type === 'event' && !!(props.portal.event_datetime || props.portal.event_location));

// --- Tabs (in the URL). Like mobile: Goal Teams first, Story first for events ---
const isTab = (v: unknown): v is Tab => v === 'goals' || v === 'story';
const tab = ref<Tab>(isTab(route.query.view) ? route.query.view : isEvent.value ? 'story' : 'goals');

watch(() => route.query.view, (v) => {
  if (isTab(v)) tab.value = v;
});

const tabs = computed<Array<{ id: Tab; label: string; count?: number }>>(() => [
  { id: 'goals', label: 'Goal Teams', count: props.goals.length },
  { id: 'story', label: 'Story' },
]);

function selectTab(next: Tab) {
  tab.value = next;
  if (route.query.view !== next) router.replace({ query: { ...route.query, view: next } });
  // If the toggle is stuck to the top, start the new tab from its beginning
  const col = rightRef.value;
  const bar = tabsRef.value;
  if (col && bar && col.scrollTop > 0) {
    const header = bar.previousElementSibling as HTMLElement | null;
    const top = header ? header.offsetHeight : 0;
    if (col.scrollTop > top) col.scrollTo({ top });
  }
}

// --- Pitch deck ---
const slides = computed<string[]>(() =>
  (props.portal.aSections || [])
    .filter((s: any) => s.title === 'Main Section')
    .flatMap((s: any) => s.aFiles || [])
    .map((f: any) => f.url)
    .filter(Boolean)
);
const slide = ref(0);
watch(slides, () => { if (slide.value >= slides.value.length) slide.value = 0; });

function step(delta: number) {
  slide.value = Math.min(Math.max(slide.value + delta, 0), slides.value.length - 1);
}

// ← → flip slides (not while typing or viewing a gallery image)
function onKeydown(e: KeyboardEvent) {
  if (lightbox.value) return;
  if ((e.target as HTMLElement)?.closest?.('input, textarea, [contenteditable]')) return;
  if (e.key === 'ArrowRight') step(1);
  else if (e.key === 'ArrowLeft') step(-1);
}

// --- People ---
const leads = computed<any[]>(() => props.portal.aLeads || []);
function leadName(lead: any): string {
  return [lead.fname, lead.lname].filter(Boolean).join(' ') || lead.full_name || 'Lead';
}
const leadSummary = computed(() => {
  const names = leads.value.map((l) => l.fname || leadName(l));
  if (names.length <= 2) return names.join(' & ');
  return `${names.slice(0, 2).join(', ')} +${names.length - 2}`;
});

// --- Actions ---
const hasPrimary = computed(
  () =>
    !!(props.attendeesGoal && !props.isEventRegistered) ||
    !!(props.isEventRegistered && props.portal.event_datetime) ||
    !!(props.supportersGoal && !props.attendeesGoal)
);

// --- Goal Teams ---
function goalPct(g: any): number {
  const raw = g.progressPercent ?? (g.progress ?? 0) * 100;
  return Math.round(Math.min(100, Math.max(0, Number(raw) || 0)));
}

// Supporters first, as on mobile
const sortedGoals = computed(() => {
  const s = props.supportersGoal;
  if (!s) return props.goals;
  return [...props.goals.filter((g) => g.id === s.id), ...props.goals.filter((g) => g.id !== s.id)];
});

const avgProgress = computed(() => {
  if (!props.goals.length) return 0;
  return Math.round(props.goals.reduce((sum, g) => sum + goalPct(g), 0) / props.goals.length);
});

// Team avatars on Goal Team cards (members only; one request per team)
const teams = ref<Record<number, any[]>>({});
const busyGoalId = ref<number | null>(null);

function loadTeams() {
  if (!props.isAuth) return;
  props.goals.slice(0, 12).forEach(async (g) => {
    if (teams.value[g.id]) return;
    try {
      const res = await api.get(`/api/goals/details?goals_id=${g.id}`);
      teams.value = { ...teams.value, [g.id]: res.data?.result?.team || [] };
    } catch {
      // Avatars are a nicety; the card works without them.
    }
  });
}

watch(() => props.goals.map((g) => g.id).join(','), loadTeams, { immediate: true });

async function messageTeam(goal: any) {
  if (busyGoalId.value) return;
  busyGoalId.value = goal.id;
  try {
    const chat = await openGoalTeamChat(goal, props.portal.name, props.userId);
    router.push(`/chat/group/${chat.id}`); // opens in the dashboard on desktop
  } catch (e: any) {
    showToast(e?.message || 'Couldn’t open the Goal Team chat.');
  } finally {
    busyGoalId.value = null;
  }
}

// --- Story ---
const storyTexts = computed<any[]>(() =>
  (props.portal.aTexts || [])
    .filter((t: any) => (t.section || '') === 'story')
    .sort((a: any, b: any) => (a.position ?? 0) - (b.position ?? 0))
);

const galleries = computed<any[]>(() =>
  (props.portal.aSections || [])
    .filter((s: any) => s.title !== 'Main Section' && s.aFiles?.length)
    .sort((a: any, b: any) => (a.position || 0) - (b.position || 0))
);

const lightbox = ref<{ urls: string[]; index: number } | null>(null);

function openGallery(gallery: any, index: number) {
  lightbox.value = { urls: (gallery.aFiles || []).map((f: any) => f.url).filter(Boolean), index };
}

// Plain text with clickable links (rendered as text nodes, never as HTML)
function linkSegments(text: string): Array<{ text: string; href?: string }> {
  const out: Array<{ text: string; href?: string }> = [];
  const urlRegex = /(https?:\/\/[^\s]+)|(www\.[^\s]+)/gi;
  let last = 0;
  let match: RegExpExecArray | null;
  while ((match = urlRegex.exec(text)) !== null) {
    if (match.index > last) out.push({ text: text.slice(last, match.index) });
    const url = match[0];
    out.push({ text: url, href: url.startsWith('www.') ? `https://${url}` : url });
    last = match.index + url.length;
  }
  if (last < text.length) out.push({ text: text.slice(last) });
  return out;
}

// --- Event formatting ---
function formatWhen(opts: Intl.DateTimeFormatOptions): string {
  const dt = props.portal.event_datetime;
  if (!dt) return '';
  try {
    const options = { ...opts };
    if (props.portal.event_timezone) {
      try {
        Intl.DateTimeFormat('en-US', { timeZone: props.portal.event_timezone });
        options.timeZone = props.portal.event_timezone;
      } catch {
        // Unknown time zone: fall back to the viewer's
      }
    }
    return new Intl.DateTimeFormat('en-US', options).format(new Date(dt));
  } catch {
    return dt;
  }
}

const eventWhen = computed(() =>
  formatWhen({ weekday: 'long', year: 'numeric', month: 'long', day: 'numeric', hour: 'numeric', minute: '2-digit', hour12: true })
);
const eventWhenShort = computed(() =>
  formatWhen({ weekday: 'short', month: 'short', day: 'numeric', hour: 'numeric', minute: '2-digit', hour12: true })
);

onMounted(() => window.addEventListener('keydown', onKeydown));
onUnmounted(() => {
  window.removeEventListener('keydown', onKeydown);
  if (toastTimer) clearTimeout(toastTimer);
});
</script>
