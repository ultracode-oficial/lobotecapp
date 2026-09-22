<script setup lang="ts">
import { reactive, watch } from 'vue';

const props = defineProps<{
  initialData?: any;
  tecnicos?: any[];
  isLoading?: boolean;
  errors?: Record<string, string[]>;
}>();

const emit = defineEmits(['submit', 'cancel']);

const form = reactive({
  name: '',
  description: '',
});

watch(() => props.initialData, (data) => {
  if (data) {
    form.name = data.name || '';
    form.description = data.description || '';
  }
}, { immediate: true });

function handleSubmit() {
  emit('submit', { ...form });
}
</script>

<template>
  <form @submit.prevent="handleSubmit" class="space-y-8">
    <div class="space-y-5">
      <!-- Informações do Tipo de Serviço -->
      <div>
        <div>
          <h3 class="text-lg font-medium leading-6 text-gray-900">Dados do Tipo de Serviço</h3>
          <p class="mb-5 text-sm text-gray-500">Defina o nome e propósito deste tipo de serviço.</p>
        </div>
        <div class="grid grid-cols-1 gap-y-6 gap-x-4 sm:grid-cols-6">
          <div class="sm:col-span-4">
            <label class="block text-sm font-medium text-slate-700 mb-1">Nome do Tipo de Serviço <span
                class="font-bold">*</span></label>
            <input v-model="form.name" type="text" required
              placeholder="Ex.: PMOC"
              class="disabled:bg-slate-200 disabled:animate-pulse w-full px-3 py-2 border border-slate-300 rounded-md focus:outline-none focus:ring-1 focus:ring-slate-800 focus:border-slate-800 text-slate-700 placeholder-slate-400" />
            <p v-if="errors?.name" class="mt-1 text-sm text-red-600">{{ errors.name[0] }}</p>
          </div>
          <div class="sm:col-span-6">
            <label class="block text-sm font-medium text-slate-700 mb-1">Descrição</label>
            <textarea v-model="form.description" rows="3"
              placeholder="Ex.: Plano de Manutenção, Operação e Controle."
              class="resize-none disabled:bg-slate-200 disabled:animate-pulse w-full px-3 py-2 border border-slate-300 rounded-md focus:outline-none focus:ring-1 focus:ring-slate-800 focus:border-slate-800 text-slate-700 placeholder-slate-400"></textarea>
          </div>
        </div>
      </div>
    </div>
    <!-- Actions -->
    <div class="pt-5">
      <div class="flex justify-end gap-3">
        <button type="button" @click="emit('cancel')"
          class="disabled:bg-slate-200 disabled:cursor-not-allowed cursor-pointer rounded-md text-sm font-medium inline-flex items-center justify-center px-6 py-2 bg-white active:bg-slate-200 border border-slate-500 text-slate-800 hover:bg-slate-100 transition-all">
          Cancelar
        </button>
        <button type="submit" :disabled="isLoading"
          class="inline-flex items-center justify-center text-sm disabled:bg-primary-muted disabled:text-primary disabled:cursor-not-allowed rounded-md font-medium cursor-pointer px-6 py-2 bg-primary active:bg-primary-active text-primary-contrast hover:bg-primary-hover transition-all">
          Salvar
        </button>
      </div>
    </div>
  </form>
</template>