<script setup>
import { useRoute } from 'vue-router';
import { ref, nextTick } from 'vue';
import bannerLogo from "@/assets/banner-color-horizontal.png";
import iconLogo from "@/assets/logo-square.png";
import { BookMarkedIcon, CalendarDaysIcon, ChartColumn, ChevronDownIcon, ContactIcon, HandshakeIcon, HomeIcon, LandmarkIcon, PackageIcon, ScrollTextIcon, Settings2Icon } from '@lucide/vue';

const props = defineProps({
  isExpanded: {
    type: Boolean,
    required: true
  }
});

const route = useRoute();

const openDropdowns = ref({
  relatorios: false,
  configuracoes: false
});

const dropdownClasses = ref({
  relatorios: 'top-1/2 -translate-y-1/2',
  configuracoes: 'top-1/2 -translate-y-1/2'
});

const toggleDropdown = async (key) => {
  openDropdowns.value[key] = !openDropdowns.value[key];

  if (!props.isExpanded && openDropdowns.value[key]) {
    dropdownClasses.value[key] = 'top-1/2 -translate-y-1/2';
    await nextTick();
    const dropdownEl = document.getElementById(`dropdown-${key}`);

    if (dropdownEl) {
      const rect = dropdownEl.getBoundingClientRect();
      const windowHeight = window.innerHeight;
      const safeMargin = 16;

      if (rect.bottom > windowHeight - safeMargin) {
        dropdownClasses.value[key] = 'bottom-0 translate-y-0';
      } else if (rect.top < safeMargin) {
        dropdownClasses.value[key] = 'top-0 translate-y-0';
      }
    }
  }
};
</script>

<template>
  <aside class="bg-white border-r border-slate-200 transition-all duration-300 flex flex-col relative z-20"
    :class="isExpanded ? 'w-60' : 'w-17'">
    <div class="h-20 flex items-center justify-center border-b border-slate-200 px-4">
      <img v-if="isExpanded" :src="bannerLogo" alt="Banner" class="h-10 object-contain" />
      <img v-else :src="iconLogo" alt="Logotipo" class="h-10 object-contain" />
    </div>

    <nav class="flex-1 py-4 flex flex-col gap-2 px-3 relative"
      :class="isExpanded ? 'overflow-y-auto' : 'overflow-visible'">

      <div class="relative group">
        <router-link title="Home" to="/"
          class="overflow-hidden flex items-center gap-3 px-3 py-2 rounded-md transition-colors"
          :class="route?.path === '/' ? 'bg-blue-100 text-blue-900' : 'text-slate-700 hover:bg-slate-100'">
          <home-icon class="size-5 shrink-0"></home-icon>
          <span v-if="isExpanded" class="font-medium whitespace-nowrap text-sm">Home</span>
        </router-link>

        <div v-if="!isExpanded"
          class="absolute left-full top-1/2 -translate-y-1/2 ml-3 px-2 py-1 bg-slate-800 text-white text-xs font-medium rounded opacity-0 group-hover:opacity-100 pointer-events-none transition-opacity whitespace-nowrap z-50">
          Home
        </div>
      </div>

      <div class="relative group" v-can="'VER_AGENDA'">
        <router-link title="Agenda" to="/agenda"
          class="overflow-hidden flex items-center gap-3 px-3 py-2 rounded-md transition-colors"
          :class="route?.path.startsWith('/agenda') ? 'bg-blue-100 text-blue-900' : 'text-slate-700 hover:bg-slate-100'">
          <calendar-days-icon class="size-5 shrink-0"></calendar-days-icon>
          <span v-if="isExpanded" class="font-medium whitespace-nowrap text-sm">Agenda</span>
        </router-link>

        <div v-if="!isExpanded"
          class="absolute left-full top-1/2 -translate-y-1/2 ml-3 px-2 py-1 bg-slate-800 text-white text-xs font-medium rounded opacity-0 group-hover:opacity-100 pointer-events-none transition-opacity whitespace-nowrap z-50">
          Agenda
        </div>
      </div>

      <div class="relative group" v-can="'VER_SERVICOS'">
        <router-link title="Serviços" to="/servicos"
          class="overflow-hidden flex items-center gap-3 px-3 py-2 rounded-md transition-colors"
          :class="route?.path.startsWith('/servicos') ? 'bg-blue-100 text-blue-900' : 'text-slate-700 hover:bg-slate-100'">
          <book-marked-icon class="size-5 shrink-0"></book-marked-icon>
          <span v-if="isExpanded" class="font-medium whitespace-nowrap text-sm">Serviços</span>
        </router-link>

        <div v-if="!isExpanded"
          class="absolute left-full top-1/2 -translate-y-1/2 ml-3 px-2 py-1 bg-slate-800 text-white text-xs font-medium rounded opacity-0 group-hover:opacity-100 pointer-events-none transition-opacity whitespace-nowrap z-50">
          Serviços
        </div>
      </div>

      <div class="relative group" v-can="'VER_CONTRATOS'">
        <router-link title="Contratos" to="/contratos"
          class="overflow-hidden flex items-center gap-3 px-3 py-2 rounded-md transition-colors"
          :class="route?.path.startsWith('/servicos') ? 'bg-blue-100 text-blue-900' : 'text-slate-700 hover:bg-slate-100'">
          <scroll-text-icon class="size-5 shrink-0"></scroll-text-icon>
          <span v-if="isExpanded" class="font-medium whitespace-nowrap text-sm">Contratos</span>
        </router-link>

        <div v-if="!isExpanded"
          class="absolute left-full top-1/2 -translate-y-1/2 ml-3 px-2 py-1 bg-slate-800 text-white text-xs font-medium rounded opacity-0 group-hover:opacity-100 pointer-events-none transition-opacity whitespace-nowrap z-50">
          Contratos
        </div>
      </div>

      <div class="relative group" v-can="'VER_CLIENTES'">
        <router-link title="Clientes" to="/clientes"
          class="overflow-hidden flex items-center gap-3 px-3 py-2 rounded-md transition-colors"
          :class="route?.path.startsWith('/clientes') ? 'bg-blue-100 text-blue-900' : 'text-slate-700 hover:bg-slate-100'">
          <landmark-icon class="size-5 shrink-0"></landmark-icon>
          <span v-if="isExpanded" class="font-medium whitespace-nowrap text-sm">Clientes</span>
        </router-link>

        <div v-if="!isExpanded"
          class="absolute left-full top-1/2 -translate-y-1/2 ml-3 px-2 py-1 bg-slate-800 text-white text-xs font-medium rounded opacity-0 group-hover:opacity-100 pointer-events-none transition-opacity whitespace-nowrap z-50">
          Clientes
        </div>
      </div>
      <div class="relative group" v-can="'VER_ESTOQUE'">
        <router-link title="Estoque" to="/estoque"
          class="overflow-hidden flex items-center gap-3 px-3 py-2 rounded-md transition-colors"
          :class="route?.path.startsWith('/estoque') ? 'bg-blue-100 text-blue-900' : 'text-slate-700 hover:bg-slate-100'">
          <package-icon class="size-5 shrink-0"></package-icon>
          <span v-if="isExpanded" class="font-medium whitespace-nowrap text-sm">Estoque</span>
        </router-link>
        <div v-if="!isExpanded"
          class="absolute left-full top-1/2 -translate-y-1/2 ml-3 px-2 py-1 bg-slate-800 text-white text-xs font-medium rounded opacity-0 group-hover:opacity-100 pointer-events-none transition-opacity whitespace-nowrap z-50">
          Estoque
        </div>
      </div>
      <div class="relative group" v-can="'VER_USUARIOS'">
        <router-link title="Usuários" to="/users"
          class="overflow-hidden flex items-center gap-3 px-3 py-2 rounded-md transition-colors"
          :class="route?.path.startsWith('/users') ? 'bg-blue-100 text-blue-900' : 'text-slate-700 hover:bg-slate-100'">
          <contact-icon class="size-5 shrink-0"></contact-icon>
          <span v-if="isExpanded" class="font-medium whitespace-nowrap text-sm">Usuários</span>
        </router-link>

        <div v-if="!isExpanded"
          class="absolute left-full top-1/2 -translate-y-1/2 ml-3 px-2 py-1 bg-slate-800 text-white text-xs font-medium rounded opacity-0 group-hover:opacity-100 pointer-events-none transition-opacity whitespace-nowrap z-50">
          Usuários
        </div>
      </div>
      <div class="relative group" v-can="'VER_EQUIPES'">
        <router-link title="Equipes" to="/equipes"
          class="overflow-hidden flex items-center gap-3 px-3 py-2 rounded-md transition-colors"
          :class="route?.path.startsWith('/equipes') ? 'bg-blue-100 text-blue-900' : 'text-slate-700 hover:bg-slate-100'">
          <handshake-icon class="size-5 shrink-0"></handshake-icon>
          <span v-if="isExpanded" class="font-medium whitespace-nowrap text-sm">Equipes</span>
        </router-link>

        <div v-if="!isExpanded"
          class="absolute left-full top-1/2 -translate-y-1/2 ml-3 px-2 py-1 bg-slate-800 text-white text-xs font-medium rounded opacity-0 group-hover:opacity-100 pointer-events-none transition-opacity whitespace-nowrap z-50">
          Equipes
        </div>
      </div>

      <div class="relative group" v-can="'VER_RELATORIOS'">
        <button @click="toggleDropdown('relatorios')"
          class="cursor-pointer w-full flex items-center justify-between px-3 py-2 rounded-md hover:bg-slate-100 transition-colors text-slate-700"
          :class="{ 'bg-slate-100': openDropdowns.relatorios }">
          <div class="overflow-hidden flex items-center gap-3">
            <chart-column class="size-5 shrink-0"></chart-column>
            <span v-if="isExpanded" class="font-medium whitespace-nowrap text-sm">Relatórios</span>
          </div>
          <chevron-down-icon class="size-4 transition-transform"
            :class="{ 'text-slate-500 absolute right-0 top-1/2 -translate-y-1/2 -rotate-90': !isExpanded, 'rotate-180': openDropdowns.relatorios && isExpanded, 'rotate-90': openDropdowns.relatorios && !isExpanded, }"></chevron-down-icon>
        </button>
        <div v-if="!isExpanded && !openDropdowns.relatorios"
          class="absolute left-full top-1/2 -translate-y-1/2 ml-3 px-2 py-1 bg-slate-800 text-white text-xs font-medium rounded opacity-0 group-hover:opacity-100 pointer-events-none transition-opacity whitespace-nowrap z-50">
          Relatórios
        </div>

        <div id="dropdown-relatorios" v-show="openDropdowns.relatorios" :class="[
          isExpanded
            ? 'mt-1 flex flex-col gap-1 border-l-2 border-slate-200 ml-6 pl-2'
            : 'absolute left-full ml-4 w-48 bg-white border border-slate-200 shadow-xl rounded-md p-2 flex flex-col gap-1 z-51',
          !isExpanded ? dropdownClasses.relatorios : ''
        ]">

          <div v-if="!isExpanded"
            class="text-xs font-bold text-slate-400 uppercase mb-2 px-2 border-b border-slate-100 pb-1">
            Relatórios
          </div>
          <router-link to="/relatorios/vendedores" title="Vendedores"
            :class="route?.path.startsWith('/relatorios/vendedores') ? 'bg-blue-100 text-blue-900' : 'text-slate-700 hover:bg-slate-100'"
            class="px-3 py-2 rounded-md text-sm text-slate-600 truncate">
            Vendedores
          </router-link>
          <router-link to="/relatorios/financas" title="Finanças"
            :class="route?.path.startsWith('/relatorios/financas') ? 'bg-blue-100 text-blue-900' : 'text-slate-700 hover:bg-slate-100'"
            class="px-3 py-2 rounded-md text-sm text-slate-600 truncate">
            Finanças
          </router-link>
          <router-link to="/relatorios/estoque" title="Estoque"
            :class="route?.path.startsWith('/relatorios/estoque') ? 'bg-blue-100 text-blue-900' : 'text-slate-700 hover:bg-slate-100'"
            class="px-3 py-2 rounded-md text-sm text-slate-600 truncate">
            Estoque
          </router-link>
        </div>
      </div>

      <div class="relative group" v-can="'VER_CONFIGURACOES'">
        <button @click="toggleDropdown('configuracoes')"
          class="cursor-pointer w-full flex items-center justify-between px-3 py-2 rounded-md transition-colors text-slate-700"
          :class="{ 'bg-slate-100': openDropdowns.configuracoes }">
          <div class="overflow-hidden flex items-center gap-3">
            <settings2-icon class="size-5 shrink-0"></settings2-icon>
            <span v-if="isExpanded" class="font-medium whitespace-nowrap text-sm">Configurações</span>
          </div>
          <chevron-down-icon class="size-4 transition-transform"
            :class="{ 'text-slate-500 absolute right-0 top-1/2 -translate-y-1/2 -rotate-90': !isExpanded, 'rotate-180': openDropdowns.configuracoes && isExpanded, 'rotate-90': openDropdowns.configuracoes && !isExpanded, }"></chevron-down-icon>
        </button>
        <div v-if="!isExpanded && !openDropdowns.configuracoes"
          class="absolute left-full top-1/2 -translate-y-1/2 ml-3 px-2 py-1 bg-slate-800 text-white text-xs font-medium rounded opacity-0 group-hover:opacity-100 pointer-events-none transition-opacity whitespace-nowrap z-50">
          Configurações
        </div>

        <div id="dropdown-configuracoes" v-show="openDropdowns.configuracoes" :class="[
          isExpanded
            ? 'mt-1 flex flex-col gap-1 border-l-2 border-slate-200 ml-6 pl-2'
            : 'absolute left-full ml-4 w-48 bg-white border border-slate-200 shadow-xl rounded-md p-2 flex flex-col gap-1 z-50',
          !isExpanded ? dropdownClasses.configuracoes : ''
        ]">

          <div v-if="!isExpanded"
            class="text-xs font-bold text-slate-400 uppercase mb-2 px-2 border-b border-slate-100 pb-1">
            Configurações
          </div>
          <router-link to="/configuracoes/tipoServicos"
            :class="route?.path.startsWith('/configuracoes/tipoServicos') ? 'bg-blue-100 text-blue-900' : 'text-slate-700 hover:bg-slate-100'"
            title="Tipos de Serviço" class="px-3 py-2 rounded-md text-sm text-slate-600 truncate">
            Tipos de Serviço
          </router-link>
          <router-link to="/configuracoes/tipoTarefas"
            :class="route?.path.startsWith('/configuracoes/tipoTarefas') ? 'bg-blue-100 text-blue-900' : 'text-slate-700 hover:bg-slate-100'"
            title="Tipos de Tarefa" class="px-3 py-2 rounded-md text-sm text-slate-600 truncate">
            Tipos de Tarefa
          </router-link>
          <router-link to="/configuracoes/tipoEquipamentos"
            :class="route?.path.startsWith('/configuracoes/tipoEquipamentos') ? 'bg-blue-100 text-blue-900' : 'text-slate-700 hover:bg-slate-100'"
            title="Tipos de Equipamento" class="px-3 py-2 rounded-md text-sm text-slate-600 truncate">
            Tipos de Equipamento
          </router-link>
          <router-link to="/configuracoes/especializacoes"
            :class="route?.path.startsWith('/configuracoes/especializacoes') ? 'bg-blue-100 text-blue-900' : 'text-slate-700 hover:bg-slate-100'"
            title="Especializações e Requisitos" class="px-3 py-2 rounded-md text-sm text-slate-600 truncate">
            Especializações e Requisitos
          </router-link>
          <router-link to="/configuracoes/roles"
            :class="route?.path.startsWith('/configuracoes/roles') ? 'bg-blue-100 text-blue-900' : 'text-slate-700 hover:bg-slate-100'"
            title="Cargos" class="px-3 py-2 rounded-md text-sm text-slate-600 truncate">
            Cargos
          </router-link>
        </div>
      </div>
    </nav>
  </aside>
</template>