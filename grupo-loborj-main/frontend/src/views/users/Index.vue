<script setup lang="ts">
import { ref, reactive, watch } from 'vue';
import { useRouter } from 'vue-router';
import DataTable, { type Column } from '@/components/ui/DataTable.vue';
import { useUsersQuery, useDeleteUserMutation, useRestoreUserMutation, type User } from '@/composables/useUsers.ts';
import { useToastStore } from '@/stores/toast';
import { usePage } from '@/composables/usePage';
import { formatCPF, formatPhone } from '@/services/formatters';
import ConfirmModal from '@/components/ui/ConfirmModal.vue';
import { Edit2Icon, Loader2Icon, SearchIcon, SquarePenIcon, UserRoundCheckIcon, UserRoundXIcon } from '@lucide/vue';
import { STORAGE_PATH } from '@/services/storage';

const { setHeader } = usePage();
setHeader('Usuários', 'Gerencie o acesso, permissões e perfis dos usuários da plataforma.');

const router = useRouter();
const toastStore = useToastStore();

// --- ESTADO REATIVO DOS FILTROS E PAGINAÇÃO ---
const queryParams = reactive({
  page: 1,
  per_page: 15,
  search: '',
  role: '',
  status: 'all',
  sort_by: 'created_at',
  sort_dir: 'desc' as 'asc' | 'desc'
});

// Reseta a página para 1 sempre que um filtro textual ou dropdown mudar
watch(
  () => [queryParams.search, queryParams.role, queryParams.status],
  () => { queryParams.page = 1; }
);

// --- FETCH DATA (VUE QUERY) ---
const { data: usersResponse, isLoading, isFetching } = useUsersQuery(queryParams);

// --- MUTAÇÕES (DELETAR / RESTAURAR) ---
const deleteMutation = useDeleteUserMutation();
const restoreMutation = useRestoreUserMutation();

// --- CONFIGURAÇÃO DAS COLUNAS DA TABELA ---
const columns: Column[] = [
  { key: 'name', label: 'Usuário', sortable: true },
  { key: 'contact', label: 'Contato', sortable: false },
  { key: 'roles', label: 'Perfis', sortable: false },
  { key: 'status', label: 'Status', sortable: true, align: 'center' },
  { key: 'actions', label: 'Ações', align: 'right' }
];

// --- ESTADO DO MODAL DE CONFIRMAÇÃO ---
const modalState = reactive({
  isOpen: false,
  title: '',
  message: '',
  confirmText: '',
  type: 'danger' as 'danger' | 'success' | 'warning' | 'info',
  isLoading: false,
  onConfirm: async () => { } // Guarda a função que será executada
});

// Helper para abrir o modal
function openConfirmModal(options: Partial<typeof modalState>) {
  Object.assign(modalState, {
    ...options,
    isOpen: true,
    isLoading: false
  });
}

// --- AÇÕES ---
function handleSort(key: string, dir: 'asc' | 'desc') {
  queryParams.sort_by = key;
  queryParams.sort_dir = dir;
}

async function handleDelete(user: User) {
  openConfirmModal({
    title: 'Desativar Usuário',
    message: `Tem certeza que deseja desativar o acesso de ${user.name}? O usuário não poderá mais acessar o sistema.`,
    confirmText: 'Desativar',
    type: 'danger',
    onConfirm: async () => {
      modalState.isLoading = true;
      try {
        await deleteMutation.mutateAsync(user.id);
        toastStore.send({ message: 'Usuário desativado com sucesso.', style: 'success' });
        modalState.isOpen = false;
      } catch (error) {
        toastStore.send({ message: 'Erro ao desativar usuário.', style: 'error' });
      } finally {
        modalState.isLoading = false;
      }
    }
  });
}

async function handleRestore(user: User) {
  openConfirmModal({
    title: 'Reativar Usuário',
    message: `Deseja restaurar o acesso de ${user.name}? Ele voltará a ter acesso total ao sistema com suas permissões anteriores.`,
    confirmText: 'Reativar Usuário',
    type: 'success',
    onConfirm: async () => {
      modalState.isLoading = true;
      try {
        await restoreMutation.mutateAsync(user.id);
        toastStore.send({ message: 'Usuário reativado com sucesso.', style: 'success' });
        modalState.isOpen = false;
      } catch (error) {
        toastStore.send({ message: 'Erro ao reativar usuário.', style: 'error' });
      } finally {
        modalState.isLoading = false;
      }
    }
  });
}
</script>

<template>
  <div class="space-y-6 py-3">
    <!-- Cabeçalho da Página -->
    <div class="sm:flex sm:items-center sm:justify-between">
      <h2 class="text-xl font-bold text-slate-800">Lista de Usuários</h2>
      <button v-can="'CRIAR_USUARIOS'" @click="router.push({ name: 'users.create' })" type="button"
        class="inline-flex items-center justify-center text-sm disabled:bg-primary-muted disabled:text-primary disabled:cursor-not-allowed rounded-md font-medium cursor-pointer px-6 py-2 bg-primary active:bg-primary-active text-primary-contrast hover:bg-primary-hover transition-all">
        Novo Usuário
      </button>
    </div>

    <!-- Barra de Filtros -->
    <div class="bg-white p-4 rounded-lg shadow-sm ring-1 ring-slate-300 flex flex-col sm:flex-row gap-4 items-end">
      <!-- Busca Textual -->
      <div class="w-full sm:w-1/3">
        <label for="search" class="block text-sm font-medium text-slate-700 mb-1">Pesquisar</label>
        <div class="mt-1 relative rounded-md">
          <div class="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-3">
            <SearchIcon class="size-5 text-slate-400"></SearchIcon>
          </div>
          <input v-model.lazy="queryParams.search" type="text" id="search"
            class="text-sm w-full pl-10 py-2 disabled:bg-slate-200 disabled:animate-pulse border border-slate-300 rounded-md focus:outline-none focus:ring-1 focus:ring-slate-800 focus:border-slate-800 text-slate-700 placeholder-slate-400"
            placeholder="Nome, e-mail ou CPF...">
        </div>
      </div>

      <!-- Filtro: Perfil -->
      <div class="w-full sm:w-1/4">
        <label for="role" class="block text-sm font-medium text-slate-700 mb-1">Perfil</label>
        <select v-model="queryParams.role" id="role"
          class="text-sm w-full px-3 py-2 disabled:bg-slate-200 disabled:animate-pulse border border-slate-300 rounded-md focus:outline-none focus:ring-1 focus:ring-slate-800 focus:border-slate-800 text-slate-700 placeholder-slate-400">
          <option value="">Todos os perfis</option>
          <option value="VENDEDOR">Vendedor</option>
          <option value="REPRESENTANTE">Representante</option>
          <option value="TÉCNICO">Técnico</option>
          <option value="FINANCEIRO">Financeiro</option>
          <option value="ADMINISTRADOR">Administrador</option>
        </select>
      </div>

      <!-- Filtro: Status -->
      <div class="w-full sm:w-1/4">
        <label for="status" class="block text-sm font-medium text-slate-700 mb-1">Status</label>
        <select v-model="queryParams.status" id="status"
          class="text-sm w-full px-3 py-2 disabled:bg-slate-200 disabled:animate-pulse border border-slate-300 rounded-md focus:outline-none focus:ring-1 focus:ring-slate-800 focus:border-slate-800 text-slate-700 placeholder-slate-400">
          <option value="all">Todos</option>
          <option value="enabled">Ativo</option>
          <option value="disabled">Desativado</option>
        </select>
      </div>

      <!-- Indicador de Loading suave ao refazer buscas -->
      <div v-if="isFetching && !isLoading" class="pb-2 pl-2">
        <Loader2Icon class="animate-spin size-5 text-slate-600"></Loader2Icon>
      </div>
    </div>

    <!-- Tabela de Dados -->
    <DataTable :columns="columns" :items="usersResponse?.data || []" :loading="isLoading"
      :pagination="usersResponse?.meta" :sort-by="queryParams.sort_by" :sort-dir="queryParams.sort_dir"
      empty-message="Nenhum usuário foi encontrado" @sort="handleSort" @update:page="queryParams.page = $event"
      @update:per-page="queryParams.per_page = $event">
      <!-- Slot customizado: Name (Avatar + Email) -->
      <template #cell-name="{ item }">
        <div class="flex items-center">
          <div class="h-10 w-10 shrink-0">
            <img v-if="item.photo" class="h-10 w-10 rounded-full object-cover" :src="`${STORAGE_PATH}${item.photo}`"
              alt="" />
            <div v-else
              class="h-10 w-10 rounded-full bg-slate-100 flex items-center justify-center text-slate-700 font-bold">
              {{ item.name.charAt(0).toUpperCase() }}
            </div>
          </div>
          <div class="ml-4">
            <div class="font-medium text-slate-900">{{ item.name }}</div>
            <div class="text-slate-500">{{ item.email }}</div>
          </div>
        </div>
      </template>

      <!-- Slot customizado: Contact -->
      <template #cell-contact="{ item }">
        <div class="text-slate-900">{{ formatCPF(item.cpf) }}</div>
        <div class="text-slate-500 text-xs">{{ item.phone ? formatPhone(item.phone) : 'Sem telefone' }}</div>
      </template>

      <!-- Slot customizado: Roles (Badges) -->
      <template #cell-roles="{ item }">
        <div class="flex flex-wrap gap-1">
          <span v-for="role in item.roles" :key="role"
            class="inline-flex items-center rounded-md bg-blue-50 px-2 py-1 text-xs font-medium text-blue-700 ring-1 ring-inset ring-blue-700/10">
            {{ role }}
          </span>
          <span v-if="item.roles.length === 0" class="text-slate-400 text-xs">Sem perfil</span>
        </div>
      </template>

      <!-- Slot customizado: Status -->
      <template #cell-status="{ item }">
        <span v-if="item.is_active"
          class="inline-flex items-center rounded-md bg-green-50 px-2 py-1 text-xs font-medium text-green-700 ring-1 ring-inset ring-green-600/20">
          Ativo
        </span>
        <span v-else
          class="inline-flex items-center rounded-md bg-red-50 px-2 py-1 text-xs font-medium text-red-700 ring-1 ring-inset ring-red-600/10">
          Desativado
        </span>
      </template>

      <!-- Slot customizado: Actions -->
      <template #cell-actions="{ item }">
        <div class="flex items-center justify-end gap-3">
          <!-- Botão Editar -->
          <button v-can="'GERIR_USUARIOS'" @click="router.push({ name: 'users.edit', params: { id: item.id } })"
            title="Editar"
            class="bg-yellow-500 hover:bg-yellow-600 active:bg-yellow-700 disabled:cursor-not-allowed disabled:bg-yellow-300 text-white p-2 font-medium rounded cursor-pointer">
            <SquarePenIcon class="size-5"></SquarePenIcon>
          </button>

          <!-- Botões Desativar / Reativar (SoftDeletes) -->
          <button v-if="item.is_active" v-can="'GERIR_USUARIOS'" @click="handleDelete(item as User)" title="Desativar"
            class="bg-red-500 hover:bg-red-600 active:bg-red-700 disabled:cursor-not-allowed disabled:bg-red-300 text-white p-2 font-medium rounded cursor-pointer"
            :disabled="deleteMutation.isPending.value">
            <UserRoundXIcon class="size-5"></UserRoundXIcon>
          </button>

          <button v-else v-can="'GERIR_USUARIOS'" @click="handleRestore(item as User)" title="Reativar"
            class="bg-green-500 hover:bg-green-600 active:bg-green-700 disabled:cursor-not-allowed disabled:bg-green-300 text-white p-2 font-medium rounded cursor-pointer"
            :disabled="restoreMutation.isPending.value">
            <UserRoundCheckIcon class="size-5"></UserRoundCheckIcon>
          </button>
        </div>
      </template>
    </DataTable>
    <ConfirmModal v-model:isOpen="modalState.isOpen" :title="modalState.title" :message="modalState.message"
      :confirm-text="modalState.confirmText" :type="modalState.type" :is-loading="modalState.isLoading"
      @confirm="modalState.onConfirm" />
  </div>
</template>