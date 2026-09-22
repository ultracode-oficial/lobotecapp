<script setup lang="ts">
import { ref, reactive, watch } from 'vue';
import { useRouter } from 'vue-router';
import DataTable, { type Column } from '@/components/ui/DataTable.vue';
import { useClientesQuery, useDeleteClienteMutation, type Cliente } from '@/composables/useClientes.ts';
import { useToastStore } from '@/stores/toast';
import { usePage } from '@/composables/usePage';
import { formatCNPJ, formatEndereco, formatPhone } from '@/services/formatters';
import ConfirmModal from '@/components/ui/ConfirmModal.vue';
import { Loader2Icon, SearchIcon, SquarePenIcon, UserRoundXIcon } from '@lucide/vue';
import TextModal from '@/components/ui/TextModal.vue';

const { setHeader } = usePage();
setHeader('Clientes', 'Gerencie clientes, equipamentos, serviços e contratos.');

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
const { data: clientesResponse, isLoading, isFetching } = useClientesQuery(queryParams);

// --- MUTAÇÕES (DELETAR / RESTAURAR) ---
const deleteMutation = useDeleteClienteMutation();
// const restoreMutation = useRestoreClienteMutation();

// --- CONFIGURAÇÃO DAS COLUNAS DA TABELA ---
const columns: Column[] = [
  { key: 'name', label: 'Cliente', sortable: true },
  { key: 'contact', label: 'Contato', sortable: false },
  { key: 'endereco', label: 'Endereço', sortable: false },
  { key: 'observacoes', label: 'Observações', sortable: false },
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

// Controle de estado do modal
const isObservationModalOpen = ref(false);
const currentObservationText = ref('');
const currentTitle = ref('');

// Função para abrir o modal com o texto específico
function openObservation({ text, title }: { title: string, text: string }) {
  currentObservationText.value = text;
  currentTitle.value = title;
  isObservationModalOpen.value = true;
}

// --- AÇÕES ---
function handleSort(key: string, dir: 'asc' | 'desc') {
  queryParams.sort_by = key;
  queryParams.sort_dir = dir;
}

async function handleDelete(cliente: Cliente) {
  openConfirmModal({
    title: 'Excluir Cliente',
    message: `Tem certeza que deseja excluir o cliente ${cliente.razao_social}? Esta operação não pode ser desfeita.`,
    confirmText: 'Excluir',
    type: 'danger',
    onConfirm: async () => {
      modalState.isLoading = true;
      try {
        await deleteMutation.mutateAsync(cliente.id);
        toastStore.send({ message: 'Cliente desativado com sucesso.', style: 'success' });
        modalState.isOpen = false;
      } catch (error) {
        toastStore.send({ message: 'Erro ao desativar cliente.', style: 'error' });
      } finally {
        modalState.isLoading = false;
      }
    }
  });
}

/* async function handleRestore(cliente: Cliente) {
  openConfirmModal({
    title: 'Reativar Cliente',
    message: `Deseja restaurar o acesso de ${cliente.razao_social}? Ele voltará a ter acesso total ao sistema com suas permissões anteriores.`,
    confirmText: 'Reativar Cliente',
    type: 'success',
    onConfirm: async () => {
      modalState.isLoading = true;
      try {
        await restoreMutation.mutateAsync(cliente.id);
        toastStore.send({ message: 'Cliente reativado com sucesso.', style: 'success' });
        modalState.isOpen = false;
      } catch (error) {
        toastStore.send({ message: 'Erro ao reativar cliente.', style: 'error' });
      } finally {
        modalState.isLoading = false;
      }
    }
  });
} */
</script>

<template>
  <div class="space-y-6 py-3">
    <!-- Cabeçalho da Página -->
    <div class="sm:flex sm:items-center sm:justify-between">
      <h2 class="text-xl font-bold text-slate-800">Lista de Clientes</h2>
      <button v-can="'CRIAR_USUARIOS'" @click="router.push({ name: 'clientes.create' })" type="button"
        class="inline-flex items-center justify-center text-sm disabled:bg-primary-muted disabled:text-primary disabled:cursor-not-allowed rounded-md font-medium cursor-pointer px-6 py-2 bg-primary active:bg-primary-active text-primary-contrast hover:bg-primary-hover transition-all">
        Novo Cliente
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
            class="text-sm w-full pl-10 pr-2 py-2 disabled:bg-slate-200 disabled:animate-pulse border border-slate-300 rounded-md focus:outline-none focus:ring-1 focus:ring-slate-800 focus:border-slate-800 text-slate-700 placeholder-slate-400"
            placeholder="Razão social, nome fantasia, CNPJ, e-mail, telefone...">
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
    <DataTable :columns="columns" :items="clientesResponse?.data || []" :loading="isLoading"
      :pagination="clientesResponse?.meta" :sort-by="queryParams.sort_by" :sort-dir="queryParams.sort_dir"
      empty-message="Nenhum cliente foi encontrado" @sort="handleSort" @update:page="queryParams.page = $event"
      @update:per-page="queryParams.per_page = $event">
      <!-- Slot customizado: Name (Avatar + Email) -->
      <template #cell-name="{ item }">
        <div class="flex flex-col">
          <div class="font-medium text-slate-800" title="Razão Social">{{ item.razao_social }}</div>
          <div v-if="item.nome_fantasia" class="font-medium text-slate-600" title="Nome Fantasia">{{ item.nome_fantasia
          }}</div>
          <div class="text-slate-600" title="CNPJ">{{ formatCNPJ(item.cnpj) }}</div>
        </div>
      </template>

      <!-- Slot customizado: Contact -->
      <template #cell-contact="{ item }">
        <div class="flex flex-col">
          <p class="text-slate-900">{{ item.phone ? formatPhone(item.phone) : 'Sem telefone' }}</p>
          <p class="text-slate-600">{{ item.email ?? 'Sem e-mail' }}</p>
          <p class="text-slate-600">{{ item.nome_representante ?? 'Representante não identificado' }}</p>
        </div>
      </template>

      <!-- Slot customizado: Endereço -->
      <template #cell-endereco="{ item }">
        <div class="text-slate-600 max-w-72 text-wrap">{{ formatEndereco({
          cep: item.cep,
          logradouro: item.logradouro,
          numero_logradouro: item.numero_logradouro,
          complemento: item.complemento,
          bairro: item.bairro,
          municipio: item.municipio,
          uf: item.uf,
        }) ?? 'Sem endereço' }}</div>
      </template>

      <template #cell-observacoes="{ item }">
        <p v-if="item.observacoes"
          @click="openObservation({ title: `Observações do Cliente — ${item.razao_social}`, text: item.observacoes })"
          class="text-slate-600 max-w-72 truncate cursor-pointer hover:text-slate-600 hover:underline transition-colors">
          {{ item.observacoes }}
        </p>
        <p v-else class="text-slate-400">Sem observações</p>
      </template>

      <!-- Slot customizado: Actions -->
      <template #cell-actions="{ item }">
        <div class="flex items-center justify-end gap-3">
          <!-- Botão Editar -->
          <button v-can="'GERIR_USUARIOS'" @click="router.push({ name: 'clientes.edit', params: { id: item.id } })"
            title="Editar"
            class="bg-yellow-500 hover:bg-yellow-600 active:bg-yellow-700 disabled:cursor-not-allowed disabled:bg-yellow-300 text-white p-2 font-medium rounded cursor-pointer">
            <SquarePenIcon class="size-5"></SquarePenIcon>
          </button>

          <!-- Botões Excluir -->
          <!-- v-if="item.is_active" -->
          <button v-can="'GERIR_USUARIOS'" @click="handleDelete(item as Cliente)" title="Excluir Cliente"
            class="bg-red-500 hover:bg-red-600 active:bg-red-700 disabled:cursor-not-allowed disabled:bg-red-300 text-white p-2 font-medium rounded cursor-pointer"
            :disabled="deleteMutation.isPending.value">
            <UserRoundXIcon class="size-5"></UserRoundXIcon>
          </button>

          <!-- <button v-else v-can="'GERIR_USUARIOS'" @click="handleRestore(item as Cliente)" title="Reativar"
            class="bg-green-500 hover:bg-green-600 active:bg-green-700 disabled:cursor-not-allowed disabled:bg-green-300 text-white p-2 font-medium rounded cursor-pointer"
            :disabled="restoreMutation.isPending.value">
            <UserRoundCheckIcon class="size-5"></UserRoundCheckIcon>
          </button> -->
        </div>
      </template>
    </DataTable>
    <ConfirmModal v-model:isOpen="modalState.isOpen" :title="modalState.title" :message="modalState.message"
      :confirm-text="modalState.confirmText" :type="modalState.type" :is-loading="modalState.isLoading"
      @confirm="modalState.onConfirm" />
    <TextModal v-model:isOpen="isObservationModalOpen" :title="currentTitle" :text="currentObservationText" />
  </div>
</template>