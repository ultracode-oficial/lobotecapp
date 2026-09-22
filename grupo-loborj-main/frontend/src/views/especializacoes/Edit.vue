<script setup lang="ts">
import { ref } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import EspecializacaoForm from '@/components/especializacoes/EspecializacaoForm.vue';
import { useEspecializacaoQuery, useUpdateEspecializacaoMutation } from '@/composables/useEspecializacoes';
import { useToastStore } from '@/stores/toast';

const route = useRoute();
const router = useRouter();
const toast = useToastStore();
const especializacaoId = route.params.id as string;
const toastStore = useToastStore();
const { data: especializacao, isLoading: isEspecializacaoLoading } = useEspecializacaoQuery(especializacaoId);
const updateMutation = useUpdateEspecializacaoMutation();
const validationErrors = ref({});

async function handleSubmit(payload: any) {
  try {
    validationErrors.value = {};
    await updateMutation.mutateAsync({ id: especializacaoId, payload });
    toast.send({ message: 'Especialização/requisito atualizado com sucesso.', style: 'success' });
    router.push({ name: 'especializacoes.index' });
  } catch (error: any) {
    if (error.response?.status === 422) {
      validationErrors.value = error.response.data.errors;
    } else {
      const err = error as any;
      toastStore.send({ message: err?.errors ? Object.values(err.errors).flat().join(' ') : err?.message ?? 'Erro interno ao atualizar especialização/requisito.', style: 'error' });
    }
  }
}
</script>

<template>
  <div class="max-w-7xl w-full mx-auto space-y-6 py-3">
    <div class="md:flex md:items-center md:justify-between">
      <div class="min-w-0 flex-1">
        <h2 class="text-xl font-bold text-slate-800">Editar Especialização e Requisito</h2>
      </div>
    </div>
    <div class="bg-white px-4 py-5 shadow sm:rounded-lg sm:p-6">
      <div v-if="isEspecializacaoLoading" class="flex justify-center py-10">
        <Loader2Icon class="animate-spin size-8 text-slate-600"></Loader2Icon>
      </div>
      <EspecializacaoForm v-else-if="especializacao" :initial-data="especializacao" :is-loading="updateMutation.isPending.value"
        :errors="validationErrors" @submit="handleSubmit" @cancel="router.push({ name: 'especializacoes.index' })" />
    </div>
  </div>
</template>