import { useQuery, useMutation, useQueryClient } from '@tanstack/vue-query';
import api from '@/services/api';
import { toValue, type MaybeRefOrGetter } from 'vue';

export interface Especializacao {
  id: number;
  name: string;
  description: string | null;
}

// Lista Especializações
export function useEspecializacoesQuery(params: MaybeRefOrGetter<any>) {
  return useQuery({
    queryKey: ['especializacoes', params],
    queryFn: async () => {
      const cleanParams = Object.fromEntries(
        Object.entries(toValue(params)).filter(([_, v]) => v !== '' && v !== null)
      );
      const { data } = await api.get('/especializacoes', { params: cleanParams });
      return data;
    },
    placeholderData: (prev) => prev,
  });
}

// Busca uma única Especialização
export function useEspecializacaoQuery(id: number | string) {
  return useQuery({
    queryKey: ['especializacoes', id],
    queryFn: async () => {
      const { data } = await api.get(`/especializacoes/${id}`);
      return data.data;
    },
    enabled: !!id,
  });
}

// Mutations
export function useCreateEspecializacaoMutation() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (payload: any) => await api.post('/especializacoes', payload),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['especializacoes'] })
  });
}

export function useUpdateEspecializacaoMutation() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async ({ id, payload }: { id: string | number, payload: any }) =>
      await api.put(`/especializacoes/${id}`, payload),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['especializacoes'] })
  });
}

export function useDeleteEspecializacaoMutation() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (id: number) => await api.delete(`/especializacoes/${id}`),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['especializacoes'] })
  });
}