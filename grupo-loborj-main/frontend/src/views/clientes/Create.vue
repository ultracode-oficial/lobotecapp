<script setup lang="ts">
import { ref } from 'vue';
import { useRouter } from 'vue-router';
import ClienteForm from '@/components/clientes/ClienteForm.vue';
import { useCreateClienteMutation, useClienteFormTipoEquipamentosOptionsData, useVendedoresQuery } from '@/composables/useClientes.ts';
import { useToastStore } from '@/stores/toast';
import type { AxiosError } from 'axios';

const router = useRouter();
const toastStore = useToastStore();
const { data: tipoEquipamentosOptions } = useClienteFormTipoEquipamentosOptionsData();
const { data: vendedoresData } = useVendedoresQuery();
const createMutation = useCreateClienteMutation();
const validationErrors = ref({});

async function handleSubmit(payload: any) {
  try {
    validationErrors.value = {}; // limpa erros anteriores
    await createMutation.mutateAsync(payload);

    toastStore.send({ message: 'Cliente cadastrado com sucesso.', style: 'success' });
    router.push({ name: 'clientes.index' });
  } catch (error) {
    const axiosError = error as AxiosError<any>;
    if (axiosError.response?.status === 422) {
      validationErrors.value = axiosError.response.data.errors;
      toastStore.send({ message: 'Verifique os erros no formulário.', style: 'warning' });
    } else {
      const err = error as any;
      toastStore.send({ message: err?.errors ? Object.values(err.errors).flat().join(' ') : err?.message ?? 'Erro interno ao criar cliente.', style: 'error' });
    }
  }
}
</script>

<template>
  <div class="max-w-7xl w-full mx-auto space-y-6 py-3">
    <div class="md:flex md:items-center md:justify-between">
      <div class="min-w-0 flex-1">
        <h2 class="text-xl font-bold text-slate-800">Novo Cliente</h2>
      </div>
    </div>

    <div class="bg-white px-4 py-5 shadow sm:rounded-lg sm:p-6">
      <ClienteForm :tipo-equipamentos-options="tipoEquipamentosOptions?.tipoEquipamentos"
        :vendedores-options="vendedoresData?.vendedores" :is-loading="createMutation.isPending.value"
        :errors="validationErrors" @submit="handleSubmit" @cancel="router.push({ name: 'clientes.index' })" />
    </div>
  </div>
</template>