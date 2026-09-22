import { useQuery, useMutation, useQueryClient } from '@tanstack/vue-query';
import api from '@/services/api';
import { toValue, type MaybeRefOrGetter } from 'vue';

export interface TipoServico {
  id: number;
  name: string;
  description: string | null;
}

// Lista Especializações
export function useTipoServicosQuery(params: MaybeRefOrGetter<any>) {
  return useQuery({
    queryKey: ['tipoServicos', params],
    queryFn: async () => {
      const cleanParams = Object.fromEntries(
        Object.entries(toValue(params)).filter(([_, v]) => v !== '' && v !== null)
      );
      const { data } = await api.get('/tipoServicos', { params: cleanParams });
      return data;
    },
    placeholderData: (prev) => prev,
  });
}

// Busca um único Tipo de Serviço
export function useTipoServicoQuery(id: number | string) {
  return useQuery({
    queryKey: ['tipoServicos', id],
    queryFn: async () => {
      const { data } = await api.get(`/tipoServicos/${id}`);
      return data.data;
    },
    enabled: !!id,
  });
}

// Mutations
export function useCreateTipoServicoMutation() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (payload: any) => await api.post('/tipoServicos', payload),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['tipoServicos'] })
  });
}

export function useUpdateTipoServicoMutation() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async ({ id, payload }: { id: string | number, payload: any }) =>
      await api.put(`/tipoServicos/${id}`, payload),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['tipoServicos'] })
  });
}

export function useDeleteTipoServicoMutation() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (id: number) => await api.delete(`/tipoServicos/${id}`),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['tipoServicos'] })
  });
}