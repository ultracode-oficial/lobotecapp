<script setup lang="ts">
import { CircleAlertIcon, CircleCheckIcon, Loader2Icon, TriangleAlertIcon } from '@lucide/vue';
import { computed } from 'vue';

const props = defineProps<{
  isOpen: boolean;
  title: string;
  message: string;
  confirmText?: string;
  cancelText?: string;
  type?: 'danger' | 'success' | 'warning' | 'info';
  isLoading?: boolean;
}>();

const emit = defineEmits(['update:isOpen', 'confirm', 'cancel']);

function handleClose() {
  if (props.isLoading) return;
  emit('update:isOpen', false);
  emit('cancel');
}

function handleConfirm() {
  if (props.isLoading) return;
  emit('confirm');
}

// Estilização dinâmica do botão baseada no tipo da ação
const confirmButtonClass = computed(() => {
  switch (props.type) {
    case 'danger':
      return 'disabled:bg-red-300 bg-red-600 hover:bg-red-700 focus:ring-red-500';
    case 'success':
      return 'disabled:bg-green-300 bg-green-600 hover:bg-green-700 focus:ring-green-500';
    case 'warning':
      return 'disabled:bg-yellow-300 bg-yellow-600 hover:bg-yellow-700 focus:ring-yellow-500';
    case 'info':
    default:
      return 'disabled:bg-indigo-300 bg-indigo-600 hover:bg-indigo-700 focus:ring-indigo-500';
  }
});
</script>

<template>
  <Teleport to="body">
    <Transition name="fade">
      <div v-if="isOpen" class="relative z-50" aria-labelledby="modal-title" role="dialog" aria-modal="true">

        <!-- Fundo escuro (Backdrop) -->
        <div class="fixed inset-0 bg-slate-500 opacity-50 transition-opacity" @click="handleClose"></div>

        <div class="fixed inset-0 z-10 overflow-y-auto">
          <div class="flex min-h-full items-end justify-center p-4 text-center sm:items-center sm:p-0">
            <Transition name="slide-up">
              <div v-if="isOpen"
                class="relative transform overflow-hidden rounded-lg bg-white text-left shadow-xl transition-all sm:my-8 sm:w-full sm:max-w-lg">
                <div class="bg-white px-4 pb-4 pt-5 sm:p-6 sm:pb-4">
                  <div class="sm:flex sm:items-start">

                    <!-- Ícones dinâmicos -->
                    <div v-if="type === 'danger'"
                      class="mx-auto flex h-12 w-12 shrink-0 items-center justify-center rounded-full bg-red-100 text-red-600 sm:mx-0 sm:h-10 sm:w-10">
                      <TriangleAlertIcon class="size-6"></TriangleAlertIcon>
                    </div>
                    <div v-else-if="type === 'success'"
                      class="mx-auto flex h-12 w-12 shrink-0 items-center justify-center rounded-full bg-green-100 text-green-600 sm:mx-0 sm:h-10 sm:w-10">
                      <CircleCheckIcon class="size-6"></CircleCheckIcon>
                    </div>

                    <!-- Conteúdo -->
                    <div class="mt-3 text-center sm:ml-4 sm:mt-0 sm:text-left">
                      <h3 class="text-base font-semibold leading-6 text-slate-900" id="modal-title">{{ title }}</h3>
                      <div class="mt-2">
                        <p class="text-sm text-slate-500">{{ message }}</p>
                      </div>
                    </div>
                  </div>
                </div>

                <!-- Rodapé / Botões -->
                <div class="bg-slate-50 px-4 py-3 sm:flex gap-3 justify-end sm:px-6">
                  <button type="button"
                    class="cursor-pointer disabled:cursor-not-allowed inline-flex w-full justify-center rounded-md px-4 py-2 text-sm font-semibold text-white shadow-sm sm:ml-3 sm:w-auto focus:outline-none focus:ring-2 focus:ring-offset-2 disabled:opacity-50 transition-colors"
                    :class="confirmButtonClass" :disabled="isLoading" @click="handleConfirm">
                    <Loader2Icon v-if="isLoading" class="animate-spin -ml-1 mr-2 size-5 text-white"></Loader2Icon>
                    {{ confirmText || 'Confirmar' }}
                  </button>
                  <button type="button"
                    class="cursor-pointer disabled:cursor-not-allowed mt-3 inline-flex w-full justify-center rounded-md bg-white px-4 py-2 text-sm font-semibold text-slate-900 shadow-sm ring-1 ring-inset ring-slate-300 hover:bg-slate-50 sm:mt-0 sm:w-auto disabled:opacity-50"
                    :disabled="isLoading" @click="handleClose">
                    {{ cancelText || 'Cancelar' }}
                  </button>
                </div>
              </div>
            </Transition>
          </div>
        </div>
      </div>
    </Transition>
  </Teleport>
</template>

<style scoped>
/* Classes do Vue Transition */
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.2s ease;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}

.slide-up-enter-active,
.slide-up-leave-active {
  transition: all 0.2s ease;
}

.slide-up-enter-from,
.slide-up-leave-to {
  opacity: 0;
  transform: trangrayY(10px) scale(0.95);
}
</style>