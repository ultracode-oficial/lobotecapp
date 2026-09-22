<script setup lang="ts">
import { ref } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import TipoServicoForm from '@/components/tipoServicos/TipoServicoForm.vue';
import { useTipoServicoQuery, useUpdateTipoServicoMutation } from '@/composables/useTipoServicos';
import { useToastStore } from '@/stores/toast';

const route = useRoute();
const router = useRouter();
const toast = useToastStore();
const equipeId = route.params.id as string;
const toastStore = useToastStore();
const { data: tipoServico, isLoading: isTipoServicoLoading } = useTipoServicoQuery(equipeId);
const updateMutation = useUpdateTipoServicoMutation();
const validationErrors = ref({});

async function handleSubmit(payload: any) {
  try {
    validationErrors.value = {};
    await updateMutation.mutateAsync({ id: equipeId, payload });
    toast.send({ message: 'Tipo de Serviço atualizado com sucesso.', style: 'success' });
    router.push({ name: 'tipoServicos.index' });
  } catch (error: any) {
    if (error.response?.status === 422) {
      validationErrors.value = error.response.data.errors;
    } else {
      const err = error as any;
      toastStore.send({ message: err?.errors ? Object.values(err.errors).flat().join(' ') : err?.message ?? 'Erro interno ao atualizar tipoServico.', style: 'error' });
    }
  }
}
</script>

<template>
  <div class="max-w-7xl w-full mx-auto space-y-6 py-3">
    <div class="md:flex md:items-center md:justify-between">
      <div class="min-w-0 flex-1">
        <h2 class="text-xl font-bold text-slate-800">Editar Tipo de Serviço</h2>
      </div>
    </div>
    <div class="bg-white px-4 py-5 shadow sm:rounded-lg sm:p-6">
      <div v-if="isTipoServicoLoading" class="flex justify-center py-10">
        <Loader2Icon class="animate-spin size-8 text-slate-600"></Loader2Icon>
      </div>
      <TipoServicoForm v-else-if="tipoServico" :initial-data="tipoServico" :is-loading="updateMutation.isPending.value"
        :errors="validationErrors" @submit="handleSubmit" @cancel="router.push({ name: 'tipoServicos.index' })" />
    </div>
  </div>
</template>