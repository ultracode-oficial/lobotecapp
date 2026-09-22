<script setup lang="ts">
import { ref } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import ClienteForm from '@/components/clientes/ClienteForm.vue';
import { useClienteQuery, useUpdateClienteMutation, useClienteFormTipoEquipamentosOptionsData, useVendedoresQuery } from '@/composables/useClientes.ts';
import { useToastStore } from '@/stores/toast';
import type { AxiosError } from 'axios';
import { Loader2Icon } from '@lucide/vue';

const route = useRoute();
const router = useRouter();
const toastStore = useToastStore();

const clienteId = route.params.id as string;

// Buscas paralelas: Dados do cliente + Opções dos selects
const { data: cliente, isLoading: isClienteLoading } = useClienteQuery(clienteId);
const { data: tipoEquipamentosOptions } = useClienteFormTipoEquipamentosOptionsData();
const { data: vendedoresData } = useVendedoresQuery();

const updateMutation = useUpdateClienteMutation();
const validationErrors = ref({});

async function handleSubmit(payload: any) {
  try {
    validationErrors.value = {};
    await updateMutation.mutateAsync({ id: clienteId, payload });

    toastStore.send({ message: 'Cliente atualizado com sucesso.', style: 'success' });
    router.push({ name: 'clientes.index' });
  } catch (error: unknown) {
    const axiosError = error as AxiosError<any>;
    if (axiosError.response?.status === 422) {
      validationErrors.value = axiosError.response.data.errors;
      toastStore.send({ message: 'Verifique os erros no formulário.', style: 'warning' });
    } else {
      const err = error as any;
      toastStore.send({ message: err?.errors ? Object.values(err.errors).flat().join(' ') : err?.message ?? 'Erro interno ao atualizar cliente.', style: 'error' });
    }
  }
}
</script>

<template>
  <div class="max-w-7xl w-full mx-auto space-y-6 py-3">
    <div class="md:flex md:items-center md:justify-between">
      <div class="min-w-0 flex-1">
        <h2 class="text-xl font-bold text-slate-800">Editar Cliente</h2>
      </div>
    </div>

    <div class="bg-white px-4 py-5 shadow sm:rounded-lg sm:p-6">
      <div v-if="isClienteLoading" class="flex justify-center py-10">
        <Loader2Icon class="animate-spin size-8 text-slate-600"></Loader2Icon>
      </div>

      <ClienteForm v-else-if="cliente" :initial-data="cliente"
        :tipo-equipamentos-options="tipoEquipamentosOptions?.tipoEquipamentos"
        :vendedores-options="vendedoresData?.vendedores" :is-loading="updateMutation.isPending.value"
        :errors="validationErrors" @submit="handleSubmit" @cancel="router.push({ name: 'clientes.index' })" />
    </div>
  </div>
</template>