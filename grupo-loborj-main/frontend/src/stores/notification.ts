import { defineStore } from 'pinia';
import { ref } from 'vue';
import { useQueryClient } from '@tanstack/vue-query';
import { useAuthStore } from '@/stores/auth';
import echo from '@/services/echo';

export const useNotificationStore = defineStore('notifications', () => {
  const unreadCount = ref(0);
  const queryClient = useQueryClient();
  const authStore = useAuthStore();
  let channel: any = null;

  function setUnreadCount(count: number) {
    unreadCount.value = count;
  }

  function decrementCount() {
    if (unreadCount.value > 0) unreadCount.value--;
  }

  function clearCount() {
    unreadCount.value = 0;
  }

  function listenToNotifications() {
    if (!authStore.user?.id) return;

    // Conecta no canal privado do usuário
    channel = echo.private(`user.${authStore.user.id}`);

    channel.listen('.NotificationReceived', (payload: any) => {
      // 1. Aumenta o contador
      unreadCount.value++;

      // 2. Invalida as queries do TanStack Vue Query para forçar recarregamento nos componentes
      queryClient.invalidateQueries({ queryKey: ['notifications'] });

      // Opcional: Disparar um Toast/Snackbar de notificação push aqui
    });
  }

  function stopListening() {
    if (channel && authStore.user?.id) {
      echo.leave(`user.${authStore.user.id}`);
      channel = null;
    }
  }

  return {
    unreadCount,
    setUnreadCount,
    decrementCount,
    clearCount,
    listenToNotifications,
    stopListening
  };
});