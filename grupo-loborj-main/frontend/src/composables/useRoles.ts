import { useQuery, useMutation, useQueryClient } from '@tanstack/vue-query';
import api from '@/services/api';
import { toValue, type MaybeRefOrGetter } from 'vue';

export interface Role {
  id: number;
  name: string;
  permissions?: Array<{ id: number; name: string }>;
}

// Lista Roles
export function useRolesQuery(params: MaybeRefOrGetter<any>) {
  return useQuery({
    queryKey: ['roles', params],
    queryFn: async () => {
      const cleanParams = Object.fromEntries(
        Object.entries(toValue(params)).filter(([_, v]) => v !== '' && v !== null)
      );
      const { data } = await api.get('/roles', { params: cleanParams });
      return data;
    },
    placeholderData: (prev) => prev,
  });
}

// Busca uma única Role
export function useRoleQuery(id: number | string) {
  return useQuery({
    queryKey: ['roles', id],
    queryFn: async () => {
      const { data } = await api.get(`/roles/${id}`);
      return data.data;
    },
    enabled: !!id,
  });
}

// Busca opções de permissions
export function usePermissionsQuery() {
  return useQuery({
    queryKey: ['permissions'],
    queryFn: async () => {
      const { data } = await api.get('/roles-options', {
        params: { per_page: 1000 }
      });
      return data.permissions;
    },
    staleTime: 60000,
  });
}

// Mutations
export function useCreateRoleMutation() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (payload: any) => await api.post('/roles', payload),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['roles'] })
  });
}

export function useUpdateRoleMutation() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async ({ id, payload }: { id: string | number, payload: any }) =>
      await api.put(`/roles/${id}`, payload),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['roles'] })
  });
}

export function useDeleteRoleMutation() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (id: number) => await api.delete(`/roles/${id}`),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['roles'] })
  });
}