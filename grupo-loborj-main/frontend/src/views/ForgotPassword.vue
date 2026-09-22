<script setup>
import { ref, reactive } from 'vue';
import { useRouter } from 'vue-router';
import banner from "@/assets/banner-color-horizontal.png";
import api from '@/services/api';
import { CheckIcon, EyeIcon, EyeOffIcon, Loader2Icon } from '@lucide/vue';

const router = useRouter();

// Controle de fluxo das telas: 'request', 'verify', 'reset', 'success'
const step = ref('request');
const isLoading = ref(false);
const errorMessage = ref('');

// Dados do formulário
const email = ref('');
const code = ref('');
const password = ref('');
const passwordConfirmation = ref('');
const showPassword = ref(false);

// Passo 1: Solicitar o código por e-mail
const handleRequestCode = async () => {
  isLoading.value = true;
  errorMessage.value = '';

  try {
    await api.post('/auth/forgot-password', { email: email.value });
    step.value = 'verify';
  } catch (error) {
    errorMessage.value = error.response?.data?.error || 'Erro ao solicitar recuperação de senha.';
  } finally {
    isLoading.value = false;
  }
};

// Passo 2: Validar o código de 6 dígitos
const handleVerifyCode = async () => {
  isLoading.value = true;
  errorMessage.value = '';

  try {
    await api.post('/auth/verify-code', {
      email: email.value,
      code: code.value
    });
    step.value = 'reset';
  } catch (error) {
    errorMessage.value = error.response?.data?.error || 'Código inválido ou expirado.';
  } finally {
    isLoading.value = false;
  }
};

// Passo 3: Definir a nova senha
const handleResetPassword = async () => {
  isLoading.value = true;
  errorMessage.value = '';

  try {
    await api.post('/auth/reset-password', {
      email: email.value,
      code: code.value,
      password: password.value,
      password_confirmation: passwordConfirmation.value
    });
    step.value = 'success';
  } catch (error) {
    errorMessage.value = error.response?.data?.error || 'Erro ao redefinir a senha.';
  } finally {
    isLoading.value = false;
  }
};

const backToLogin = () => {
  router.push({ name: 'login' });
};
</script>
<template>
  <div class="flex flex-col items-center mx-auto mt-12">
    <img :src="banner" width="380" alt="Banner" class="mb-6">

    <form v-if="step === 'request'" @submit.prevent="handleRequestCode" class="flex flex-col w-full max-w-sm">
      <h1 class="text-center text-3xl font-medium mb-2 text-primary">Esqueci minha senha</h1>
      <p class="text-center mb-6 text-slate-600">
        Insira o e-mail associado à sua conta e enviaremos um código para redefinir sua senha.
      </p>

      <div class="flex flex-col mb-6">
        <label class="mb-2">E-mail</label>
        <input class="rounded border border-slate-300 focus:border-slate-500 outline-0 p-2" v-model="email" type="email"
          required placeholder="Digite seu e-mail" />
      </div>

      <div class="text-red-500 text-center text-sm mb-4" v-if="errorMessage">{{ errorMessage }}</div>

      <button type="submit" :disabled="isLoading"
        class="px-6 py-2 cursor-pointer bg-primary hover:bg-primary-hover transition-colors text-white rounded mb-4">
        <Loader2Icon v-if="isLoading" class="mx-auto animate-spin size-6" />
        <span v-else>Enviar Código</span>
      </button>

      <router-link to="/login" class="mx-auto text-sm text-primary hover:text-primary-hover hover:underline mb-6">
        Voltar para o Login
      </router-link>
    </form>

    <form v-else-if="step === 'verify'" @submit.prevent="handleVerifyCode" class="flex flex-col w-full max-w-sm">
      <h1 class="text-center text-3xl font-medium mb-2 text-primary">Verifique seu e-mail</h1>
      <p class="text-center mb-6 text-slate-600">
        Enviamos um código de verificação de 6 dígitos para <strong>{{ email }}</strong>. Digite-o abaixo.
      </p>
      <div class="flex flex-col mb-6 mx-auto">
        <label class="mb-2 text-center">Código de 6 dígitos</label>
        <input
          class="rounded border border-slate-300 focus:border-slate-500 outline-0 p-2 w-48 text-center text-xl tracking-[0.5em]"
          v-model="code" type="text" maxlength="6" required placeholder="000000" autocomplete="one-time-code" />
      </div>
      <div class="text-red-500 text-center text-sm mb-4" v-if="errorMessage">{{ errorMessage }}</div>
      <button type="submit" :disabled="isLoading"
        class="px-6 py-2 cursor-pointer bg-primary hover:bg-primary-hover transition-colors text-white rounded mb-4">
        <Loader2Icon v-if="isLoading" class="mx-auto animate-spin size-6" />
        <span v-else>Verificar Código</span>
      </button>
      <div class="flex justify-between w-full">
        <button type="button" @click="handleRequestCode" :disabled="isLoading"
          class="text-sm text-primary hover:underline">
          Reenviar código
        </button>
        <button type="button" @click="step = 'request'" class="text-sm text-slate-500 hover:underline">
          Alterar e-mail
        </button>
      </div>
    </form>

    <form v-else-if="step === 'reset'" @submit.prevent="handleResetPassword" class="flex flex-col w-full max-w-sm">
      <h1 class="text-center text-3xl font-medium mb-2 text-primary">Crie uma nova senha</h1>
      <p class="text-center mb-6 text-slate-600">
        Sua nova senha deve ter pelo menos 8 caracteres.
      </p>
      <div class="flex flex-col mb-4 relative">
        <label class="mb-2">Nova Senha</label>
        <div class="relative">
          <input class="w-full rounded border border-slate-300 focus:border-slate-500 outline-0 p-2 pr-10"
            v-model="password" :type="showPassword ? 'text' : 'password'" required placeholder="Sua nova senha"
            minlength="8" />
          <button type="button" @click="showPassword = !showPassword"
            class="cursor-pointer absolute right-3 top-2.5 text-slate-400 hover:text-slate-600">
            <EyeIcon v-if="!showPassword" class="size-5"></EyeIcon>
            <EyeOffIcon v-else class="size-5"></EyeOffIcon>
          </button>
        </div>
      </div>
      <div class="flex flex-col mb-6">
        <label class="mb-2">Confirmar Nova Senha</label>
        <input class="w-full rounded border border-slate-300 focus:border-slate-500 outline-0 p-2"
          v-model="passwordConfirmation" :type="showPassword ? 'text' : 'password'" required
          placeholder="Repita a senha" minlength="8" />
      </div>
      <div class="text-red-500 text-center text-sm mb-4" v-if="errorMessage">{{ errorMessage }}</div>
      <button type="submit" :disabled="isLoading"
        class="px-6 py-2 cursor-pointer bg-primary hover:bg-primary-hover transition-colors text-white rounded">
        <Loader2Icon v-if="isLoading" class="mx-auto animate-spin size-6" />
        <span v-else>Redefinir Senha</span>
      </button>
    </form>

    <div v-else-if="step === 'success'" class="flex flex-col items-center w-full max-w-sm text-center">
      <div class="w-16 h-16 bg-primary text-primary-contrast rounded-full flex items-center justify-center mb-4">
        <CheckIcon class="size-8"></CheckIcon>
      </div>
      <h1 class="text-3xl font-medium mb-2 text-primary">Senha redefinida!</h1>
      <p class="mb-8 text-slate-600">
        Sua senha foi atualizada com sucesso. Agora você pode usar sua nova senha para acessar o sistema.
      </p>
      <button @click="backToLogin"
        class="w-full px-6 py-2 cursor-pointer bg-primary hover:bg-primary-hover transition-colors text-white rounded">
        Voltar para o Login
      </button>
    </div>

  </div>
</template>