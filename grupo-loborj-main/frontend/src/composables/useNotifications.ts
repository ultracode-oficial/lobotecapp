import { useQuery, useMutation, useQueryClient } from '@tanstack/vue-query';
import { useNotificationStore } from '@/stores/notification';
import api from '@/services/api';
import { toValue, type MaybeRefOrGetter } from 'vue';

export interface AppNotification {
  id: number;
  title: string;
  body: string;
  is_read: boolean;
  read_at: string | null;
  created_at: string;
  routing: {
    resource: string;
    resource_id: string;
    action: string;
  };
}

// 1. Query para listagem (suporta filtro e paginação)
export function useNotificationsQuery(status: MaybeRefOrGetter<'all' | 'unread'> = 'all',
  page: MaybeRefOrGetter<number> = 1) {
  const store = useNotificationStore();

  return useQuery({
    queryKey: ['notifications', status, page],
    queryFn: async () => {
      const statusValue = toValue(status);
      const pageValue = toValue(page);

      const { data } = await api.get('/notifications', {
        params: { status: statusValue === 'all' ? undefined : statusValue, page: pageValue }
      });

      if (statusValue === 'all' && pageValue === 1) {
        store.setUnreadCount(data.unread);
      }

      return data;
    },
    staleTime: 60000,
  });
}

// 2. Mutation para marcar uma como lida
export function useMarkAsReadMutation() {
  const queryClient = useQueryClient();
  const store = useNotificationStore();

  return useMutation({
    mutationFn: async (id: number) => {
      await api.patch(`/notifications/${id}/read`);
    },
    onSuccess: () => {
      // Invalida para buscar novos dados
      queryClient.invalidateQueries({ queryKey: ['notifications'] });
      store.decrementCount();
    }
  });
}

// 3. Mutation para marcar todas como lidas
export function useMarkAllAsReadMutation() {
  const queryClient = useQueryClient();
  const store = useNotificationStore();

  return useMutation({
    mutationFn: async () => {
      await api.post('/notifications/read-all');
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['notifications'] });
      store.clearCount();
    }
  });
}