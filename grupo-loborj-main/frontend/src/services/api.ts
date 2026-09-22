import axios from 'axios';
import { useAuthStore } from '@/stores/auth';
import router from '@/router';
import { useToastStore } from '@/stores/toast';

const api = axios.create({
  baseURL: import.meta.env.VITE_API_URL || 'http://localhost:8000/api',
  headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'X-Platform': 'web' // <-- Identifica globalmente que este SPA é a plataforma Web
  }
});

let isRefreshing = false;
let failedQueue: any[] = [];

const processQueue = (error: unknown, token = null) => {
  failedQueue.forEach(prom => {
    if (error) {
      prom.reject(error);
    } else {
      prom.resolve(token);
    }
  });
  failedQueue = [];
};

// Interceptor de Requisição (Injeta o Token)
api.interceptors.request.use(config => {
  const authStore = useAuthStore();
  if (authStore.token) {
    config.headers.Authorization = `Bearer ${authStore.token}`;
  }
  return config;
});

// Interceptor de Resposta (Trata 401 e 403)
api.interceptors.response.use(
  response => response,
  async error => {
    const originalRequest = error.config;
    const authStore = useAuthStore();
    const toastStore = useToastStore();

    // Lida com 401 - Token Expirado/Inválido
    if (error.response?.status === 401 && !originalRequest._retry) {
      if (isRefreshing) {
        return new Promise(function (resolve, reject) {
          failedQueue.push({ resolve, reject });
        }).then(token => {
          originalRequest.headers['Authorization'] = 'Bearer ' + token;
          return api(originalRequest);
        }).catch(err => Promise.reject(err));
      }

      originalRequest._retry = true;
      isRefreshing = true;

      try {
        const { data } = await axios.post(`${api.defaults.baseURL}/auth/refresh`, {}, {
          headers: { Authorization: `Bearer ${authStore.token}` }
        });

        const newToken = data.access_token;
        authStore.setToken(newToken, data.user);

        processQueue(null, newToken);
        originalRequest.headers['Authorization'] = `Bearer ${newToken}`;

        return api(originalRequest);
      } catch (err) {
        processQueue(err, null);
        authStore.logout();
        router.push({ name: 'login' });
        return Promise.reject(err);
      } finally {
        isRefreshing = false;
      }
    }

    // Lida com 403 - Permissão Negada
    if (error.response?.status === 403) {
      toastStore.send({
        message: 'Acesso negado: sua conta não tem permissão para esta ação.',
        style: 'warning'
      });
    }

    return Promise.reject(error.response.data);
  }
);

api.interceptors.request.use(config => {
  const authStore = useAuthStore();
  if (authStore.token) {
    config.headers.Authorization = `Bearer ${authStore.token}`;
  }
  return config;
});

export default api;