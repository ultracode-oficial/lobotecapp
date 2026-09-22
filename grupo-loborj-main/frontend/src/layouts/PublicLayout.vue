<script setup>
import { nextTick, ref, watch } from 'vue';
import { useToastStore } from '@/stores/toast';
import { XIcon } from '@lucide/vue';
import { storeToRefs } from 'pinia';

const toastStore = useToastStore();
const { hasToast } = storeToRefs(toastStore);

const toastElement = ref(null)

watch(hasToast, async (newVal) => {
  if (newVal) {
    await nextTick()
    toastElement.value?.scrollIntoView({ behavior: 'smooth' })
  }
})
</script>

<template>
  <main class="min-h-screen flex-1 overflow-x-hidden overflow-y-auto bg-slate-100 px-6 py-4 flex flex-col">
    <div v-if="toastStore.hasToast" ref="toastElement"
      class="scroll-mt-8 relative rounded p-2 text-base flex items-center justify-between mb-6" :class="{
        'bg-red-100 text-red-500 border border-red-500': toastStore.toast.style === 'error',
        'bg-green-100 text-green-600 border border-green-600': toastStore.toast.style === 'success',
        'bg-amber-100 text-amber-600 border border-amber-600': toastStore.toast.style === 'warning',
        'bg-blue-100 text-blue-600 border border-blue-600': toastStore.toast.style === 'info',
      }">{{ toastStore.toast.message }}
      <button @click="toastStore.clearToast" class="rounded cursor-pointer border" :class="{
        'hover:bg-red-200 border-red-500': toastStore.toast.style === 'error',
        'hover:bg-green-200 border-green-600': toastStore.toast.style === 'success',
        'hover:bg-amber-200 border-amber-600': toastStore.toast.style === 'warning',
        'hover:bg-blue-200 border-blue-600': toastStore.toast.style === 'info',
      }"><x-icon class="size-4"></x-icon></button>
      <div
        class="absolute bottom-0 left-0 border-b-3 opacity-40 origin-bottom-left rounded-b transition-transform animate-grow-side w-full">
      </div>
    </div>
    <slot />
  </main>
</template>