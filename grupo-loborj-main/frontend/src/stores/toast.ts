import { nanoid } from "nanoid";
import { defineStore } from "pinia";
import { nextTick } from "vue";

type ToastStyle = "success" | "error" | "warning" | "info"

type Toast = {
  id: string;
  message: string;
  style: ToastStyle
}

type ToastState = (Toast | {
  id: null
  message: null;
  style: null;
})

export const useToastStore = defineStore('toast', {
  state: (): ToastState => {
    return {
      id: null,
      message: null,
      style: null
    }
  },

  getters: {
    toast(): Toast | null {
      return this.message ? { id: this.id, message: this.message, style: this.style } : null;
    },
    hasToast(): boolean {
      return this.message !== null;
    }
  },

  actions: {
    clearToast() {
      this.id = null;
      this.message = null
      this.style = null
    },
    send({ message, style }: { message: string, style: ToastStyle }) {
      this.clearToast();
      nextTick().then(() => {
        const currentId = nanoid();
        this.id = currentId;
        this.message = message;
        this.style = style;

        setTimeout(() => {
          if (this.id === currentId) {
            this.clearToast();
          }
        }, 5000);
      });
    }
  }
});