import { useQuery, useMutation, useQueryClient } from '@tanstack/vue-query';
import api from '@/services/api';
import { toValue, type MaybeRefOrGetter } from 'vue';

export interface TipoEquipamento {
  id: number;
  name: string;
  description: string | null;
}

// Lista Especializações
export function useTipoEquipamentosQuery(params: MaybeRefOrGetter<any>) {
  return useQuery({
    queryKey: ['tipoEquipamentos', params],
    queryFn: async () => {
      const cleanParams = Object.fromEntries(
        Object.entries(toValue(params)).filter(([_, v]) => v !== '' && v !== null)
      );
      const { data } = await api.get('/tipoEquipamentos', { params: cleanParams });
      return data;
    },
    placeholderData: (prev) => prev,
  });
}

// Busca um único Tipo de Equipamento
export function useTipoEquipamentoQuery(id: number | string) {
  return useQuery({
    queryKey: ['tipoEquipamentos', id],
    queryFn: async () => {
      const { data } = await api.get(`/tipoEquipamentos/${id}`);
      return data.data;
    },
    enabled: !!id,
  });
}

// Mutations
export function useCreateTipoEquipamentoMutation() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (payload: any) => await api.post('/tipoEquipamentos', payload),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['tipoEquipamentos'] })
  });
}

export function useUpdateTipoEquipamentoMutation() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async ({ id, payload }: { id: string | number, payload: any }) =>
      await api.put(`/tipoEquipamentos/${id}`, payload),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['tipoEquipamentos'] })
  });
}

export function useDeleteTipoEquipamentoMutation() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (id: number) => await api.delete(`/tipoEquipamentos/${id}`),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['tipoEquipamentos'] })
  });
}