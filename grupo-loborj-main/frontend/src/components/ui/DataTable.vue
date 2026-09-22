<script setup lang="ts" generic="T extends Record<string, any>">
import { computed } from 'vue';
import Pagination from './Pagination.vue';
import { ChevronDownIcon, ChevronUpIcon } from '@lucide/vue';
import EmptyBoxIcon from '../icons/EmptyBoxIcon.vue';

export interface Column {
  key: string;
  label: string;
  sortable?: boolean;
  align?: 'left' | 'center' | 'right';
}

export interface PaginationInfo {
  current_page: number;
  last_page: number;
  total: number;
  per_page: number;
}

const props = withDefaults(defineProps<{
  columns: Column[];
  items: T[];
  loading?: boolean;
  emptyMessage?: string;
  sortBy?: string;
  sortDir?: 'asc' | 'desc';
  pagination?: PaginationInfo | null;
}>(), {
  loading: false,
  emptyMessage: 'Nenhum registro encontrado.',
  sortBy: '',
  sortDir: 'desc',
  pagination: null,
});

const emit = defineEmits<{
  (e: 'sort', key: string, direction: 'asc' | 'desc'): void;
  (e: 'update:page', page: number): void;
  (e: 'update:perPage', perPage: number): void;
}>();

function handleSort(column: Column) {
  if (!column.sortable) return;

  let direction: 'asc' | 'desc' = 'asc';
  if (props.sortBy === column.key && props.sortDir === 'asc') {
    direction = 'desc';
  }

  emit('sort', column.key, direction);
}

const alignmentClasses = {
  left: 'text-left',
  center: 'text-center',
  right: 'text-right'
};
</script>

<template>
  <div class="flex flex-col bg-white shadow-sm ring-1 ring-slate-300 sm:rounded-lg">
    <div class="overflow-x-auto">
      <div class="inline-block min-w-full align-middle">
        <table class="min-w-full divide-y divide-slate-300">
          <thead>
            <tr>
              <th v-for="col in columns" :key="col.key" scope="col" :class="[
                'py-3.5 px-4 text-sm font-semibold text-slate-900',
                alignmentClasses[col.align || 'left'],
                col.sortable ? 'cursor-pointer hover:bg-slate-50 select-none rounded-lg' : ''
              ]" @click="handleSort(col)">
                <div class="flex items-center gap-2"
                  :class="{ 'justify-center': col.align === 'center', 'justify-end': col.align === 'right' }">
                  {{ col.label }}

                  <span v-if="col.sortable" class="flex flex-col text-slate-400 w-3">
                    <ChevronUpIcon class="size-3 -mb-1" v-if="sortBy !== col.key || sortDir === 'asc'"
                      :class="{ 'text-indigo-600': sortBy === col.key && sortDir === 'asc' }"></ChevronUpIcon>

                    <ChevronDownIcon v-if="sortBy !== col.key || sortDir === 'desc'" class="size-3"
                      :class="{ 'text-indigo-600': sortBy === col.key && sortDir === 'desc' }"></ChevronDownIcon>
                  </span>
                </div>
              </th>
            </tr>
          </thead>
          <tbody class="divide-y divide-slate-200">
            <!-- Loading State (Skeletons) -->
            <template v-if="loading">
              <tr v-for="i in (pagination?.per_page || 5)" :key="`skeleton-${i}`" class="animate-pulse">
                <td v-for="col in columns" :key="`sk-td-${col.key}`" class="whitespace-nowrap px-4 py-4 text-sm">
                  <div class="h-4 bg-slate-200 rounded w-3/4"
                    :class="{ 'mx-auto': col.align === 'center', 'ml-auto': col.align === 'right' }"></div>
                </td>
              </tr>
            </template>

            <!-- Empty State -->
            <template v-else-if="items.length === 0">
              <tr>
                <td :colspan="columns.length" class="px-4 py-12 text-center text-sm text-slate-500">
                  <div class="flex flex-col items-center justify-center">
                    <EmptyBoxIcon class="mx-auto size-12 text-slate-400"></EmptyBoxIcon>
                    <h3 class="mt-2 text-sm font-semibold text-slate-900">Sem registros</h3>
                    <p class="mt-1 text-sm text-slate-500">{{ emptyMessage }}</p>
                  </div>
                </td>
              </tr>
            </template>

            <!-- Data Rows -->
            <template v-else>
              <tr v-for="(item, index) in items" :key="index" class="hover:bg-slate-50 transition-colors duration-150">
                <td v-for="col in columns" :key="`cell-${col.key}`"
                  :class="['whitespace-nowrap px-4 py-4 text-sm text-slate-900', alignmentClasses[col.align || 'left']]">
                  <!-- 
                    A mágica acontece aqui: O Vue procura se um slot com o nome 'cell-{nome_da_coluna}' foi passado.
                    Se sim, renderiza o HTML customizado passado pelo componente pai.
                    Se não, imprime o valor da propriedade de forma bruta.
                  -->
                  <slot :name="`cell-${col.key}`" :item="item" :index="index">
                    {{ item[col.key] }}
                  </slot>
                </td>
              </tr>
            </template>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Paginação atrelada ao Footer da tabela -->
    <Pagination v-if="pagination && !loading && items.length > 0" :current-page="pagination.current_page"
      :last-page="pagination.last_page" :total="pagination.total" :per-page="pagination.per_page"
      @update:page="$emit('update:page', $event)" @update:per-page="$emit('update:perPage', $event)" />
  </div>
</template>