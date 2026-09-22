import Echo from 'laravel-echo';
import Pusher from 'pusher-js';
import axios from 'axios';
import { useAuthStore } from '@/stores/auth';

declare global {
  interface Window { Pusher: typeof Pusher; }
}

window.Pusher = Pusher;

const echo = new Echo({
  broadcaster: 'reverb',
  key: import.meta.env.VITE_REVERB_APP_KEY,
  wsHost: import.meta.env.VITE_REVERB_HOST,
  wsPort: import.meta.env.VITE_REVERB_PORT ?? 8080,
  wssPort: import.meta.env.VITE_REVERB_PORT ?? 443,
  forceTLS: (import.meta.env.VITE_REVERB_SCHEME ?? 'https') === 'https',
  enabledTransports: ['ws', 'wss'],
  authorizer: (channel: any) => {
    return {
      authorize: (socketId: string, callback: Function) => {
        const authStore = useAuthStore();

        axios.post(`${import.meta.env.VITE_REVERB_URL}/broadcasting/auth`, {
          socket_id: socketId,
          channel_name: channel.name
        }, {
          headers: {
            Accept: 'application/json',
            Authorization: authStore.token ? `Bearer ${authStore.token}` : '',
            "X-Platform": "web"
          }
        })
          .then(response => {
            callback(null, response.data);
          })
          .catch(error => {
            callback(error);
          });
      }
    };
  }
});

export default echo;