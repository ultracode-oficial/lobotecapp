import { useQuery, useMutation, useQueryClient } from '@tanstack/vue-query';
import api from '@/services/api';
import { toValue, type MaybeRefOrGetter } from 'vue';

export interface TipoTarefa {
  id: number;
  name: string;
  description: string | null;
}

// Lista Especializações
export function useTipoTarefasQuery(params: MaybeRefOrGetter<any>) {
  return useQuery({
    queryKey: ['tipoTarefas', params],
    queryFn: async () => {
      const cleanParams = Object.fromEntries(
        Object.entries(toValue(params)).filter(([_, v]) => v !== '' && v !== null)
      );
      const { data } = await api.get('/tipoTarefas', { params: cleanParams });
      return data;
    },
    placeholderData: (prev) => prev,
  });
}

// Busca um único Tipo de Tarefa
export function useTipoTarefaQuery(id: number | string) {
  return useQuery({
    queryKey: ['tipoTarefas', id],
    queryFn: async () => {
      const { data } = await api.get(`/tipoTarefas/${id}`);
      return data.data;
    },
    enabled: !!id,
  });
}

// Mutations
export function useCreateTipoTarefaMutation() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (payload: any) => await api.post('/tipoTarefas', payload),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['tipoTarefas'] })
  });
}

export function useUpdateTipoTarefaMutation() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async ({ id, payload }: { id: string | number, payload: any }) =>
      await api.put(`/tipoTarefas/${id}`, payload),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['tipoTarefas'] })
  });
}

export function useDeleteTipoTarefaMutation() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (id: number) => await api.delete(`/tipoTarefas/${id}`),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['tipoTarefas'] })
  });
}