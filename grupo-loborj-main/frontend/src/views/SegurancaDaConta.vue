<script setup>
import { ref } from 'vue';
import { usePage } from '@/composables/usePage';
import api from '@/services/api';
import { useToastStore } from '@/stores/toast';
import { useMutation, useQuery, useQueryClient } from '@tanstack/vue-query';
import { CheckIcon, CopyIcon, EyeIcon, EyeOffIcon, Loader2Icon, LockIcon, XIcon } from '@lucide/vue';
import { passwordRequirements } from '@/services/featureFlags';
import { useAuthStore } from '@/stores/auth';
import { vMaska } from 'maska/vue';

const { setHeader } = usePage();
setHeader('Segurança da Conta', 'Gerencie senhas e autenticação de dois fatores');

const toastStore = useToastStore();
const authStore = useAuthStore();
const queryClient = useQueryClient();

// Senha
const passForm = ref({
  current_password: '',
  password: '',
  password_confirmation: ''
});
const showPasswords = ref({ current_password: false, password: false, password_confirmation: false });

const togglePass = (field) => {
  showPasswords.value[field] = !showPasswords.value[field];
};

const savePassword = () => {
  if (passForm.value.password !== passForm.value.password_confirmation) {
    throw new Error('A nova senha e a confirmação da nova senha devem ser iguais.');
  }

  return api.post('/auth/change-password', passForm.value);
};

const { isPending: isChangingPassword, mutate: mutatePassword } = useMutation({
  mutationFn: savePassword,
  onError: (error) => {
    toastStore.send({
      message: error.message,
      style: "error",
    });
  },
  onSuccess: () => {
    toastStore.send({
      message: 'Senha alterada com sucesso!',
      style: "success",
    });

    authStore.refetchUser();
    passForm.value = { current_password: '', password: '', password_confirmation: '' };
  },
});

// MFA
const activeModal = ref(null); // 'intro', 'qrcode', 'success', 'deactivate', 'recovery'
const mfaCodeInput = ref('');
const mfaDeactivateForm = ref({ password: '', code: '' });
const copiedStatus = ref(false);

const closeModals = () => {
  activeModal.value = null;
  mfaCodeInput.value = '';
  mfaDeactivateForm.value = { password: '', code: '' };
};

const copyToClipboard = (text) => {
  navigator.clipboard.writeText(text);
  copiedStatus.value = true;
  setTimeout(() => copiedStatus.value = false, 2000);
};

// Query para buscar o código de backup sempre que abrir o modal de visualização
const { data: recoveryCodeData, refetch: fetchRecoveryCode, isPending: isLoadingRecovery } = useQuery({
  queryKey: ['mfa-recovery-code'],
  queryFn: async () => {
    const res = await api.get('/auth/mfa/recovery-code');
    return res.data;
  },
  enabled: false // Só dispara manualmente ao clicar no botão/abrir modal
});

// Mutation para inicializar o fluxo (Gera chave secreta e QR Code real)
const { mutate: startMfaSetup, data: setupData, isPending: isStartingSetup } = useMutation({
  mutationFn: async () => {
    const res = await api.get('/auth/mfa/setup');
    return res.data; // retorna { secret, qr_code_base64, qr_code_url }
  },
  onSuccess: () => {
    activeModal.value = 'qrcode';
  },
  onError: (error) => {
    toastStore.send({ message: error.response?.data?.message || 'Erro ao inicializar MFA', style: 'error' });
  }
});

// Mutation para confirmar a ativação do MFA via código do aplicativo
const { mutate: confirmMfaActivation, isPending: isEnablingMfa } = useMutation({
  mutationFn: async () => {
    const res = await api.post('/auth/mfa/enable', { code: mfaCodeInput.value });
    return res.data; // retorna { message, recovery_code }
  },
  onSuccess: (data) => {
    authStore.refetchUser(); // Atualiza o estado global de autenticação do usuário
    setupData.value = null;
    mfaCodeInput.value = '';
    // injeta o código retornado na primeira vez diretamente na estrutura da query local
    queryClient.setQueryData(['mfa-recovery-code'], { recovery_code: data.recovery_code });
    activeModal.value = 'success';
  },
  onError: (error) => {
    toastStore.send({ message: error.response?.data?.message || 'Código inválido', style: 'error' });
  }
});

// Mutation para desativar o MFA definitivamente
const { mutate: deactivateMfa, isPending: isDeactivatingMfa } = useMutation({
  mutationFn: async () => {
    return api.post('/auth/mfa/disable', mfaDeactivateForm.value);
  },
  onSuccess: () => {
    authStore.refetchUser();
    closeModals();
    toastStore.send({ message: 'A autenticação MFA foi desativada.', style: "success" });
  },
  onError: (error) => {
    toastStore.send({ message: error.response?.data?.message || 'Erro ao desativar MFA', style: 'error' });
  }
});

const openRecoveryModal = () => {
  activeModal.value = 'recovery';
  fetchRecoveryCode();
};
</script>

<template>
  <div class="max-w-7xl w-full mx-auto py-3">
    <div class="grid grid-cols-1 lg:grid-cols-2 gap-16">
      <div>
        <h2 class="text-xl font-bold text-slate-800 mb-6">Alterar Senha de Acesso</h2>
        <form @submit.prevent="mutatePassword" class="space-y-5">
          <div>
            <label class="block text-sm font-medium text-slate-700 mb-1">Senha Atual <span
                class="font-bold">*</span></label>
            <div class="relative">
              <span class="absolute inset-y-0 left-0 pl-3 flex items-center text-slate-400">
                <LockIcon class="size-5"></LockIcon>
              </span>
              <input :type="showPasswords.current_password ? 'text' : 'password'" v-model="passForm.current_password"
                class="w-full pl-10 pr-10 py-2 disabled:bg-slate-200 disabled:animate-pulse border border-slate-300 rounded-md focus:outline-none focus:ring-1 focus:ring-slate-800 focus:border-slate-800 text-slate-700 placeholder-slate-400"
                placeholder="Digite sua senha..." required>
              <button type="button" @click="togglePass('current_password')"
                class="cursor-pointer absolute inset-y-0 right-0 pr-3 flex items-center text-slate-400 hover:text-slate-600">
                <EyeIcon v-if="!showPasswords.current_password" class="size-5"></EyeIcon>
                <EyeOffIcon v-else class="size-5"></EyeOffIcon>
              </button>
            </div>
          </div>
          <div>
            <label class="block text-sm font-medium text-slate-700 mb-1">Nova Senha <span
                class="font-bold">*</span></label>
            <div class="relative">
              <span class="absolute inset-y-0 left-0 pl-3 flex items-center text-slate-400">
                <LockIcon class="size-5"></LockIcon>
              </span>
              <input :type="showPasswords.password ? 'text' : 'password'" v-model="passForm.password"
                class="w-full pl-10 pr-10 py-2 disabled:bg-slate-200 disabled:animate-pulse border border-slate-300 rounded-md focus:outline-none focus:ring-1 focus:ring-slate-800 focus:border-slate-800 text-slate-700 placeholder-slate-400"
                placeholder="Crie uma senha segura" required>
              <button type="button" @click="togglePass('password')"
                class="cursor-pointer absolute inset-y-0 right-0 pr-3 flex items-center text-slate-400 hover:text-slate-600">
                <EyeIcon v-if="!showPasswords.password" class="size-5"></EyeIcon>
                <EyeOffIcon v-else class="size-5"></EyeOffIcon>
              </button>
            </div>
          </div>
          <div>
            <label class="block text-sm font-medium text-slate-700 mb-1">Confirmar Nova Senha <span
                class="font-bold">*</span></label>
            <div class="relative">
              <span class="absolute inset-y-0 left-0 pl-3 flex items-center text-slate-400">
                <LockIcon class="size-5"></LockIcon>
              </span>
              <input :type="showPasswords.password_confirmation ? 'text' : 'password'"
                v-model="passForm.password_confirmation"
                class="w-full pl-10 pr-10 py-2 disabled:bg-slate-200 disabled:animate-pulse border border-slate-300 rounded-md focus:outline-none focus:ring-1 focus:ring-slate-800 focus:border-slate-800 text-slate-700 placeholder-slate-400"
                placeholder="Confirme sua nova senha" required>
              <button type="button" @click="togglePass('password_confirmation')"
                class="cursor-pointer absolute inset-y-0 right-0 pr-3 flex items-center text-slate-400 hover:text-slate-600">
                <EyeIcon v-if="!showPasswords.password_confirmation" class="size-5"></EyeIcon>
                <EyeOffIcon v-else class="size-5"></EyeOffIcon>
              </button>
            </div>
          </div>
          <div class="py-2">
            <p class="font-semibold text-slate-800 mb-2">Requisitos de Senha</p>
            <ul class="text-sm text-slate-600 space-y-1">
              <li v-if="passwordRequirements.min8">* Mínimo de 8 caracteres</li>
              <li v-if="passwordRequirements.uppercase">* Pelo menos uma letra maiúscula</li>
              <li v-if="passwordRequirements.number">* Pelo menos um número</li>
              <li v-if="passwordRequirements.symbol">* Pelo menos um símbolo</li>
            </ul>
          </div>
          <div class="flex items-center gap-4 pt-2">
            <button type="submit" :disabled="isChangingPassword"
              class="disabled:bg-primary-muted disabled:text-primary disabled:cursor-not-allowed cursor-pointer rounded-md text-sm font-medium inline-flex items-center justify-center px-6 py-2 bg-primary active:bg-primary-active text-primary-contrast hover:bg-primary-hover transition-all">
              <span v-if="!isChangingPassword">
                Salvar Alterações
              </span>
              <Loader2Icon class="animate-spin" v-else></Loader2Icon>
            </button>
            <button type="button" @click="passForm = { current_password: '', password: '', password_confirmation: '' }"
              :disabled="isChangingPassword"
              class="disabled:bg-slate-200 disabled:cursor-not-allowed cursor-pointer rounded-md text-sm font-medium inline-flex items-center justify-center px-6 py-2 bg-white active:bg-slate-200 border border-slate-500 text-slate-800 hover:bg-slate-100 transition-all">
              Cancelar
            </button>
          </div>
        </form>
      </div>
      <div>
        <h2 class="text-xl font-bold text-slate-800 mb-6">Autenticação Multi-Fator (MFA)</h2>
        <div class="bg-slate-50 p-6 rounded-lg border border-slate-200 space-y-4">
          <div class="flex items-center justify-between">
            <span class="font-semibold text-slate-800">Status do Recurso</span>
            <span
              :class="[authStore.isMfaActive ? 'bg-green-100 text-green-800' : 'bg-amber-100 text-amber-800', 'px-3 py-1 rounded-full text-xs font-medium']">
              {{ authStore.isMfaActive ? 'Ativado' : 'Desativado' }}
            </span>
          </div>
          <div v-if="!authStore.isMfaActive" class="space-y-4 pt-2">
            <p class="text-sm text-slate-600">Adicione uma camada extra de segurança. Sempre que fizer login,
              você precisará informar o token gerado no celular.</p>
            <button @click="activeModal = 'intro'"
              class="disabled:bg-primary-muted disabled:text-primary disabled:cursor-not-allowed cursor-pointer rounded-md text-sm font-medium inline-flex items-center justify-center px-6 py-2 bg-primary active:bg-primary-active text-primary-contrast hover:bg-primary-hover transition-all">
              Configurar MFA
            </button>
          </div>
          <div v-else class="space-y-4 pt-2">
            <p class="text-sm text-slate-600">Sua conta já está assegurada com a autenticação em dois fatores baseada em
              tempo (TOTP).</p>
            <div class="flex flex-wrap items-center gap-4">
              <button @click="activeModal = 'deactivate'"
                class="cursor-pointer px-4 py-2 bg-red-600 hover:bg-red-700 active:bg-red-800 text-white text-sm font-medium rounded-md transition-colors">
                Desativar MFA
              </button>
              <button @click="openRecoveryModal"
                class="cursor-pointer text-sm font-medium text-slate-700 hover:text-slate-800 active:text-slate-900 underline">
                Ver código de recuperação
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
    <Teleport to="body">
      <div v-if="activeModal"
        class="fixed inset-0 bg-black/50 z-50 flex items-center justify-center backdrop-blur-sm px-4">
        <div class="bg-white rounded-xl shadow-xl w-full max-w-md relative p-6 border border-slate-100">

          <button v-if="activeModal !== 'success' && !isEnablingMfa && !isDeactivatingMfa" @click="closeModals"
            class="cursor-pointer absolute top-4 right-4 text-slate-400 hover:text-slate-600">
            <XIcon class="size-5"></XIcon>
          </button>
          <div v-if="activeModal === 'intro'" class="text-center">
            <h3 class="text-xl font-bold text-slate-800 mb-3">Como funciona?</h3>
            <p class="text-sm text-slate-600 mb-6 text-left leading-relaxed">
              Você precisará de um aplicativo como <strong>Google Authenticator</strong> ou <strong>Authy</strong> no
              celular. Vamos exibir um QR Code para você escanear na etapa seguinte.
            </p>
            <button @click="startMfaSetup" :disabled="isStartingSetup"
              class="cursor-pointer w-full inline-flex items-center justify-center disabled:bg-primary-muted disabled:text-primary disabled:cursor-not-allowed rounded-md font-medium px-6 py-2 bg-primary active:bg-primary-active text-primary-contrast hover:bg-primary-hover transition-all">
              <Loader2Icon v-if="isStartingSetup" class="animate-spin mr-2 h-4 w-4" />
              Gerar QR Code
            </button>
          </div>

          <div v-if="activeModal === 'qrcode'" class="text-center">
            <h3 class="text-xl font-bold text-slate-800 mb-2">Escaneie o QR Code</h3>
            <p class="text-xs text-slate-500 mb-4">Abra o aplicativo de autenticação e adicione uma nova conta.</p>

            <div class="flex justify-center mb-4 bg-slate-50 p-4 rounded-lg border border-dashed border-slate-300">
              <img v-if="setupData?.qr_code_base64" :src="setupData.qr_code_base64" alt="MFA QR Code"
                class="w-44 h-44" />
              <div v-else class="w-44 h-44 flex items-center justify-center">
                <Loader2Icon class="animate-spin" />
              </div>
            </div>

            <div class="text-left mb-4">
              <label class="block text-xs font-semibold text-slate-500 uppercase mb-1">Chave secreta alternativa</label>
              <div
                class="flex items-center bg-slate-100 p-2 rounded text-xs text-slate-700 break-all select-all font-mono">
                <span class="flex-1">{{ setupData?.secret }}</span>
              </div>
            </div>

            <input type="text" v-model="mfaCodeInput" max-length="6"
              class="w-full px-3 py-2 border text-center font-mono tracking-widest text-lg border-slate-300 rounded-md mb-4 focus:ring-2 focus:ring-slate-800"
              placeholder="000000" autocomplete="one-time-code" v-maska="'######'">

            <button @click="confirmMfaActivation" :disabled="isEnablingMfa || mfaCodeInput.length < 6"
              class="cursor-pointer w-full inline-flex items-center justify-center disabled:bg-primary-muted disabled:text-primary disabled:cursor-not-allowed rounded-md font-medium px-6 py-2 bg-primary active:bg-primary-active text-primary-contrast hover:bg-primary-hover transition-all">
              <Loader2Icon v-if="isEnablingMfa" class="animate-spin mr-2 h-4 w-4" />
              Confirmar e Ativar
            </button>
          </div>

          <div v-if="activeModal === 'success' || activeModal === 'recovery'" class="text-center">
            <h3 class="text-xl font-bold text-slate-800 mb-2">
              {{ activeModal === 'success' ? 'MFA Ativado com Sucesso!' : 'Seu Código de Recuperação' }}
            </h3>
            <p class="text-sm text-slate-600 mb-6 text-left leading-relaxed">
              Guarde este código em local seguro. Caso perca seu dispositivo, precisará dele para recuperar o acesso à
              plataforma.
            </p>

            <div v-if="isLoadingRecovery" class="py-6 flex justify-center">
              <Loader2Icon class="animate-spin text-slate-800" />
            </div>

            <div v-else
              class="relative flex items-center justify-center text-xl font-bold text-slate-800 tracking-wider mb-6 py-4 bg-slate-50 border border-slate-200 rounded-md font-mono">
              <span>{{ recoveryCodeData?.recovery_code }}</span>
              <button @click="copyToClipboard(recoveryCodeData?.recovery_code)"
                class="cursor-pointer absolute right-3 text-slate-400 hover:text-slate-600">
                <CheckIcon v-if="copiedStatus" class="h-5 w-5 text-green-600" />
                <CopyIcon v-else class="h-5 w-5" />
              </button>
            </div>

            <button @click="closeModals"
              class="cursor-pointer w-full inline-flex items-center justify-center disabled:bg-primary-muted disabled:text-primary disabled:cursor-not-allowed rounded-md font-medium px-6 py-2 bg-primary active:bg-primary-active text-primary-contrast hover:bg-primary-hover transition-all">
              Fechar Janela
            </button>
          </div>

          <div v-if="activeModal === 'deactivate'" class="text-center">
            <h3 class="text-xl font-bold text-slate-800 mb-2">Desativar Proteção MFA</h3>
            <p class="text-sm text-slate-500 mb-4">Confirme sua senha e o token atual para revogar o acesso.</p>

            <div class="space-y-3 text-left mb-6">
              <div>
                <label class="block text-xs font-medium text-slate-600 mb-1">Sua Senha Atual</label>
                <input type="password" v-model="mfaDeactivateForm.password"
                  class="w-full px-3 py-2 border border-slate-300 rounded-md focus:ring-1 focus:ring-slate-800"
                  placeholder="••••••••">
              </div>
              <div>
                <label class="block text-xs font-medium text-slate-600 mb-1">Código de 6 dígitos do Token</label>
                <input type="text" v-model="mfaDeactivateForm.code" maxlength="6"
                  class="w-full px-3 py-2 border border-slate-300 rounded-md focus:ring-1 focus:ring-slate-800 text-center font-mono"
                  placeholder="000000" autocomplete="one-time-code" v-maska="'######'">
              </div>
            </div>

            <div class="flex gap-3">
              <button @click="deactivateMfa"
                :disabled="isDeactivatingMfa || !mfaDeactivateForm.password || mfaDeactivateForm.code.length < 6"
                class="cursor-pointer disabled:cursor-not-allowed disabled:bg-red-300 flex-1 inline-flex items-center justify-center px-4 py-2 bg-red-600 text-white rounded-md text-sm font-medium hover:bg-red-700">
                <Loader2Icon v-if="isDeactivatingMfa" class="animate-spin mr-2 h-4 w-4" />
                Confirmar Remoção
              </button>
              <button @click="closeModals" :disabled="isDeactivatingMfa"
                class="flex-1 disabled:bg-slate-200 disabled:cursor-not-allowed cursor-pointer rounded-md text-sm font-medium inline-flex items-center justify-center px-6 py-2 bg-white active:bg-slate-200 border border-slate-500 text-slate-800 hover:bg-slate-100 transition-all">Cancelar</button>
            </div>
          </div>

        </div>
      </div>
    </Teleport>
  </div>
</template>