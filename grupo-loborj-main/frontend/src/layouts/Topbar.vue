<script setup>
import { ref, onMounted, onUnmounted, computed } from 'vue';
import { useAuthStore } from '@/stores/auth';
import { useRouter } from 'vue-router';
import { usePage } from '@/composables/usePage';
import { useRelativeTime } from '@/composables/useRelativeTime';
import { STORAGE_PATH } from '@/services/storage';
import { featureFlags } from '@/services/featureFlags';
import { useNotificationStore } from '@/stores/notification';
import { useNotificationsQuery, useMarkAsReadMutation, useMarkAllAsReadMutation } from '@/composables/useNotifications';
import { resolveNotificationRoute } from '@/services/notificationRouter';
import { BellIcon, ChevronDown, CircleUserIcon, Loader2Icon, LockKeyholeIcon, LogOutIcon, ShieldUserIcon, TextAlignJustifyIcon, User2Icon, UserLockIcon, UserRoundPenIcon } from '@lucide/vue';
import EmptyBoxIcon from '@/components/icons/EmptyBoxIcon.vue';

const emit = defineEmits(['toggle-sidebar']);
const authStore = useAuthStore();
const router = useRouter();
const { pageTitle, pageSubtitle } = usePage();
const { getRelativeTime } = useRelativeTime();

const isNotifOpen = ref(false);
const isUserOpen = ref(false);
const notifStore = useNotificationStore();

const { data: notificationsData, isLoading: isLoadingNotifs } = useNotificationsQuery('all', 1);
const markAsRead = useMarkAsReadMutation();
const markAllAsRead = useMarkAllAsReadMutation();

const recentNotifications = computed(() => {
  return notificationsData.value?.data?.slice(0, 3) || [];
});

const handleLogout = () => {
  authStore.logout();
  router.push({ name: 'login' });
};

const closeDropdowns = (e) => {
  if (!e.target.closest('.dropdown-container')) {
    isNotifOpen.value = false;
    isUserOpen.value = false;
  }
};

onMounted(() => {
  document.addEventListener('click', closeDropdowns);
  notifStore.listenToNotifications();
});

onUnmounted(() => {
  document.removeEventListener('click', closeDropdowns);
  notifStore.stopListening();
});

const handleNotificationClick = async (notif) => {
  if (!notif.is_read) {
    await markAsRead.mutateAsync(notif.id);
  }
  isNotifOpen.value = false;

  // Roteamento baseado em intenção
  const route = resolveNotificationRoute(notif.routing);
  router.push(route);
};

const handleMarkAllAsRead = async () => {
  await markAllAsRead.mutateAsync();
  isNotifOpen.value = false;
};
</script>

<template>
  <header class="h-20 bg-white border-b border-slate-200 flex items-center justify-between px-6 z-10">

    <div class="flex items-center gap-4 relative">
      <button @click.stop="emit('toggle-sidebar')"
        class="cursor-pointer p-2 text-slate-500 hover:bg-slate-100 active:bg-slate-200 rounded-md">
        <text-align-justify-icon class="size-5"></text-align-justify-icon>
      </button>

      <div class="hidden md:block transition-all duration-300">
        <h1 class="text-xl font-semibold text-slate-800">{{ pageTitle }}</h1>
        <p class="text-sm text-slate-500" v-if="pageSubtitle">{{ pageSubtitle }}</p>
      </div>
    </div>

    <div class="flex items-center gap-4 dropdown-container relative">
      <span class="text-xs uppercase font-bold text-primary">{{ authStore.payload?.roles?.join(', ') }}</span>
      <div class="relative" v-if="featureFlags.enableNotifications">
        <button @click.stop="isNotifOpen = !isNotifOpen; isUserOpen = false"
          class="cursor-pointer relative p-2.5 text-slate-600 rounded-full bg-slate-200 hover:bg-slate-300 transition-colors focus:outline-none focus:ring-2 focus:ring-slate-200">
          <bell-icon class="size-5"></bell-icon>
          <span v-if="notifStore.unreadCount > 0"
            class="absolute top-1 right-1 bg-red-500 text-white text-[10px] font-bold px-1.5 py-0.5 rounded-full border-2 border-white transform translate-x-1/2 -translate-y-1/2">
            {{ notifStore.unreadCount > 99 ? '99+' : notifStore.unreadCount }}
          </span>
        </button>

        <!-- DROPDOWN DE NOTIFICAÇÕES -->
        <div v-if="isNotifOpen"
          class="absolute right-0 mt-3 w-80 bg-white border border-slate-200 rounded-lg shadow-xl overflow-hidden z-50 transform origin-top-right transition-all">
          <div class="flex items-center justify-between p-4 border-b border-slate-100 bg-slate-50/50">
            <h3 class="font-semibold text-slate-800">Notificações</h3>
            <button @click="handleMarkAllAsRead" v-if="notifStore.unreadCount > 0"
              class="text-xs font-medium text-blue-600 hover:text-blue-800 transition-colors">
              Marcar todas lidas
            </button>
          </div>

          <div class="max-h-80 overflow-y-auto">
            <div v-if="isLoadingNotifs" class="p-8 text-center text-slate-500">
              <loader2-icon class="animate-spin size-6 mx-auto mb-2 text-slate-400"></loader2-icon>
              Carregando...
            </div>

            <div v-else-if="recentNotifications.length === 0"
              class="p-8 text-center text-slate-500 flex flex-col items-center">
              <empty-box-icon class="size-10 text-slate-300 mb-2"></empty-box-icon>
              <p class="text-sm">Você não tem notificações no momento.</p>
            </div>

            <button v-else v-for="notif in recentNotifications" :key="notif.id" @click="handleNotificationClick(notif)"
              class="w-full text-left flex gap-3 p-4 hover:bg-slate-50 border-b border-slate-50 transition-colors relative"
              :class="!notif.is_read ? 'bg-blue-50/30' : ''">

              <!-- Bolinha de Não Lido -->
              <span v-if="!notif.is_read"
                class="absolute left-2 top-1/2 -translate-y-1/2 w-1.5 h-1.5 bg-blue-500 rounded-full"></span>

              <div class="pl-2 flex-1">
                <p class="font-medium text-sm text-slate-800" :class="!notif.is_read ? 'font-semibold' : ''">{{
                  notif.title }}</p>
                <p class="text-xs text-slate-500 mt-0.5 line-clamp-1">{{ notif.body }}</p>
                <p class="text-[10px] text-slate-400 mt-1 font-medium">{{ getRelativeTime(notif.created_at) }}</p>
              </div>
            </button>
          </div>

          <div class="p-3 border-t border-slate-100 text-center bg-slate-50">
            <router-link to="/notifications" @click="isNotifOpen = false"
              class="text-sm font-semibold text-slate-600 hover:text-blue-600 transition-colors">
              Ver Central de Notificações
            </router-link>
          </div>
        </div>
      </div>

      <div class="relative">
        <div class="flex flex-col items-end">
          <button @click.stop="isUserOpen = !isUserOpen; isNotifOpen = false"
            class="cursor-pointer flex items-center gap-2 pl-2 pr-3 py-1.5 rounded-full bg-slate-200 hover:bg-slate-300 transition-colors">
            <div class="w-7 h-7 rounded-full bg-slate-800 text-white flex items-center justify-center shrink-0">
              <img v-if="authStore.user?.photo" :src="`${STORAGE_PATH}${authStore.user?.photo}`" alt="Foto de Perfil"
                class="w-full h-full object-cover rounded-full" />
              <user2-icon class="size-5 text-slate-400"></user2-icon>
            </div>
            <chevron-down class="size-4 text-slate-600"></chevron-down>
          </button>
        </div>

        <div v-if="isUserOpen"
          class="absolute right-0 mt-3 w-56 bg-white border border-slate-200 rounded-md shadow-lg overflow-hidden z-50">
          <div class="py-1">
            <router-link to="/profile" class="flex items-center gap-3 px-4 py-3 hover:bg-slate-50 text-slate-800">
              <user-round-pen-icon class="size-5"></user-round-pen-icon>
              <span class="font-medium text-sm">Meu Perfil</span>
            </router-link>

            <router-link to="/security" class="flex items-center gap-3 px-4 py-3 hover:bg-slate-50 text-slate-800">
              <lock-keyhole-icon class="size-5"></lock-keyhole-icon>
              <span class="font-medium text-sm">Segurança da Conta</span>
            </router-link>
          </div>

          <div class="border-t border-slate-200 py-1">
            <button @click="handleLogout"
              class="cursor-pointer w-full flex items-center gap-3 px-4 py-3 hover:bg-red-50 text-red-500 transition-colors">
              <log-out-icon class="size-5"></log-out-icon>
              <span class="font-medium text-sm">Sair</span>
            </button>
          </div>
        </div>
      </div>
    </div>
  </header>
</template>