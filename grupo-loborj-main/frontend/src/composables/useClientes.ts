import { useQuery, useMutation, useQueryClient } from '@tanstack/vue-query';
import api from '@/services/api';
import { toValue, type MaybeRefOrGetter } from 'vue';

export interface Cliente {
  id: number;
  razao_social: string;
  nome_fantasia: string | null;
  cnpj: string;
  observacoes: string | null;
  email: string | null;
  phone: string | null;
  nome_representante: string | null;
  cep: string | null;
  logradouro: string | null;
  numero_logradouro: string | null;
  complemento: string | null;
  bairro: string | null;
  municipio: string | null;
  uf: string | null;
  lat: number | null;
  lng: number | null;
  created_at: string;
  equipamentos: {
    id: number; tipo_equipamento_id: number;
    tag: string | null;
    localizacao: string | null;
    marca: string | null;
    modelo: string | null;
    btu: string | null;
    evaporadora: string | null;
    condensadora: string | null;
    observacoes: string | null;
    is_generic: boolean;
    tipoEquipamento: {
      id: number;
      name: string;
      description: string | null;
    }
  }[]
}

export interface ClientesQueryParams {
  page: number;
  per_page: number;
  search: string;
  role: string;
  status: string;
  sort_by: string;
  sort_dir: 'asc' | 'desc';
}

// 1. Query para Listagem com suporte a todos os filtros
export function useClientesQuery(params: MaybeRefOrGetter<ClientesQueryParams>) {
  return useQuery({
    queryKey: ['clientes', params],
    queryFn: async () => {
      const queryParams = toValue(params);

      // Limpamos propriedades vazias para ter uma URL mais limpa
      const cleanParams = Object.fromEntries(
        Object.entries(queryParams).filter(([_, v]) => v !== '' && v !== null)
      );

      const { data } = await api.get('/clientes', { params: cleanParams });

      // O Laravel ResourceCollection retorna { data: [...], meta: { current_page... } }
      return data;
    },
    // Mantém os dados antigos na tela enquanto busca os novos (melhora UX de paginação)
    placeholderData: (previousData) => previousData,
    staleTime: 30000,
  });
}

export function useClienteQuery(id: number | string) {
  return useQuery({
    queryKey: ['clientes', id],
    queryFn: async () => {
      const { data } = await api.get(`/clientes/${id}`);
      return data.data; // Assumindo o wrap do Resource do Laravel
    },
    enabled: !!id, // Só executa se tiver um ID válido
  });
}

// Busca as roles e especializações disponíveis para preencher os selects/checkboxes
export function useClienteFormTipoEquipamentosOptionsData() {
  return useQuery({
    queryKey: ['tipoEquipamentos', 'options'],
    queryFn: async () => {
      const res = await api.get('/tipoEquipamentos-options');

      return {
        tipoEquipamentos: res.data // ex: [{id: 1, name: 'ACJ'}, ...]
      };
    },
    staleTime: 1000 * 60 * 60, // 1 hora de cache (muda pouco)
  });
}
export function useVendedoresQuery() {
  return useQuery({
    queryKey: ['users', 'vendedores'],
    queryFn: async () => {
      // Ajuste os parâmetros conforme seu backend espera para filtrar roles
      const { data } = await api.get('/users', {
        params: { roles: ['VENDEDOR', 'REPRESENTANTE'], status: 'enabled', per_page: 1000,  sort_by: 'name', sort_dir: 'asc' }
      });
      // Retorna apenas a array de dados (ignorando paginação se houver)
      return { vendedores: data.data };
    },
    staleTime: 60000,
  });
}

export function useCreateClienteMutation() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async (payload: any) => {
      const { data } = await api.post('/clientes', payload);
      return data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['clientes'] });
    }
  });
}

export function useUpdateClienteMutation() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async ({ id, payload }: { id: number | string, payload: any }) => {
      const { data } = await api.put(`/clientes/${id}`, payload);
      return data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['clientes'] });
    }
  });
}

// 2. Mutation para Desativar (Soft Delete)
export function useDeleteClienteMutation() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (id: number) => {
      await api.delete(`/clientes/${id}`);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['clientes'] });
    }
  });
}

// 3. Mutation para Reativar (Restore)
/* export function useRestoreClienteMutation() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (id: number) => {
      await api.post(`/clientes/${id}/restore`);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['clientes'] });
    }
  });
} */