<script setup lang="ts">
import { reactive, watch, computed, ref } from 'vue';
import { vMaska } from 'maska/vue';
import { Loader2Icon } from '@lucide/vue';
import { estadosOptions } from '@/services/estados';

const props = defineProps<{
  initialData?: any;
  isLoading?: boolean;
  tipoEquipamentosOptions?: { id: number, name: string }[];
  vendedoresOptions?: { id: number, name: string, roles: string[] }[];
  errors?: Record<string, string[]>;
}>();

const emit = defineEmits(['submit', 'cancel']);

// Estado local do formulário
const form = reactive({
  razao_social: '',
  nome_fantasia: '',
  cnpj: '',
  observacoes: '',
  email: '',
  phone: '',
  nome_representante: '',
  cep: '',
  logradouro: '',
  numero_logradouro: '',
  complemento: '',
  bairro: '',
  municipio: '',
  uf: '',
  vendedor_id: '',
  equipamentos: {
    ...props.tipoEquipamentosOptions?.reduce<Record<number, string>>((acc, o) => {
      acc[o.id] = '';
      return acc;
    }, {})
  },
});

const cepInicial = ref('');
// Preenche o formulário se vier dados (Modo Edição)
watch(() => props.initialData, (data) => {
  if (data) {
    if (data?.cep) {
      cepInicial.value = data.cep.replace(/\D/g, '');
    }
    form.razao_social = data.razao_social || '';
    form.nome_fantasia = data.nome_fantasia || '';
    form.cnpj = data.cnpj || '';
    form.observacoes = data.observacoes || '';
    form.email = data.email || '';
    form.phone = data.phone || '';
    form.nome_representante = data.nome_representante || '';
    form.cep = data.cep || '';
    form.logradouro = data.logradouro || '';
    form.numero_logradouro = data.numero_logradouro || '';
    form.complemento = data.complemento || '';
    form.bairro = data.bairro || '';
    form.municipio = data.municipio || '';
    form.uf = data.uf || '';
    form.vendedor_id = data.vendedor_id || '';

    const defaultEquips = data.equipamentos.reduce((acc: Record<number, number>, o: { id: number, tipo_equipamento_id: number, is_generic: boolean }) => {
      if (o.is_generic) {
        if (Object.hasOwn(acc, o.tipo_equipamento_id)) {
          acc[o.tipo_equipamento_id]! += 1;
        } else {
          acc[o.tipo_equipamento_id] = 1;
        }
      }
      return acc;
    }, {});

    form.equipamentos = {
      ...form.equipamentos,
      ...defaultEquips
    }
  }
}, { immediate: true });

watch(() => form.cep, async (novoCep) => {
  const cepLimpo = novoCep ? novoCep.replace(/\D/g, '') : '';
  if (cepLimpo.length !== 8) return;
  if (cepLimpo === cepInicial.value) return;

  try {
    const response = await fetch(`https://viacep.com.br/ws/${cepLimpo}/json/`);
    const data = await response.json();

    if (!data.erro) {
      form.logradouro = data.logradouro || '';
      form.bairro = data.bairro || '';
      form.municipio = data.localidade || '';
      form.uf = data.uf || '';
    }
  } catch (error) {
    console.error("Erro ao buscar o CEP:", error);
  }
});

function handleSubmit() {
  const payload: any = {
    razao_social: form.razao_social,
    nome_fantasia: form.nome_fantasia,
    cnpj: form.cnpj,
    observacoes: form.observacoes,
    email: form.email,
    phone: form.phone,
    nome_representante: form.nome_representante,
    cep: form.cep,
    logradouro: form.logradouro,
    numero_logradouro: form.numero_logradouro,
    complemento: form.complemento,
    bairro: form.bairro,
    municipio: form.municipio,
    uf: form.uf,
    vendedor_id: form.vendedor_id,
    equipamentos: form.equipamentos
  };

  emit('submit', payload);
}
</script>

<template>
  <form @submit.prevent="handleSubmit" class="space-y-8">
    <div class="space-y-5">
      <!-- Informações Pessoais -->
      <div>
        <div class="mb-5">
          <h3 class="text-lg font-medium leading-6 text-slate-900">Informações do Cliente</h3>
          <p class="mt-1 text-sm text-slate-500">Dados básicos de identificação.</p>
        </div>
        <div class="grid grid-cols-1 gap-y-6 gap-x-4 sm:grid-cols-6">
          <div class="sm:col-span-2">
            <label class="block text-sm font-medium text-slate-700 mb-1">Razão Social <span
                class="font-bold">*</span></label>
            <input v-model="form.razao_social" type="text" required placeholder="Razão Social do Cliente"
              class="disabled:bg-slate-200 disabled:animate-pulse w-full px-3 py-2 border border-slate-300 rounded-md focus:outline-none focus:ring-1 focus:ring-slate-800 focus:border-slate-800 text-slate-700 placeholder-slate-400" />
            <p v-if="errors?.razao_social" class="mt-1 text-sm text-red-600">{{ errors.razao_social[0] }}</p>
          </div>
          <div class="sm:col-span-2">
            <label class="block text-sm font-medium text-slate-700 mb-1">Nome Fantasia</label>
            <input v-model="form.nome_fantasia" type="text" placeholder="Nome Fantasia do Cliente"
              class="disabled:bg-slate-200 disabled:animate-pulse w-full px-3 py-2 border border-slate-300 rounded-md focus:outline-none focus:ring-1 focus:ring-slate-800 focus:border-slate-800 text-slate-700 placeholder-slate-400" />
            <p v-if="errors?.nome_fantasia" class="mt-1 text-sm text-red-600">{{ errors.nome_fantasia[0] }}</p>
          </div>
          <div class="sm:col-span-2">
            <label class="block text-sm font-medium text-slate-700 mb-1">CNPJ <span class="font-bold">*</span></label>
            <input v-model="form.cnpj" type="text" v-maska="'**.***.***/****-**'" placeholder="00.000.000/0000-00"
              minlength="18" maxlength="18" required
              class="disabled:bg-slate-200 disabled:animate-pulse w-full px-3 py-2 border border-slate-300 rounded-md focus:outline-none focus:ring-1 focus:ring-slate-800 focus:border-slate-800 text-slate-700 placeholder-slate-400" />
            <p v-if="errors?.cnpj" class="mt-1 text-sm text-red-600">{{ errors.cnpj[0] }}</p>
          </div>
          <div class="sm:col-span-6">
            <label class="block text-sm font-medium text-slate-700 mb-1">Observações</label>
            <textarea v-model="form.observacoes" rows="3"
              placeholder="Ex.: Perfil comercial, preferências, restrições de atendimento..."
              class="resize-none disabled:bg-slate-200 disabled:animate-pulse w-full px-3 py-2 border border-slate-300 rounded-md focus:outline-none focus:ring-1 focus:ring-slate-800 focus:border-slate-800 text-slate-700 placeholder-slate-400"></textarea>
          </div>
        </div>
      </div>
      <!-- Contato -->
      <div class="pt-8">
        <div class="mb-5">
          <h3 class="text-lg font-medium leading-6 text-slate-900">Contato Comercial</h3>
          <p class="mt-1 text-sm text-slate-500">Contato dos responsáveis pela aprovação de orçamentos e agendamentos.
          </p>
        </div>
        <div class="grid grid-cols-1 gap-y-6 gap-x-4 sm:grid-cols-6">
          <div class="sm:col-span-2">
            <label class="block text-sm font-medium text-slate-700 mb-1">E-mail</label>
            <input v-model="form.email" type="email" placeholder="exemplo@email.com"
              class="disabled:bg-slate-200 disabled:animate-pulse w-full px-3 py-2 border border-slate-300 rounded-md focus:outline-none focus:ring-1 focus:ring-slate-800 focus:border-slate-800 text-slate-700 placeholder-slate-400" />
            <p v-if="errors?.email" class="mt-1 text-sm text-red-600">{{ errors.email[0] }}</p>
          </div>
          <div class="sm:col-span-2">
            <label class="block text-sm font-medium text-slate-700 mb-1">Telefone</label>
            <input v-model="form.phone" type="text" v-maska data-maska="['(##)####-####','(##)#####-####']"
              minlength="13" maxlength="14" placeholder="(00) 00000-0000"
              class="disabled:bg-slate-200 disabled:animate-pulse w-full px-3 py-2 border border-slate-300 rounded-md focus:outline-none focus:ring-1 focus:ring-slate-800 focus:border-slate-800 text-slate-700 placeholder-slate-400" />
          </div>
          <div class="sm:col-span-2">
            <label class="block text-sm font-medium text-slate-700 mb-1">Representante</label>
            <input v-model="form.nome_representante" type="text" placeholder="Nome para Contato"
              class="disabled:bg-slate-200 disabled:animate-pulse w-full px-3 py-2 border border-slate-300 rounded-md focus:outline-none focus:ring-1 focus:ring-slate-800 focus:border-slate-800 text-slate-700 placeholder-slate-400" />
            <p v-if="errors?.nome_representante" class="mt-1 text-sm text-red-600">{{ errors.nome_representante[0] }}
            </p>
          </div>
        </div>
      </div>
      <!-- Endereço -->
      <div class="pt-8">
        <div class="mb-5">
          <h3 class="text-lg font-medium leading-6 text-slate-900">Dados de Localização</h3>
          <p class="mt-1 text-sm text-slate-500">Informe o endereço exato onde os serviços de manutenção serão
            efetuados.</p>
        </div>
        <div class="grid grid-cols-1 gap-y-6 gap-x-4 sm:grid-cols-6">
          <div class="sm:col-span-6">
            <label class="block text-sm font-medium text-slate-700 mb-1">CEP</label>
            <input v-model="form.cep" type="text" placeholder="00000-000" v-maska="'#####-###'"
              class="disabled:bg-slate-200 disabled:animate-pulse px-3 py-2 border border-slate-300 rounded-md focus:outline-none focus:ring-1 focus:ring-slate-800 focus:border-slate-800 text-slate-700 placeholder-slate-400" />
            <p v-if="errors?.cep" class="mt-1 text-sm text-red-600">{{ errors.cep[0] }}</p>
          </div>
          <div class="sm:col-span-2">
            <label class="block text-sm font-medium text-slate-700 mb-1">Logradouro</label>
            <input v-model="form.logradouro" type="text" placeholder="Ex.: Rua das Flores"
              class="disabled:bg-slate-200 disabled:animate-pulse w-full px-3 py-2 border border-slate-300 rounded-md focus:outline-none focus:ring-1 focus:ring-slate-800 focus:border-slate-800 text-slate-700 placeholder-slate-400" />
          </div>
          <div class="sm:col-span-2">
            <label class="block text-sm font-medium text-slate-700 mb-1">Número</label>
            <input v-model="form.numero_logradouro" type="text" placeholder="Ex.: 123"
              class="disabled:bg-slate-200 disabled:animate-pulse w-full px-3 py-2 border border-slate-300 rounded-md focus:outline-none focus:ring-1 focus:ring-slate-800 focus:border-slate-800 text-slate-700 placeholder-slate-400" />
          </div>
          <div class="sm:col-span-2">
            <label class="block text-sm font-medium text-slate-700 mb-1">Complemento</label>
            <input v-model="form.complemento" type="text" placeholder="Ex.: Apt 42, Bloco B"
              class="disabled:bg-slate-200 disabled:animate-pulse w-full px-3 py-2 border border-slate-300 rounded-md focus:outline-none focus:ring-1 focus:ring-slate-800 focus:border-slate-800 text-slate-700 placeholder-slate-400" />
          </div>
          <div class="sm:col-span-2">
            <label class="block text-sm font-medium text-slate-700 mb-1">Bairro</label>
            <input v-model="form.bairro" type="text" placeholder="Ex.: Jardim América"
              class="disabled:bg-slate-200 disabled:animate-pulse w-full px-3 py-2 border border-slate-300 rounded-md focus:outline-none focus:ring-1 focus:ring-slate-800 focus:border-slate-800 text-slate-700 placeholder-slate-400" />
          </div>
          <div class="sm:col-span-2">
            <label class="block text-sm font-medium text-slate-700 mb-1">Cidade</label>
            <input v-model="form.municipio" type="text" placeholder="Ex.: Nova Iguaçu"
              class="disabled:bg-slate-200 disabled:animate-pulse w-full px-3 py-2 border border-slate-300 rounded-md focus:outline-none focus:ring-1 focus:ring-slate-800 focus:border-slate-800 text-slate-700 placeholder-slate-400" />
          </div>
          <div class="sm:col-span-2">
            <label class="block text-sm font-medium text-slate-700 mb-1">Estado</label>
            <select v-model="form.uf"
              class="disabled:bg-slate-200 disabled:animate-pulse w-full px-3 py-2 border border-slate-300 rounded-md focus:outline-none focus:ring-1 focus:ring-slate-800 focus:border-slate-800 text-slate-700 placeholder-slate-400">
              <option value="">Selecione</option>
              <option :key="estado.uf" v-for="estado in estadosOptions" :value="estado.uf">{{ estado.nome }} ({{
                estado.uf }})</option>
            </select>
          </div>
        </div>
      </div>
      <!-- Equipamentos do Cliente -->
      <div class="pt-8">
        <div class="mb-5">
          <h3 class="text-lg font-medium leading-6 text-slate-900">Equipamentos do Cliente (Genéricos)</h3>
          <p class="mt-1 text-sm text-slate-500">Informe a quantidade de equipamentos genéricos do cliente por tipo.</p>
        </div>
        <div class="grid grid-cols-1 gap-y-6 gap-x-4 sm:grid-cols-6"
          v-if="tipoEquipamentosOptions && form.equipamentos">
          <div class="sm:col-span-1" v-for="tipoEquipamento in tipoEquipamentosOptions" :key="tipoEquipamento.id">
            <label class="block text-sm font-medium text-slate-700 mb-1">{{ tipoEquipamento.name }}</label>
            <input v-model="form.equipamentos[tipoEquipamento.id]" type="number" placeholder="Ex.: 10" min="0"
              class="disabled:bg-slate-200 disabled:animate-pulse w-full px-3 py-2 border border-slate-300 rounded-md focus:outline-none focus:ring-1 focus:ring-slate-800 focus:border-slate-800 text-slate-700 placeholder-slate-400" />
          </div>
        </div>
      </div>
      <!-- Vendedor Responsável -->
      <div class="pt-8" v-can="'GERIR_CLIENTES'">
        <div class="mb-5">
          <h3 class="text-lg font-medium leading-6 text-slate-900">Relacionamento com o Cliente</h3>
          <p class="mt-1 text-sm text-slate-500">Indique o vendedor ou representante responsável por este cliente.</p>
        </div>
        <div class="grid grid-cols-1 gap-y-6 gap-x-4 sm:grid-cols-6" v-if="vendedoresOptions">
          <div class="sm:col-span-3">
            <label class="block text-sm font-medium text-slate-700 mb-1">Responsável</label>
            <select v-model="form.vendedor_id"
              class="disabled:bg-slate-200 disabled:animate-pulse w-full px-3 py-2 border border-slate-300 rounded-md focus:outline-none focus:ring-1 focus:ring-slate-800 focus:border-slate-800 text-slate-700 placeholder-slate-400">
              <option value="">Selecione o vendedor ou representante</option>
              <option v-for="vendedor in vendedoresOptions" :key="vendedor.id" :value="vendedor.id">{{
                vendedor.name }} ({{ vendedor.roles.join(', ') }})</option>
            </select>
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