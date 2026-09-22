<script setup lang="ts">
import { ChevronLeftIcon, ChevronRightIcon } from '@lucide/vue';
import { computed } from 'vue';

interface Props {
  currentPage: number;
  lastPage: number;
  total: number;
  perPage: number;
}

const props = defineProps<Props>();

const emit = defineEmits<{
  (e: 'update:page', page: number): void;
  (e: 'update:perPage', perPage: number): void;
}>();

// Calcula o início e fim dos itens exibidos atualmente
const showingFrom = computed(() => (props.currentPage - 1) * props.perPage + 1);
const showingTo = computed(() => Math.min(props.currentPage * props.perPage, props.total));

// Lógica simples para gerar os botões de página (com reticências para muitas páginas)
const pages = computed(() => {
  const range = [];
  for (let i = 1; i <= props.lastPage; i++) {
    if (i === 1 || i === props.lastPage || (i >= props.currentPage - 1 && i <= props.currentPage + 1)) {
      range.push(i);
    } else if (range[range.length - 1] !== '...') {
      range.push('...');
    }
  }
  return range;
});

function changePage(page: number | string) {
  if (typeof page === 'number' && page !== props.currentPage && page >= 1 && page <= props.lastPage) {
    emit('update:page', page);
  }
}

function changePerPage(event: Event) {
  const target = event.target as HTMLSelectElement;
  emit('update:perPage', Number(target.value));
}
</script>

<template>
  <div class="flex items-center justify-between border-t border-slate-200 bg-white px-4 py-3 sm:px-6">
    <div class="hidden sm:flex sm:flex-1 sm:items-center sm:justify-between">
      <div class="flex items-center space-x-4">
        <p class="text-sm text-slate-700">
          Mostrando <span class="font-medium">{{ showingFrom }}</span> a <span class="font-medium">{{ showingTo
            }}</span> de <span class="font-medium">{{ total }}</span> resultados
        </p>

        <div class="flex items-center space-x-2">
          <label for="per_page" class="text-sm text-slate-700">Por página:</label>
          <select id="per_page" :value="perPage" @change="changePerPage"
            class="block w-20 rounded-md border border-slate-300 py-1.5 text-sm focus:border-slate-500 focus:ring-slate-500">
            <option :value="15">15</option>
            <option :value="30">30</option>
            <option :value="50">50</option>
            <option :value="100">100</option>
          </select>
        </div>
      </div>

      <div>
        <nav class="isolate inline-flex -space-x-px rounded-md shadow-sm" aria-label="Pagination">
          <button @click="changePage(currentPage - 1)" :disabled="currentPage === 1"
            class="relative inline-flex items-center rounded-l-md px-2 py-2 text-slate-400 ring-1 ring-inset ring-slate-300 hover:bg-slate-50 focus:z-20 disabled:opacity-50 disabled:cursor-not-allowed">
            <span class="sr-only">Anterior</span>
            <ChevronLeftIcon class="size-4"></ChevronLeftIcon>
          </button>

          <button v-for="(page, index) in pages" :key="index" @click="changePage(page)" :class="[
            page === currentPage ? 'z-10 bg-primary text-white focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary-active' : 'text-slate-900 ring-1 ring-inset ring-slate-300 hover:bg-slate-50 focus:outline-offset-0',
            page === '...' ? 'pointer-events-none' : '',
            'relative inline-flex items-center px-4 py-2 text-sm font-semibold'
          ]">
            {{ page }}
          </button>

          <button @click="changePage(currentPage + 1)" :disabled="currentPage === lastPage"
            class="relative inline-flex items-center rounded-r-md px-2 py-2 text-slate-400 ring-1 ring-inset ring-slate-300 hover:bg-slate-50 focus:z-20 disabled:opacity-50 disabled:cursor-not-allowed">
            <span class="sr-only">Próximo</span>
            <ChevronRightIcon class="size-4"></ChevronRightIcon>
          </button>
        </nav>
      </div>
    </div>
  </div>
</template>