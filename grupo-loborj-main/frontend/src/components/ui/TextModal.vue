<script setup lang="ts">
import { XIcon } from '@lucide/vue';

const props = defineProps<{
  isOpen: boolean;
  title: string;
  text: string;
}>();

const emit = defineEmits(['update:isOpen', 'close']);

function handleClose() {
  emit('update:isOpen', false);
  emit('close');
}
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
                class="relative transform overflow-hidden rounded-lg bg-white text-left shadow-xl transition-all sm:my-8 sm:w-full sm:max-w-2xl">

                <!-- Cabeçalho -->
                <div class="bg-white px-4 py-4 sm:px-6 flex justify-between items-center border-b border-slate-100">
                  <h3 class="text-lg font-semibold leading-6 text-slate-900" id="modal-title">
                    {{ title }}
                  </h3>
                  <button @click="handleClose"
                    title="Fechar"
                    class="cursor-pointer text-slate-400 hover:text-slate-500 transition-colors rounded-md">
                    <XIcon class="size-5"></XIcon>
                  </button>
                </div>

                <!-- Conteúdo com Scroll -->
                <div class="bg-white px-4 py-5 sm:p-6 sm:pb-6 max-h-[60vh] overflow-y-auto">
                  <div class="text-slate-700">
                    <!-- whitespace-pre-wrap respeita as quebras de linha originais do texto -->
                    <p class="text-sm whitespace-pre-wrap leading-relaxed">{{ text }}</p>
                  </div>
                </div>

                <!-- Rodapé -->
                <div class="bg-slate-50 px-4 py-3 sm:flex justify-end sm:px-6">
                  <button type="button"
                    class="cursor-pointer disabled:cursor-not-allowed mt-3 inline-flex w-full justify-center rounded-md bg-white px-4 py-2 text-sm font-semibold text-slate-900 shadow-sm ring-1 ring-inset ring-slate-300 hover:bg-slate-50 sm:mt-0 sm:w-auto disabled:opacity-50"
                    @click="handleClose">
                    Fechar
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
  transform: translateY(10px) scale(0.95);
}
</style>