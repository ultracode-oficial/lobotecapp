<script setup lang="ts">
import { reactive, watch } from 'vue';
import { useRouter } from 'vue-router';
import DataTable, { type Column } from '@/components/ui/DataTable.vue';
import { useToastStore } from '@/stores/toast';
import { usePage } from '@/composables/usePage';
import ConfirmModal from '@/components/ui/ConfirmModal.vue';
import { Loader2Icon, SearchIcon, SquarePenIcon, Trash2Icon } from '@lucide/vue';
import { useDeleteTipoEquipamentoMutation, useTipoEquipamentosQuery, type TipoEquipamento } from '@/composables/useTipoEquipamentos';

const { setHeader } = usePage();
setHeader('Tipos de Equipamento', 'Configure as opções de tipos de equipamentos.');

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
const { data: tipoEquipamentosResponse, isLoading, isFetching } = useTipoEquipamentosQuery(queryParams);

// --- MUTAÇÕES (DELETAR / RESTAURAR) ---
const deleteMutation = useDeleteTipoEquipamentoMutation();

// --- CONFIGURAÇÃO DAS COLUNAS DA TABELA ---
const columns: Column[] = [
  { key: 'name', label: 'Tipo de Equipamento', sortable: true },
  { key: 'description', label: 'Descrição', sortable: false },
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

async function handleDelete(tipoEquipamento: TipoEquipamento) {
  openConfirmModal({
    title: 'Excluir Tipo de Equipamento',
    message: `Tem certeza que deseja excluir o tipo de equipamento ${tipoEquipamento.name}? Esta operação não pode ser desfeita.`,
    confirmText: 'Excluir',
    type: 'danger',
    onConfirm: async () => {
      modalState.isLoading = true;
      try {
        await deleteMutation.mutateAsync(tipoEquipamento.id);
        toastStore.send({ message: 'Tipo de equipamento excluído com sucesso.', style: 'success' });
        modalState.isOpen = false;
      } catch (error) {
        const err = error as any;
        toastStore.send({ message: err?.errors ? Object.values(err.errors).flat().join(' ') : err?.message ?? 'Erro interno ao tentar excluir tipo de equipamento.', style: 'error' });
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
      <h2 class="text-xl font-bold text-slate-800">Lista de Tipos de Equipamento</h2>
      <button title="Criar novo tipo de equipamento" v-can="'GERIR_CONFIGURACOES'"
        @click="router.push({ name: 'tipoEquipamentos.create' })" type="button"
        class="inline-flex items-center justify-center text-sm disabled:bg-primary-muted disabled:text-primary disabled:cursor-not-allowed rounded-md font-medium cursor-pointer px-6 py-2 bg-primary active:bg-primary-active text-primary-contrast hover:bg-primary-hover transition-all">
        Novo Tipo
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
            placeholder="Nome do tipo de equipamento">
        </div>
      </div>
      <!-- Indicador de Loading suave ao refazer buscas -->
      <div v-if="isFetching && !isLoading" class="pb-2 pl-2">
        <Loader2Icon class="animate-spin size-5 text-slate-600"></Loader2Icon>
      </div>
    </div>

    <!-- Tabela de Dados -->
    <DataTable :columns="columns" :items="tipoEquipamentosResponse?.data || []" :loading="isLoading"
      :pagination="tipoEquipamentosResponse?.meta" :sort-by="queryParams.sort_by" :sort-dir="queryParams.sort_dir"
      empty-message="Nenhum tipo de equipamento foi encontrado" @sort="handleSort"
      @update:page="queryParams.page = $event" @update:per-page="queryParams.per_page = $event">
      <!-- Slot customizado: Nome -->
      <template #cell-name="{ item }">
        <div class="px-2 text-base font-medium text-primary">{{ item.name }}</div>
      </template>

      <!-- Slot customizado: Descrição -->
      <template #cell-description="{ item }">
        <div class="text-slate-500 text-sm max-w-xs text-wrap">{{ item.description }}</div>
      </template>

      <!-- Slot customizado: Actions -->
      <template #cell-actions="{ item }">
        <div class="flex items-center justify-end gap-3">
          <!-- Botão Editar -->
          <button v-can="'GERIR_CONFIGURACOES'"
            @click="router.push({ name: 'tipoEquipamentos.edit', params: { id: item.id } })" title="Editar"
            class="bg-yellow-500 hover:bg-yellow-600 active:bg-yellow-700 disabled:cursor-not-allowed disabled:bg-yellow-300 text-white p-2 font-medium rounded cursor-pointer">
            <SquarePenIcon class="size-5"></SquarePenIcon>
          </button>
          <!-- Botões Desativar / Reativar (SoftDeletes) -->
          <button v-can="'GERIR_CONFIGURACOES'" @click="handleDelete(item as TipoEquipamento)" title="Excluir"
            class="bg-red-500 hover:bg-red-600 active:bg-red-700 disabled:cursor-not-allowed disabled:bg-red-300 text-white p-2 font-medium rounded cursor-pointer"
            :disabled="deleteMutation.isPending.value">
            <Trash2Icon class="size-5"></Trash2Icon>
          </button>
        </div>
      </template>
    </DataTable>
    <ConfirmModal v-model:isOpen="modalState.isOpen" :title="modalState.title" :message="modalState.message"
      :confirm-text="modalState.confirmText" :type="modalState.type" :is-loading="modalState.isLoading"
      @confirm="modalState.onConfirm" />
  </div>
</template>