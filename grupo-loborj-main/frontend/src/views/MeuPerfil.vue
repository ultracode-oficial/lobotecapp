<script setup>
import { ref, watch } from 'vue';
import { usePage } from '@/composables/usePage';
import { useRelativeTime } from '@/composables/useRelativeTime';
import { vMaska } from 'maska/vue';
import api from '@/services/api';
import { useMutation, useQuery, useQueryClient } from '@tanstack/vue-query';
import { STORAGE_PATH } from '@/services/storage';
import { useAuthStore } from '@/stores/auth';
import { Loader2Icon, User2Icon } from '@lucide/vue';
import { useToastStore } from '@/stores/toast';

const { setHeader } = usePage();
const queryClient = useQueryClient();
const authStore = useAuthStore();
const toastStore = useToastStore();

setHeader('Meu Perfil', 'Gerencie suas informações pessoais');

const userForm = ref({
  name: '',
  cpf: '',
  email: '',
  phone: '',
  bio: '',
});

const readOnlyData = ref({
  photo: null,
  roles: '',
  createdAt: '',
  deletedAt: '',
  updatedAt: '',

  vendedorConfig: null,
  especializacoes: []
});

const fetchData = async () => {
  const { data } = await api.get('/auth/me');
  return data;
};

// 1. Vue Query limpo, servindo apenas para buscar e gerenciar o cache
const { data: profileData, isFetching: isFetchingProfile } = useQuery({
  queryKey: ["/auth/me"],
  queryFn: fetchData,
});

// 2. Watch para reagir aos dados do cache de forma segura
watch(profileData, (newData) => {
  if (newData) {
    userForm.value = {
      name: newData.user.name,
      cpf: newData.user.cpf,
      email: newData.user.email,
      phone: newData.user.phone,
      bio: newData.user.bio,
    };

    readOnlyData.value = {
      roles: newData.roles.join(", "),
      createdAt: newData.user.created_at,
      updatedAt: newData.user.updated_at,
      deletedAt: newData.user.deleted_at,
      photo: newData.user.photo?.trim().length > 0 ? newData.user.photo : null,
      vendedorConfig: newData.user.vendedorConfig,
      especializacoes: newData.user.especializacoes,
    };
  }
}, { immediate: true });

const saveProfile = async () => {
  const cleanData = {
    ...userForm.value,
    cpf: userForm.value.cpf?.replace(/\D/g, ''),
    phone: userForm.value.phone?.replace(/\D/g, '')
  };
  await api.put('/profile', cleanData);
};

const savePhoto = async (file) => {
  const formData = new FormData();
  formData.append('photo', file);

  const { data } = await api.post('/profile/photo', formData, {
    headers: { 'Content-Type': 'multipart/form-data' }
  });

  readOnlyData.value.photo = data.photo_url;
  await authStore.refetchUser(); // Sincroniza a foto nova com a Topbar!
};

const { isPending: isSavingProfile, mutate: mutateProfile } = useMutation({
  mutationFn: saveProfile,
  onError: (error) => {
    toastStore.send({
      message: error.message,
      style: "error",
    });
  },
  onSuccess: async () => {
    toastStore.send({
      message: 'Perfil atualizado com sucesso.',
      style: "success",
    });
    // Invalida o cache e atualiza o JWT no Pinia
    queryClient.invalidateQueries({ queryKey: ['/auth/me'] });
    await authStore.refetchUser();
  },
});

const { isPending: isSavingPhoto, mutate: mutatePhoto } = useMutation({
  mutationFn: savePhoto,
  onError: (error) => {
    toastStore.send({
      message: error.message,
      style: "error",
    });
  },
  onSuccess: async () => {
    toastStore.send({
      message: 'Foto atualizada com sucesso.',
      style: "success",
    });
    // Invalida o cache e atualiza o JWT no Pinia
    queryClient.invalidateQueries({ queryKey: ['/auth/me'] });
    await authStore.refetchUser();
  },
});

const triggerImageUpload = () => {
  const input = document.createElement('input');
  input.type = 'file';
  input.accept = 'image/jpeg, image/png, image/jpg';

  input.onchange = async (event) => {
    const file = event.target.files[0];
    if (!file) return;

    mutatePhoto(file);
  };

  input.click();
};

const dateFormatter = new Intl.DateTimeFormat("pt-BR", { dateStyle: "medium" });
const { getRelativeTime } = useRelativeTime();
</script>

<template>
  <div class="max-w-7xl w-full mx-auto py-3">
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-10">
      <div class="col-span-2">
        <h2 class="text-xl font-bold text-slate-800 mb-6">Informações de Perfil</h2>
        <div class="flex items-center gap-6 mb-8">
          <div
            class="w-24 h-24 rounded-full bg-slate-200 flex items-center justify-center overflow-hidden border border-slate-300">
            <img v-if="readOnlyData.photo" :src="`${STORAGE_PATH}${readOnlyData.photo}`" alt="Foto de Perfil"
              class="w-full h-full object-cover" />
            <User2Icon v-else class="size-15 text-slate-400"></User2Icon>
          </div>
          <button @click="triggerImageUpload" :disabled="isSavingPhoto"
            class="disabled:bg-primary-muted disabled:cursor-not-allowed cursor-pointer rounded-md text-sm font-medium inline-flex items-center justify-center px-6 py-2 bg-primary active:bg-primary-active text-primary-contrast hover:bg-primary-hover transition-all">
            <span v-if="!isSavingPhoto">
              Alterar Foto de Perfil
            </span>
            <Loader2Icon class="animate-spin" v-else></Loader2Icon>
          </button>
        </div>

        <form @submit.prevent="mutateProfile" class="space-y-5">
          <div class="grid grid-cols-1 md:grid-cols-2 gap-5">
            <div>
              <label class="block text-sm font-medium text-slate-700 mb-1">Nome Completo <span
                  class="font-bold">*</span></label>
              <input type="text" v-model="userForm.name" :disabled="isFetchingProfile || isSavingProfile" required
                class="disabled:bg-slate-200 disabled:animate-pulse w-full px-3 py-2 border border-slate-300 rounded-md focus:outline-none focus:ring-1 focus:ring-slate-800 focus:border-slate-800 text-slate-700 placeholder-slate-400"
                placeholder="Nome completo do titular da conta">
            </div>
            <div>
              <label class="block text-sm font-medium text-slate-700 mb-1">CPF <span class="font-bold">*</span></label>
              <input type="text" v-model="userForm.cpf" v-maska="'###.###.###-##'" required
                :disabled="isFetchingProfile || isSavingProfile"
                class="disabled:bg-slate-200 disabled:animate-pulse w-full px-3 py-2 border border-slate-300 rounded-md focus:outline-none focus:ring-1 focus:ring-slate-800 focus:border-slate-800 text-slate-700 placeholder-slate-400"
                placeholder="000.000.000-00">
            </div>
            <div>
              <label class="block text-sm font-medium text-slate-700 mb-1">E-mail <span
                  class="font-bold">*</span></label>
              <input type="email" v-model="userForm.email" :disabled="isFetchingProfile || isSavingProfile" required
                class="disabled:bg-slate-200 disabled:animate-pulse w-full px-3 py-2 border border-slate-300 rounded-md focus:outline-none focus:ring-1 focus:ring-slate-800 focus:border-slate-800 text-slate-700 placeholder-slate-400"
                placeholder="email@exemplo.com">
            </div>
            <div>
              <label class="block text-sm font-medium text-slate-700 mb-1">Telefone</label>
              <input type="text" v-model="userForm.phone" :disabled="isFetchingProfile || isSavingProfile"
                class="disabled:bg-slate-200 disabled:animate-pulse w-full px-3 py-2 border border-slate-300 rounded-md focus:outline-none focus:ring-1 focus:ring-slate-800 focus:border-slate-800 text-slate-700 placeholder-slate-400"
                placeholder="(00) 00000-0000" v-maska data-maska="['(##)####-####','(##)#####-####']">
            </div>
          </div>

          <div>
            <label class="block text-sm font-medium text-slate-700 mb-1">Informações Complementares</label>
            <textarea v-model="userForm.bio" rows="3" :disabled="isFetchingProfile || isSavingProfile"
              class="disabled:bg-slate-200 disabled:animate-pulse w-full px-3 py-2 border border-slate-300 rounded-md focus:outline-none focus:ring-1 focus:ring-slate-800 focus:border-slate-800 text-slate-700 placeholder-slate-400 resize-none"
              placeholder="Observações, biografia/descrição profissional"></textarea>
          </div>

          <div class="flex items-center gap-4 pt-4">
            <button type="submit" :disabled="isFetchingProfile || isSavingProfile"
              class="disabled:bg-primary-muted disabled:cursor-not-allowed cursor-pointer rounded-md text-sm font-medium inline-flex items-center justify-center px-6 py-2 bg-primary active:bg-primary-active text-primary-contrast hover:bg-primary-hover transition-all">
              <span v-if="!isSavingProfile">
                Salvar Perfil
              </span>
              <Loader2Icon class="animate-spin" v-else></Loader2Icon>
            </button>
            <router-link to="/" :disabled="isFetchingProfile || isSavingProfile"
              class="disabled:bg-slate-200 disabled:cursor-not-allowed cursor-pointer rounded-md text-sm font-medium inline-flex items-center justify-center px-6 py-2 bg-white active:bg-slate-200 border border-slate-500 text-slate-800 hover:bg-slate-100 transition-all">
              Cancelar
            </router-link>
          </div>
        </form>
      </div>
      <div class="col-span-1 flex flex-col gap-x-6 gap-y-4">
        <div class="flex flex-col">
          <h2 class="text-xl font-bold text-slate-800 mb-3">Informações Adicionais</h2>
          <div class="bg-slate-50 border border-slate-100 rounded-md p-5 space-y-4">
            <div class="grid grid-cols-2 gap-2 text-sm">
              <span class="font-medium text-slate-700">Cargo</span>
              <span class="text-slate-600">{{ readOnlyData.roles }}</span>
            </div>
            <div class="grid grid-cols-2 gap-2 text-sm">
              <span class="font-medium text-slate-700">Data de Cadastro</span>
              <span class="text-slate-600">{{ readOnlyData.createdAt ? dateFormatter.format(new
                Date(readOnlyData.createdAt)) : null }}</span>
            </div>
            <div class="grid grid-cols-2 gap-2 text-sm">
              <span class="font-medium text-slate-700">Status da Conta</span>
              <span class="text-slate-600">{{ readOnlyData.deletedAt ? "Desativado" : "Ativo" }}</span>
            </div>
            <div class="grid grid-cols-2 gap-2 text-sm">
              <span class="font-medium text-slate-700">Perfil Atualizado</span>
              <span class="text-slate-600">{{ readOnlyData.updatedAt ? getRelativeTime(readOnlyData.updatedAt) : null
              }}</span>
            </div>
          </div>
        </div>
        <div v-if="!!readOnlyData.vendedorConfig" class="flex flex-col">
          <h2 class="text-xl font-bold text-slate-800 mb-3">Modelo de Comissionamento</h2>
          <div class="bg-slate-50 border border-slate-100 rounded-md p-5 space-y-4">
            <div class="grid grid-cols-2 gap-2 text-sm">
              <span class="font-medium text-slate-700">Tipo de Comissão</span>
              <span class="text-slate-600">{{ readOnlyData.vendedorConfig.tipo_comissao === "PORCENTAGEM" ?
                "Porcentagem" : "Valor Fixo" }}</span>
            </div>
            <div class="grid grid-cols-2 gap-2 text-sm">
              <span class="font-medium text-slate-700">{{ readOnlyData.vendedorConfig.tipo_comissao === "PORCENTAGEM" ?
                "Quantidade" : "Valor" }}</span>
              <span class="text-slate-600">{{ readOnlyData.vendedorConfig.tipo_comissao === "PORCENTAGEM" ?
                `${readOnlyData.vendedorConfig.porcentagem_comissao}%` : `R$
                ${(readOnlyData.vendedorConfig.valor_fixo_comissao_centavos / 100).toFixed(2)}` }}</span>
            </div>
          </div>
        </div>
        <div class="flex flex-col" v-if="readOnlyData.especializacoes.length > 0">
          <h2 class="text-xl font-bold text-slate-800 mb-3">Especializações</h2>
          <div class="bg-slate-50 border border-slate-100 rounded-md p-3 flex flex-wrap gap-2 items-start">
            <p :title="espec.description"
              class="px-2 py-0.5 rounded border border-slate-600 bg-slate-500 font-bold text-slate-50 text-sm uppercase"
              v-for="espec in readOnlyData.especializacoes" :key="`espec-${espec.id}`">{{ espec.name }}</p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>