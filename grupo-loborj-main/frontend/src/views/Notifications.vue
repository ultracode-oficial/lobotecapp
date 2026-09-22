<script setup lang="ts">
import { ref } from 'vue';
import { useRouter } from 'vue-router';
import { useNotificationsQuery, useMarkAsReadMutation, useMarkAllAsReadMutation, type AppNotification } from '@/composables/useNotifications';
import { resolveNotificationRoute } from '@/services/notificationRouter';
import { useRelativeTime } from '@/composables/useRelativeTime';
import { usePage } from '@/composables/usePage';
import { CheckIcon } from '@lucide/vue';

const router = useRouter();
const { setHeader } = usePage();
setHeader('Central de Notificações', 'Gerencie suas notificações da plataforma.');
const { getRelativeTime } = useRelativeTime();

// Estado Local
const activeTab = ref<'all' | 'unread'>('all');
const currentPage = ref(1);

// Queries e Mutations
const { data, isLoading, isError } = useNotificationsQuery(() => activeTab.value, () => currentPage.value);
const markAsRead = useMarkAsReadMutation();
const markAllAsRead = useMarkAllAsReadMutation();

// Ações
const handleTabChange = (tab: 'all' | 'unread') => {
  activeTab.value = tab;
  currentPage.value = 1;
};

const handleAction = async (notif: AppNotification) => {
  if (!notif.is_read) {
    await markAsRead.mutateAsync(notif.id);
  }
  const route = resolveNotificationRoute(notif.routing);
  router.push(route);
};

const handleMarkAsRead = async (id: number) => {
  await markAsRead.mutateAsync(id);
};

const handleMarkAll = async () => {
  await markAllAsRead.mutateAsync();
};
</script>

<template>
  <div class="max-w-7xl w-full mx-auto py-3">
    <!-- Tabs -->
    <div class="border-b border-slate-200 mb-6">
      <nav class="-mb-px flex space-x-8">
        <button @click="handleTabChange('all')"
          :class="[activeTab === 'all' ? 'border-blue-500 text-blue-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300', 'cursor-pointer pb-1 whitespace-nowrap px-1 border-b-2 font-medium text-sm transition-colors']">
          Todas as Notificações
        </button>
        <button @click="handleTabChange('unread')"
          :class="[activeTab === 'unread' ? 'border-blue-500 text-blue-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300', 'cursor-pointer pb-1 whitespace-nowrap px-1 border-b-2 font-medium text-sm transition-colors']">
          Apenas Não Lidas
        </button>
        <button @click="handleMarkAll" :disabled="markAllAsRead.isPending.value"
          class="ml-auto mb-2 disabled:bg-primary-muted disabled:cursor-not-allowed cursor-pointer rounded-md text-sm font-medium inline-flex items-center justify-center px-4 py-2 bg-primary active:bg-primary-active text-primary-contrast hover:bg-primary-hover transition-all">
          <CheckIcon class="size-4 mr-2 text-slate-400"></CheckIcon>
          Marcar todas como lidas
        </button>
      </nav>
    </div>

    <!-- State: Loading -->
    <div v-if="isLoading" class="py-12 flex justify-center">
      <svg class="animate-spin h-8 w-8 text-blue-600" xmlns="http://www.w3.org/2000/svg" fill="none"
        viewBox="0 0 24 24">
        <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
        <path class="opacity-75" fill="currentColor"
          d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z">
        </path>
      </svg>
    </div>

    <!-- State: Error -->
    <div v-else-if="isError" class="rounded-lg bg-red-50 p-4 border border-red-200">
      <div class="flex">
        <div class="shrink-0">
          <svg class="h-5 w-5 text-red-400" viewBox="0 0 20 20" fill="currentColor">
            <path fill-rule="evenodd"
              d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z"
              clip-rule="evenodd" />
          </svg>
        </div>
        <div class="ml-3">
          <h3 class="text-sm font-medium text-red-800">Erro ao carregar notificações</h3>
          <p class="text-sm text-red-700 mt-1">Por favor, verifique sua conexão ou tente novamente mais tarde.</p>
        </div>
      </div>
    </div>

    <!-- State: Empty -->
    <div v-else-if="data?.data?.length === 0"
      class="text-center py-16 px-4 sm:px-6 lg:px-8 border-2 border-dashed border-slate-200 rounded-xl bg-slate-50/50">
      <svg class="mx-auto h-12 w-12 text-slate-300" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5"
          d="M20 13V6a2 2 0 00-2-2H6a2 2 0 00-2 2v7m16 0v5a2 2 0 01-2 2H6a2 2 0 01-2-2v-5m16 0h-2.586a1 1 0 00-.707.293l-2.414 2.414a1 1 0 01-.707.293h-3.172a1 1 0 01-.707-.293l-2.414-2.414A1 1 0 006.586 13H4">
        </path>
      </svg>
      <h3 class="mt-4 text-sm font-semibold text-slate-900">Nenhuma notificação</h3>
      <p class="mt-1 text-sm text-slate-500">Tudo limpo por aqui! Você está em dia.</p>
    </div>

    <!-- Notification List -->
    <div v-else class="space-y-4">
      <div v-for="notif in data.data" :key="notif.id"
        class="group relative bg-white border rounded-xl p-5 shadow-sm transition-all hover:shadow-md flex flex-col sm:flex-row gap-4"
        :class="!notif.is_read ? 'border-blue-100 ring-1 ring-blue-50' : 'border-slate-200'">

        <!-- Indicador não lido lateral -->
        <div v-if="!notif.is_read" class="absolute left-0 top-0 bottom-0 w-1 bg-blue-500 rounded-l-xl"></div>

        <div class="flex-1">
          <div class="flex items-center justify-between mb-1">
            <h3 class="text-base font-semibold text-slate-900">{{ notif.title }}</h3>
            <span class="text-xs font-medium text-slate-500">{{ getRelativeTime(notif.created_at) }}</span>
          </div>
          <p class="text-sm text-slate-600 mb-4">{{ notif.body }}</p>

          <div class="flex items-center gap-3">
            <button @click="handleAction(notif)"
              class="inline-flex items-center text-sm font-medium text-blue-600 hover:text-blue-800 transition-colors">
              Acessar Recurso
              <svg class="ml-1 w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"></path>
              </svg>
            </button>

            <span class="text-slate-300" v-if="!notif.is_read">|</span>

            <button v-if="!notif.is_read" @click="handleMarkAsRead(notif.id)"
              class="cursor-pointer text-sm font-medium text-slate-500 hover:text-slate-700 transition-colors">
              Marcar como lida
            </button>
          </div>
        </div>
      </div>

      <!-- Paginação Simples -->
      <div v-if="data?.meta?.last_page > 1"
        class="pt-6 flex justify-between items-center border-t border-slate-200 mt-8">
        <button @click="currentPage--" :disabled="currentPage === 1"
          class="px-4 py-2 border border-slate-300 rounded-md shadow-sm text-sm font-medium text-slate-700 bg-white hover:bg-slate-50 disabled:opacity-50">
          Anterior
        </button>
        <span class="text-sm text-slate-500">Página {{ currentPage }} de {{ data.meta.last_page }}</span>
        <button @click="currentPage++" :disabled="currentPage === data.meta.last_page"
          class="px-4 py-2 border border-slate-300 rounded-md shadow-sm text-sm font-medium text-slate-700 bg-white hover:bg-slate-50 disabled:opacity-50">
          Próxima
        </button>
      </div>
    </div>
  </div>
</template>