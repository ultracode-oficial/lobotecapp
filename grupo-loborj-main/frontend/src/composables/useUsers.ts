import { useQuery, useMutation, useQueryClient } from '@tanstack/vue-query';
import api from '@/services/api';
import { toValue, type MaybeRefOrGetter } from 'vue';

export interface User {
  id: number;
  name: string;
  email: string;
  cpf: string;
  phone: string | null;
  bio: string | null;
  photo: string | null;
  mfa_enabled: boolean;
  mfa_required: boolean;
  change_password_required: boolean;
  is_active: boolean;
  created_at: string;
  roles: string[];
  permissions: string[];
  especializacoes: Array<{ id: number; nome: string }>;
  vendedor_config: any | null;
}

export interface UsersQueryParams {
  page: number;
  per_page: number;
  search: string;
  role: string;
  status: string;
  sort_by: string;
  sort_dir: 'asc' | 'desc';
}

// 1. Query para Listagem com suporte a todos os filtros
export function useUsersQuery(params: MaybeRefOrGetter<UsersQueryParams>) {
  return useQuery({
    queryKey: ['users', params],
    queryFn: async () => {
      const queryParams = toValue(params);

      // Limpamos propriedades vazias para ter uma URL mais limpa
      const cleanParams = Object.fromEntries(
        Object.entries(queryParams).filter(([_, v]) => v !== '' && v !== null)
      );

      const { data } = await api.get('/users', { params: cleanParams });

      // O Laravel ResourceCollection retorna { data: [...], meta: { current_page... } }
      return data;
    },
    // Mantém os dados antigos na tela enquanto busca os novos (melhora UX de paginação)
    placeholderData: (previousData) => previousData,
    staleTime: 30000,
  });
}

export function useUserQuery(id: number | string) {
  return useQuery({
    queryKey: ['users', id],
    queryFn: async () => {
      const { data } = await api.get(`/users/${id}`);
      return data.data; // Assumindo o wrap do Resource do Laravel
    },
    enabled: !!id, // Só executa se tiver um ID válido
  });
}

// Busca as roles e especializações disponíveis para preencher os selects/checkboxes
export function useUserFormEspecializacaoOptionsData() {
  return useQuery({
    queryKey: ['especializacoes', 'options'],
    queryFn: async () => {
      const espRes = await api.get('/especializacoes-options');

      return {
        especializacoes: espRes.data // ex: [{id: 1, name: 'Redes'}, ...]
      };
    },
    staleTime: 1000 * 60 * 60, // 1 hora de cache (muda pouco)
  });
}
export function useUserFormRoleOptionsData() {
  return useQuery({
    queryKey: ['roles', 'options'],
    queryFn: async () => {
      const rolesRes = await api.get('/roles-options')
      return {
        roles: rolesRes.data.roles, // ex: ['ADMIN', 'GERENTE', 'VENDEDOR', ...]
        permissions: rolesRes.data.permissions, // ex: ['LOGIN', 'ACESSO_WEB', 'ACESSO_MOBILE', ...]
      };
    },
    staleTime: 1000 * 60 * 60, // 1 hora de cache (muda pouco)
  });
}

export function useCreateUserMutation() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async (payload: any) => {
      const { data } = await api.post('/users', payload);
      return data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['users'] });
    }
  });
}

export function useUpdateUserMutation() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async ({ id, payload }: { id: number | string, payload: any }) => {
      const { data } = await api.put(`/users/${id}`, payload);
      return data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['users'] });
    }
  });
}

// 2. Mutation para Desativar (Soft Delete)
export function useDeleteUserMutation() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (id: number) => {
      await api.delete(`/users/${id}`);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['users'] });
    }
  });
}

// 3. Mutation para Reativar (Restore)
export function useRestoreUserMutation() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (id: number) => {
      await api.post(`/users/${id}/restore`);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['users'] });
    }
  });
}