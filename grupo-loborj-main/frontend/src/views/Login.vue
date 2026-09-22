<script setup>
import { ref, reactive } from 'vue';
import { useRouter } from 'vue-router';
import { useAuthStore } from '@/stores/auth';
import banner from "@/assets/banner-color-horizontal.png";
import api from '@/services/api';
import { EyeIcon, EyeOffIcon, Loader2Icon } from '@lucide/vue';
import axios from 'axios';
import { useToastStore } from '@/stores/toast';
import { vMaska } from "maska/vue"

const router = useRouter();
const authStore = useAuthStore();
const toastStore = useToastStore();

const step = ref('credentials'); // 'credentials' ou 'mfa'
const credentials = reactive({ login: '', password: '' });
const showPassword = ref(false);
const mfaCode = ref('');
const useRecoveryCode = ref(false);
const isLoading = ref(false);

const handleLogin = async () => {
  isLoading.value = true;
  toastStore.clearToast();

  try {
    const { data } = await axios.post(`${api.defaults.baseURL}/auth/login`, credentials, {
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-Platform': 'web'
      }
    });

    if (data.status === 'requires_mfa') {
      // Guarda o mfa_token na store SEM persistir no localStorage (persist = false)
      authStore.setToken(data.mfa_token, null, false);
      step.value = 'mfa';
    } else {
      // Login direto (MFA opcional ou não configurado)
      authStore.setToken(data.access_token, data.user, true); // Persiste por 7 dias
      router.push({ name: 'dashboard' });
    }
  } catch (error) {
    toastStore.send({
      style: "error",
      message: error.response.data?.message ?? 'Erro ao tentar acessar.'
    })
  } finally {
    isLoading.value = false;
  }
};

const handleMfaVerify = async () => {
  isLoading.value = true;
  toastStore.clearToast();

  try {
    // Como o mfa_token está na store, o interceptor do Axios injeta ele automaticamente aqui
    const { data } = await api.post('/auth/mfa/verify', { code: mfaCode.value });

    // Substitui o token provisório pelo token definitivo de 7 dias e PERSISTE
    authStore.setToken(data.access_token, data.user, true);
    if (data.mfa_disabled_due_to_recovery) {
      toastStore.send({
        style: "warning",
        message: 'Código de recuperação utilizado. A autenticação multifator (MFA) foi desativada.'
      })
    }
    router.push({ name: 'dashboard' });
  } catch (error) {
    toastStore.send({
      style: "error",
      message: error.message ?? 'Código inválido ou expirado.'
    })

  } finally {
    isLoading.value = false;
  }
};

const backToCredentials = () => {
  authStore.logout();
  step.value = 'credentials';
  mfaCode.value = '';
  useRecoveryCode.value = false; // Reseta o estado ao voltar
};

const toggleRecoveryMode = () => {
  useRecoveryCode.value = !useRecoveryCode.value;
  mfaCode.value = ''; // Limpa o input ao alternar entre os métodos
};
</script>
<template>
  <div class="flex flex-col items-center mx-auto my-10">
    <img :src="banner" width="380" alt="Banner" class="mb-6">
    <form v-if="step === 'credentials'" @submit.prevent="handleLogin" class="flex flex-col">
      <h1 class="text-center text-3xl font-medium mb-2 text-primary">Acesse sua Conta</h1>
      <p class="text-center mb-6 text-slate-600 max-w-sm">Insira suas credenciais para acessar o sistema</p>
      <div class="flex flex-col mb-5">
        <label class="mb-2">E-mail, Telefone ou CPF</label>
        <input class="rounded border border-slate-300 focus:border-slate-500 outline-0 p-2" v-model="credentials.login"
          type="text" required placeholder="Digite seus dados" />
      </div>
      <div class="flex flex-col mb-2">
        <label class="mb-2">Senha</label>
        <div class="relative">
          <input class="w-full rounded border border-slate-300 focus:border-slate-500 outline-0 p-2 pr-10"
            v-model="credentials.password" :type="showPassword ? 'text' : 'password'" required
            placeholder="Sua nova senha" />
          <button type="button" @click="showPassword = !showPassword"
            class="cursor-pointer absolute right-3 top-2.5 text-slate-400 hover:text-slate-600">
            <EyeIcon v-if="!showPassword" class="size-5"></EyeIcon>
            <EyeOffIcon v-else class="size-5"></EyeOffIcon>
          </button>
        </div>
      </div>
      <router-link class="ml-auto text-sm text-primary hover:text-primary-hover hover:underline mb-6"
        to="/forgot-password">Esqueceu sua senha?</router-link>
      <button type="submit" :disabled="isLoading"
        class="px-6 py-2 cursor-pointer bg-primary hover:bg-primary-hover transition-colors text-white rounded">
        <Loader2Icon v-if="isLoading" class="mx-auto animate-spin size-6" />
        <span v-else>Avançar</span>
      </button>
    </form>
    <form v-else-if="step === 'mfa'" @submit.prevent="handleMfaVerify" class="flex flex-col w-full max-w-sm">

      <h1 class="text-center text-3xl font-medium mb-2 text-primary">
        {{ useRecoveryCode ? 'Recuperação de Conta' : 'Autenticação (MFA)' }}
      </h1>

      <p class="text-center mb-6 text-slate-600">
        {{ useRecoveryCode
          ? 'Digite um dos seus códigos de recuperação de emergência.'
          : 'Abra seu aplicativo de autenticação e digite o código gerado.'
        }}
      </p>

      <div class="flex flex-col mb-4 mx-auto w-full items-center">
        <label class="mb-2 text-center">
          {{ useRecoveryCode ? 'Código de Recuperação' : 'Código de 6 dígitos' }}
        </label>
        <!-- Input MFA Padrão (6 dígitos numéricos) -->
        <input v-if="!useRecoveryCode"
          class="rounded border border-slate-300 focus:border-slate-500 outline-0 p-2 w-48 text-center text-xl tracking-[0.5em]"
          v-model="mfaCode" type="text" maxlength="6" required placeholder="000000" autocomplete="one-time-code"
          v-maska="'######'" />
        <!-- Input Código de Recuperação (geralmente mais longo, string alfanumérica) -->
        <input v-else
          class="rounded border border-slate-300 focus:border-slate-500 outline-0 p-2 w-full text-center text-lg tracking-widest uppercase"
          v-model="mfaCode" type="text" maxlength="14" required placeholder="0000-0000-0000"
          v-maska="'****-****-****'" />
      </div>
      <div class="flex justify-center gap-4">
        <button type="submit" :disabled="isLoading"
          class="px-4 py-2 cursor-pointer bg-primary hover:bg-primary-hover transition-colors text-white rounded flex-1">
          <Loader2Icon v-if="isLoading" class="mx-auto animate-spin size-6" />
          <span v-else>Confirmar</span>
        </button>
        <button type="button" @click="backToCredentials"
          class="px-4 py-2 cursor-pointer bg-slate-500 hover:bg-slate-400 text-white rounded flex-1">
          Cancelar
        </button>
      </div>
      <!-- Botão para alternar entre MFA e Código de Recuperação -->
      <button type="button" @click="toggleRecoveryMode"
        class="cursor-pointer text-sm text-primary hover:text-primary-hover hover:underline mt-6 mx-auto transition-colors">
        {{ useRecoveryCode ? `Voltar para o aplicativo de autenticação` : `Não tem acesso ao app? Usar código de
        recuperação` }}
      </button>
    </form>
  </div>
</template>