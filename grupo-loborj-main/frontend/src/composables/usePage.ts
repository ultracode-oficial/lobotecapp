// src/composables/usePage.js
import { ref } from 'vue';

// O estado fica FORA da função para ser global e reativo entre os componentes
const pageTitle = ref('');
const pageSubtitle = ref('');

export function usePage() {
  const setHeader = (title = '', subtitle = '') => {
    pageTitle.value = title;
    pageSubtitle.value = subtitle;
  };

  return { pageTitle, pageSubtitle, setHeader };
}