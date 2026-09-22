<script setup lang="ts">
import { ref } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import UserForm from '@/components/users/UserForm.vue';
import { useUserQuery, useUpdateUserMutation, useUserFormEspecializacaoOptionsData, useUserFormRoleOptionsData } from '@/composables/useUsers.ts';
import { useToastStore } from '@/stores/toast';
import type { AxiosError } from 'axios';
import { Loader2Icon } from '@lucide/vue';

const route = useRoute();
const router = useRouter();
const toastStore = useToastStore();

const userId = route.params.id as string;

// Buscas paralelas: Dados do usuário + Opções dos selects
const { data: user, isLoading: isUserLoading } = useUserQuery(userId);
const { data: especializacaoOptions } = useUserFormEspecializacaoOptionsData();
const { data: roleOptions } = useUserFormRoleOptionsData();

const updateMutation = useUpdateUserMutation();
const validationErrors = ref({});

async function handleSubmit(payload: any) {
  try {
    validationErrors.value = {};
    await updateMutation.mutateAsync({ id: userId, payload });

    toastStore.send({ message: 'Usuário atualizado com sucesso.', style: 'success' });
    router.push({ name: 'users.index' });
  } catch (error: unknown) {
    const axiosError = error as AxiosError<any>;
    if (axiosError.response?.status === 422) {
      validationErrors.value = axiosError.response.data.errors;
      toastStore.send({ message: 'Verifique os erros no formulário.', style: 'warning' });
    } else {
      const err = error as any;
      toastStore.send({ message: err?.errors ? Object.values(err.errors).flat().join(' ') : err?.message ?? 'Erro interno ao atualizar usuário.', style: 'error' });
    }
  }
}
</script>

<template>
  <div class="max-w-7xl w-full mx-auto space-y-6 py-3">
    <div class="md:flex md:items-center md:justify-between">
      <div class="min-w-0 flex-1">
        <h2 class="text-xl font-bold text-slate-800">Editar Usuário</h2>
      </div>
    </div>

    <div class="bg-white px-4 py-5 shadow sm:rounded-lg sm:p-6">
      <div v-if="isUserLoading" class="flex justify-center py-10">
        <Loader2Icon class="animate-spin size-8 text-slate-600"></Loader2Icon>
      </div>

      <UserForm v-else-if="user" :initial-data="user" :especializacao-options="especializacaoOptions"
        :role-options="roleOptions" :is-loading="updateMutation.isPending.value" :errors="validationErrors"
        @submit="handleSubmit" @cancel="router.push({ name: 'users.index' })" />
    </div>
  </div>
</template>