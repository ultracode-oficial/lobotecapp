<script setup lang="ts">
import { reactive, watch, computed, ref } from 'vue';
import { vMaska } from 'maska/vue';
import { passwordRequirements } from '@/services/featureFlags';
import { EyeIcon, EyeOffIcon, Loader2Icon, LockIcon } from '@lucide/vue';

const props = defineProps<{
  initialData?: any;
  isLoading?: boolean;
  roleOptions?: { permissions: { id: number, name: string }[], roles: { id: number, name: string }[]; }
  especializacaoOptions?: { especializacoes: { id: number, name: string }[] }
  errors?: Record<string, string[]>;
}>();

const emit = defineEmits(['submit', 'cancel']);

const showPasswords = ref({ password: false, password_confirmation: false });
const togglePass = (field: 'password' | 'password_confirmation') => {
  showPasswords.value[field] = !showPasswords.value[field];
};

// Estado local do formulário
const form = reactive({
  name: '',
  email: '',
  cpf: '',
  phone: '',
  password: '',
  password_confirmation: '',
  roles: [] as string[],
  permissions: [] as string[],
  especializacoes: [] as number[],
  change_password_required: false,
  mfa_required: false,
  vendedor_tipo: 'PORCENTAGEM',
  vendedor_porcentagem_display: '',
  vendedor_valor_display: '',
});

// Preenche o formulário se vier dados (Modo Edição)
watch(() => props.initialData, (data) => {
  if (data) {
    form.name = data.name || '';
    form.email = data.email || '';
    form.cpf = data.cpf || '';
    form.phone = data.phone || '';
    form.roles = data.roles || [];
    form.permissions = data.permissions || [];
    form.especializacoes = data.especializacoes?.map((e: any) => e.id) || [];
    form.change_password_required = data.change_password_required ?? false;
    form.mfa_required = data.mfa_required ?? false;

    if (data.vendedor_config) {
      form.vendedor_tipo = data.vendedor_config.tipo_comissao;
      form.vendedor_porcentagem_display = data.vendedor_config.porcentagem_comissao;
      form.vendedor_valor_display = `${(data.vendedor_config.valor_fixo_comissao_centavos / 100).toFixed(2)}`;
    }
  }
}, { immediate: true });

const isVendedor = computed(() => form.roles.some(r => ["VENDEDOR", "REPRESENTANTE"].includes(r)));
const isTecnico = computed(() => form.roles.includes("TÉCNICO"));
const userHasEspecializacoes = computed(() => form.especializacoes.length > 0);

function handleSubmit() {
  // Monta o payload preparando os dados para a API
  const payload: any = {
    name: form.name,
    email: form.email,
    cpf: form.cpf,
    phone: form.phone,
    roles: form.roles,
    permissions: form.permissions,
    especializacoes: form.especializacoes,
    change_password_required: form.change_password_required,
    mfa_required: form.mfa_required,
  };

  // Só envia senha se foi preenchida
  if (form.password) {
    payload.password = form.password;
    payload.password_confirmation = form.password_confirmation;
  }

  // Lógica do VendedorConfig
  if (isVendedor.value) {
    const porcentagemRaw = form.vendedor_porcentagem_display?.toString().replace(',', '.') || '0';
    const porcentagemDecimal = parseFloat(porcentagemRaw);

    payload.vendedor_config = {
      tipo_comissao: form.vendedor_tipo,

      porcentagem_comissao: form.vendedor_tipo === 'PORCENTAGEM'
        ? Number(porcentagemDecimal.toFixed(2)) // Garante no máximo 2 casas decimais
        : 0,

      valor_fixo_comissao_centavos: form.vendedor_tipo === 'VALOR_FIXO'
        ? Math.round(parseFloat(form.vendedor_valor_display?.toString().replace(',', '.') || '0') * 100)
        : 0,
    };
  }

  emit('submit', payload);
}
</script>

<template>
  <form @submit.prevent="handleSubmit" class="space-y-8">
    <div class="space-y-5">
      <!-- Informações Pessoais -->
      <div>
        <div class="mb-5">
          <h3 class="text-lg font-medium leading-6 text-slate-900">Informações Pessoais</h3>
          <p class="mt-1 text-sm text-slate-500">Dados básicos de identificação e contato do usuário.</p>
        </div>
        <div class="grid grid-cols-1 gap-y-6 gap-x-4 sm:grid-cols-6">
          <div class="sm:col-span-3">
            <label class="block text-sm font-medium text-slate-700 mb-1">Nome Completo <span
                class="font-bold">*</span></label>
            <input v-model="form.name" type="text" required placeholder="Titular da Conta"
              class="disabled:bg-slate-200 disabled:animate-pulse w-full px-3 py-2 border border-slate-300 rounded-md focus:outline-none focus:ring-1 focus:ring-slate-800 focus:border-slate-800 text-slate-700 placeholder-slate-400" />
            <p v-if="errors?.name" class="mt-1 text-sm text-red-600">{{ errors.name[0] }}</p>
          </div>
          <div class="sm:col-span-3">
            <label class="block text-sm font-medium text-slate-700 mb-1">CPF <span class="font-bold">*</span></label>
            <input v-model="form.cpf" type="text" v-maska="'###.###.###-##'" placeholder="000.000.000-00" minlength="14"
              maxlength="14" required
              class="disabled:bg-slate-200 disabled:animate-pulse w-full px-3 py-2 border border-slate-300 rounded-md focus:outline-none focus:ring-1 focus:ring-slate-800 focus:border-slate-800 text-slate-700 placeholder-slate-400" />
            <p v-if="errors?.cpf" class="mt-1 text-sm text-red-600">{{ errors.cpf[0] }}</p>
          </div>
          <div class="sm:col-span-3">
            <label class="block text-sm font-medium text-slate-700 mb-1">E-mail <span class="font-bold">*</span></label>
            <input v-model="form.email" type="email" required placeholder="exemplo@email.com"
              class="disabled:bg-slate-200 disabled:animate-pulse w-full px-3 py-2 border border-slate-300 rounded-md focus:outline-none focus:ring-1 focus:ring-slate-800 focus:border-slate-800 text-slate-700 placeholder-slate-400" />
            <p v-if="errors?.email" class="mt-1 text-sm text-red-600">{{ errors.email[0] }}</p>
          </div>
          <div class="sm:col-span-3">
            <label class="block text-sm font-medium text-slate-700 mb-1">Telefone</label>
            <input v-model="form.phone" type="text" v-maska data-maska="['(##)####-####','(##)#####-####']"
              minlength="13" maxlength="14" placeholder="(00) 00000-0000"
              class="disabled:bg-slate-200 disabled:animate-pulse w-full px-3 py-2 border border-slate-300 rounded-md focus:outline-none focus:ring-1 focus:ring-slate-800 focus:border-slate-800 text-slate-700 placeholder-slate-400" />
          </div>
        </div>
      </div>
      <!-- Perfis e Especializações -->
      <div class="pt-8 flex flex-col gap-6">
        <div class="grid grid-cols-1 sm:grid-cols-2 gap-y-6 gap-x-4">
          <div>
            <h3 class="text-lg font-medium leading-6 text-slate-900">Perfis de Acesso</h3>
            <div class="mt-4 space-y-4">
              <div v-for="role in roleOptions?.roles" :key="role.name" class="flex items-start">
                <div class="flex h-5 items-center">
                  <input :id="role.name" v-model="form.roles" :value="role.name" type="checkbox"
                    class="h-4 w-4 rounded border-slate-300 text-indigo-600 focus:ring-indigo-500" />
                </div>
                <div class="ml-3 text-sm">
                  <label :for="role.name" class="font-medium text-slate-700">{{ role.name }}</label>
                </div>
              </div>
            </div>
            <p v-if="errors?.roles" class="mt-2 text-sm text-red-600">{{ errors.roles[0] }}</p>
          </div>
          <!-- Condicional: Configuração de Vendedor -->
          <div v-if="isVendedor">
            <div class="mb-5">
              <h3 class="text-lg font-medium leading-6 text-slate-900">Configurações do Vendedor</h3>
              <p class="mt-1 text-sm text-slate-500">Defina o modelo de comissionamento deste vendedor.</p>
            </div>
            <div class="grid grid-cols-1 sm:grid-cols-2 gap-y-6 gap-x-4">
              <div>
                <label class="block text-sm font-medium text-slate-700 mb-1">Tipo de Comissão</label>
                <select v-model="form.vendedor_tipo"
                  class="disabled:bg-slate-200 disabled:animate-pulse w-full px-3 py-2 border border-slate-300 rounded-md focus:outline-none focus:ring-1 focus:ring-slate-800 focus:border-slate-800 text-slate-700 placeholder-slate-400">
                  <option value="PORCENTAGEM">Porcentagem (%)</option>
                  <option value="VALOR_FIXO">Valor Fixo (R$)</option>
                </select>
              </div>
              <div v-if="form.vendedor_tipo === 'PORCENTAGEM'">
                <label class="block text-sm font-medium text-slate-700 mb-1">Porcentagem (%)</label>
                <input v-model.number="form.vendedor_porcentagem_display" type="number" step="0.01"
                  class="disabled:bg-slate-200 disabled:animate-pulse w-full px-3 py-2 border border-slate-300 rounded-md focus:outline-none focus:ring-1 focus:ring-slate-800 focus:border-slate-800 text-slate-700 placeholder-slate-400"
                  placeholder="Ex: 12.5" />
              </div>
              <div v-if="form.vendedor_tipo === 'VALOR_FIXO'">
                <label class="block text-sm font-medium text-slate-700 mb-1">Valor Fixo (R$)</label>
                <input v-model="form.vendedor_valor_display" type="text"
                  class="disabled:bg-slate-200 disabled:animate-pulse w-full px-3 py-2 border border-slate-300 rounded-md focus:outline-none focus:ring-1 focus:ring-slate-800 focus:border-slate-800 text-slate-700 placeholder-slate-400"
                  v-maska :data-maska="0.99" data-maska-tokens="0:\d:multiple|9:\d:optional"
                  placeholder="Ex.: 150.00" />
              </div>
            </div>
          </div>
        </div>
        <!-- Condicional: Especializações do Técnico -->
        <div class="sm:col-span-6" v-if="isTecnico || userHasEspecializacoes">
          <div class="mb-5">
            <h3 class="text-lg font-medium leading-6 text-slate-900">Especializações</h3>
            <p class="mt-1 text-sm text-slate-500">Indique as especializações deste técnico.</p>
          </div>
          <div class="mt-4 space-y-4 grid grid-cols-1 sm:grid-cols-2 md:grid-cols-4">
            <div v-for="esp in especializacaoOptions?.especializacoes" :key="esp.id" class="flex items-start">
              <div class="flex h-5 items-center">
                <input :id="`espec-${esp.id}`" v-model="form.especializacoes" :value="esp.id" type="checkbox"
                  class="h-4 w-4 rounded border-slate-300 text-indigo-600 focus:ring-indigo-500" />
              </div>
              <div class="ml-3 text-sm">
                <label :for="`espec-${esp.id}`" class="font-medium text-slate-700">{{ esp.name }}</label>
              </div>
            </div>
          </div>
        </div>
        <!-- Permissões Diretas -->
        <div class="sm:col-span-6">
          <div class="mb-5">
            <h3 class="text-lg font-medium leading-6 text-slate-900">Permissões Diretas</h3>
            <p class="mt-1 text-sm text-slate-500">Permissões adicionais concedidas ao usuário, somando-se aos
              privilégios já definidos pelo seu perfil de acesso.</p>
          </div>
          <div class="mt-4 space-y-4 grid grid-cols-1 sm:grid-cols-2 md:grid-cols-4">
            <div v-for="permission in roleOptions?.permissions" :key="permission.name" class="flex items-start">
              <div class="flex h-5 items-center">
                <input :id="permission.name" v-model="form.permissions" :value="permission.name" type="checkbox"
                  class="h-4 w-4 rounded border-slate-300 text-indigo-600 focus:ring-indigo-500" />
              </div>
              <div class="ml-3 text-sm">
                <label :for="permission.name" class="font-medium text-slate-700">{{ permission.name }}</label>
              </div>
            </div>
          </div>
          <p v-if="errors?.permissions" class="mt-2 text-sm text-red-600">{{ errors.permissions[0] }}</p>
        </div>
      </div>
      <!-- Segurança e Acesso -->
      <div class="pt-8">
        <div>
          <h3 class="text-lg font-medium leading-6 text-slate-900">Segurança e Acesso</h3>
          <p v-if="initialData" class="mt-1 text-sm text-slate-500">Deixe os campos de senha em branco se não quiser
            alterar a senha atual do usuário.</p>
        </div>
        <div class="mt-6 grid grid-cols-1 gap-y-6 gap-x-4 sm:grid-cols-6">
          <div class="flex flex-col gap-x-4 gap-y-6 sm:col-span-3">
            <div>
              <label class="block text-sm font-medium text-slate-700 mb-1">Senha <span class="font-bold"
                  v-if="!initialData">*</span></label>
              <div class="relative">
                <span class="absolute inset-y-0 left-0 pl-3 flex items-center text-slate-400">
                  <LockIcon class="size-5"></LockIcon>
                </span>
                <input :required="!initialData" :type="showPasswords.password ? 'text' : 'password'"
                  v-model="form.password" autocomplete="new-password"
                  class="w-full pl-10 pr-10 py-2 border border-slate-300 rounded-md focus:outline-none focus:ring-1 focus:ring-slate-800 focus:border-slate-800 text-slate-700"
                  placeholder="Crie uma senha segura">
                <button type="button" @click="togglePass('password')"
                  class="cursor-pointer absolute inset-y-0 right-0 pr-3 flex items-center text-slate-400 hover:text-slate-600">
                  <EyeIcon v-if="!showPasswords.password" class="size-5"></EyeIcon>
                  <EyeOffIcon v-else class="size-5"></EyeOffIcon>
                </button>
              </div>
              <p v-if="errors?.password" class="mt-1 text-sm text-red-600">{{ errors.password[0] }}</p>
            </div>
            <div>
              <label class="block text-sm font-medium text-slate-700 mb-1">Confirmar Senha <span class="font-bold"
                  v-if="!initialData">*</span></label>
              <div class="relative">
                <span class="absolute inset-y-0 left-0 pl-3 flex items-center text-slate-400">
                  <LockIcon class="size-5"></LockIcon>
                </span>
                <input :required="!initialData" :type="showPasswords.password_confirmation ? 'text' : 'password'"
                  v-model="form.password_confirmation" autocomplete="new-password"
                  class="w-full pl-10 pr-10 py-2 border border-slate-300 rounded-md focus:outline-none focus:ring-1 focus:ring-slate-800 focus:border-slate-800 text-slate-700"
                  placeholder="Confirme sua nova senha">
                <button type="button" @click="togglePass('password_confirmation')"
                  class="cursor-pointer absolute inset-y-0 right-0 pr-3 flex items-center text-slate-400 hover:text-slate-600">
                  <EyeIcon v-if="!showPasswords.password_confirmation" class="size-5"></EyeIcon>
                  <EyeOffIcon v-else class="size-5"></EyeOffIcon>
                </button>
              </div>
            </div>
          </div>
          <div class="sm:col-span-3 sm:ml-6">
            <p class="font-semibold text-slate-800 mb-2">Requisitos de Senha</p>
            <ul class="text-sm text-slate-600 space-y-1">
              <li v-if="passwordRequirements.min8">* Mínimo de 8 caracteres</li>
              <li v-if="passwordRequirements.uppercase">* Pelo menos uma letra maiúscula</li>
              <li v-if="passwordRequirements.number">* Pelo menos um número</li>
              <li v-if="passwordRequirements.symbol">* Pelo menos um símbolo</li>
            </ul>
          </div>
          <!-- Checkboxes de Exigência -->
          <div class="sm:col-span-6 mt-4 space-y-4">
            <div class="flex items-start">
              <div class="flex h-5 items-center">
                <input v-model="form.change_password_required" id="change_password" type="checkbox"
                  class="h-4 w-4 rounded border-slate-300 text-indigo-600 focus:ring-indigo-500" />
              </div>
              <div class="ml-3 text-sm">
                <label for="change_password" class="font-medium text-slate-700">Exigir troca de senha</label>
                <p class="text-slate-500">O usuário será forçado a alterar sua senha no próximo acesso à plataforma.</p>
                <p v-if="errors?.change_password_required" class="mt-1 text-sm text-red-600">{{
                  errors.change_password_required[0] }}</p>
              </div>
            </div>
            <div class="flex items-start">
              <div class="flex h-5 items-center">
                <input v-model="form.mfa_required" id="mfa_required" type="checkbox"
                  class="h-4 w-4 rounded border-slate-300 text-indigo-600 focus:ring-indigo-500" />
              </div>
              <div class="ml-3 text-sm">
                <label for="mfa_required" class="font-medium text-slate-700">Exigir Autenticação em Duas Etapas
                  (MFA)</label>
                <p class="text-slate-500">O usuário será obrigado a configurar um aplicativo autenticador antes de
                  prosseguir.</p>
                <p v-if="errors?.mfa_required" class="mt-1 text-sm text-red-600">{{ errors.mfa_required[0] }}</p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    <!-- Actions -->
    <div class="pt-5">
      <div class="flex justify-end gap-3">
        <button type="button" @click="emit('cancel')"
          class="disabled:bg-slate-200 disabled:cursor-not-allowed cursor-pointer rounded-md text-sm font-medium inline-flex items-center justify-center px-6 py-2 bg-white active:bg-slate-200 border border-slate-500 text-slate-800 hover:bg-slate-100 transition-all">
          Cancelar
        </button>
        <button type="submit" :disabled="isLoading"
          class="inline-flex items-center justify-center text-sm disabled:bg-primary-muted disabled:text-primary disabled:cursor-not-allowed rounded-md font-medium cursor-pointer px-6 py-2 bg-primary active:bg-primary-active text-primary-contrast hover:bg-primary-hover transition-all">
          <Loader2Icon v-if="isLoading" class="animate-spin -ml-1 mr-2 size-4 text-white"></Loader2Icon>
          Salvar
        </button>
      </div>
    </div>
  </form>
</template>