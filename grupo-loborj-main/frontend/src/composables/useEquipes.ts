import { useQuery, useMutation, useQueryClient } from '@tanstack/vue-query';
import api from '@/services/api';
import { toValue, type MaybeRefOrGetter } from 'vue';

export interface Equipe {
  id: number;
  name: string;
  description: string | null;
  users?: Array<{ id: number; name: string; email: string }>;
}

// Lista Equipes
export function useEquipesQuery(params: MaybeRefOrGetter<any>) {
  return useQuery({
    queryKey: ['equipes', params],
    queryFn: async () => {
      const cleanParams = Object.fromEntries(
        Object.entries(toValue(params)).filter(([_, v]) => v !== '' && v !== null)
      );
      const { data } = await api.get('/equipes', { params: cleanParams });
      return data;
    },
    placeholderData: (prev) => prev,
  });
}

// Busca uma única Equipe
export function useEquipeQuery(id: number | string) {
  return useQuery({
    queryKey: ['equipes', id],
    queryFn: async () => {
      const { data } = await api.get(`/equipes/${id}`);
      return data.data;
    },
    enabled: !!id,
  });
}

// Busca APENAS usuários com role TÉCNICO para preencher o formulário
export function useTecnicosQuery() {
  return useQuery({
    queryKey: ['users', 'vendedores'],
    queryFn: async () => {
      // Ajuste os parâmetros conforme seu backend espera para filtrar roles
      const { data } = await api.get('/users', {
        params: { roles: ['TÉCNICO'], status: 'enabled', per_page: 1000, sort_by: 'name', sort_dir: 'asc' }
      });
      // Retorna apenas a array de dados (ignorando paginação se houver)
      return { tecnicos: data.data };
    },
    staleTime: 60000,
  });
}

// Mutations
export function useCreateEquipeMutation() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (payload: any) => await api.post('/equipes', payload),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['equipes'] })
  });
}

export function useUpdateEquipeMutation() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async ({ id, payload }: { id: string | number, payload: any }) =>
      await api.put(`/equipes/${id}`, payload),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['equipes'] })
  });
}

export function useDeleteEquipeMutation() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (id: number) => await api.delete(`/equipes/${id}`),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['equipes'] })
  });
}