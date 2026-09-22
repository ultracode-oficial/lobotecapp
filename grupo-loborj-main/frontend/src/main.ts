import './assets/main.css'
import { createApp } from 'vue'
import { createPinia } from 'pinia'
import App from './App.vue'
import router from './router'
import axios from 'axios'
import { VueQueryPlugin } from '@tanstack/vue-query'
import { useAuthStore } from './stores/auth.ts'

axios.defaults.withCredentials = true;
axios.defaults.withXSRFToken = true;

const app = createApp(App)

app.use(createPinia())
const authStore = useAuthStore()

app.directive('can', {
  mounted(el, binding) {
    const authStore = useAuthStore();
    // Se o usuário não tiver a permissão e não for desenvolvedor, removemos o elemento do DOM
    if (!authStore.hasPermission(binding.value) && !authStore.user?.is_developer) {
      // el.style.display = 'none';
      el.parentNode?.removeChild(el);
    }
  }
})

app.directive('role', {
  mounted(el, binding) {
    const authStore = useAuthStore();
    // Se o usuário não tiver a role e não for desenvolvedor, removemos o elemento do DOM
    if (!authStore.hasRole(binding.value) && !authStore.user?.is_developer) {
      // el.style.display = 'none';
      el.parentNode?.removeChild(el);
    }
  }
})

app.use(VueQueryPlugin)
app.use(router)

authStore.initAuth().finally(() => {
  app.mount('#app');
});