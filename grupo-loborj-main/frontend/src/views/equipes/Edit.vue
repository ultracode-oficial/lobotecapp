<script setup lang="ts">
import { ref } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import EquipeForm from '@/components/equipes/EquipeForm.vue';
import { useEquipeQuery, useUpdateEquipeMutation, useTecnicosQuery } from '@/composables/useEquipes';
import { useToastStore } from '@/stores/toast';

const route = useRoute();
const router = useRouter();
const toast = useToastStore();
const equipeId = route.params.id as string;
const toastStore = useToastStore();
const { data: equipe, isLoading: isEquipeLoading } = useEquipeQuery(equipeId);
const { data: tecnicosData } = useTecnicosQuery();
const updateMutation = useUpdateEquipeMutation();
const validationErrors = ref({});

async function handleSubmit(payload: any) {
  try {
    validationErrors.value = {};
    await updateMutation.mutateAsync({ id: equipeId, payload });
    toast.send({ message: 'Equipe atualizada com sucesso.', style: 'success' });
    router.push({ name: 'equipes.index' });
  } catch (error: any) {
    if (error.response?.status === 422) {
      validationErrors.value = error.response.data.errors;
    } else {
      const err = error as any;
      toastStore.send({ message: err?.errors ? Object.values(err.errors).flat().join(' ') : err?.message ?? 'Erro interno ao atualizar equipe.', style: 'error' });
    }
  }
}
</script>

<template>
  <div class="max-w-7xl w-full mx-auto space-y-6 py-3">
    <div class="md:flex md:items-center md:justify-between">
      <div class="min-w-0 flex-1">
        <h2 class="text-xl font-bold text-slate-800">Editar Equipe</h2>
      </div>
    </div>
    <div class="bg-white px-4 py-5 shadow sm:rounded-lg sm:p-6">
      <div v-if="isEquipeLoading" class="flex justify-center py-10">
        <Loader2Icon class="animate-spin size-8 text-slate-600"></Loader2Icon>
      </div>
      <EquipeForm v-else-if="equipe" :initial-data="equipe" :tecnicos="tecnicosData?.tecnicos"
        :is-loading="updateMutation.isPending.value" :errors="validationErrors" @submit="handleSubmit"
        @cancel="router.push({ name: 'equipes.index' })" />
    </div>
  </div>
</template>