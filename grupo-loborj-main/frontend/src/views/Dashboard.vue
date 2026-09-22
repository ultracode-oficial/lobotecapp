<script setup>
import { useAuthStore } from '@/stores/auth';
import { onMounted } from 'vue';
import { usePage } from '@/composables/usePage';

const { setHeader } = usePage();
const authStore = useAuthStore();
const userName = authStore.user?.name?.split(" ")[0] || 'John Doe';

onMounted(() => {
  setHeader('Dashboard Geral', `Olá, ${userName}! Bem-vindo de volta.`);
});

</script>

<template>
  <div class="w-full py-3">
    <h2 class="text-xl font-bold text-slate-800 mb-6">Dashboard</h2>
  </div>
</template>