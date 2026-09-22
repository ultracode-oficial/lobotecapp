import { defineStore } from 'pinia';
import { jwtDecode } from 'jwt-decode';
import axios from 'axios';
import api from '@/services/api';

export interface User {
  id: number;
  name: string;
  email: string;
  cpf?: string;
  phone?: string;
  photo?: string;
  mfa_enabled: boolean;
  mfa_pending?: boolean;
  mfa_required?: boolean;
  change_password_required?: boolean;
  is_developer: boolean;
  created_at: string;
  updated_at: string;
}

export interface JwtPayload {
  iss?: string;
  iat?: number;
  exp?: number;
  nbf?: number;
  jti?: string;
  sub?: number | string;
  prv?: string;

  // Custom Claims injetados pelo método getJWTCustomClaims() no Laravel
  user?: {
    id: number;
    is_developer: boolean;
  };
  roles?: string[];
  permissions?: string[];
  is_developer?: boolean;
}

interface AuthState {
  token: string | null;
  payload: JwtPayload | null;
  user: User | null;
}

export const useAuthStore = defineStore('auth', {
  state: (): AuthState => {
    const token = localStorage.getItem('access_token') || null;
    let payload: JwtPayload | null = null;

    if (token) {
      try {
        payload = jwtDecode<JwtPayload>(token);
      } catch {
        payload = null;
      }
    }

    const user: User | null = null;

    return {
      token,
      payload,
      user
    };
  },

  getters: {
    isMfaPending(): boolean {
      return !!this.user?.mfa_pending;
    },

    isMfaActive(): boolean {
      return !!this.user?.mfa_enabled;
    },

    isAuthenticated(): boolean {
      return !!this.token && !this.user?.mfa_pending;
    },

    permissions(): string[] {
      return this.payload?.permissions || [];
    },

    roles(): string[] {
      return this.payload?.roles || [];
    },

    isDeveloper(): boolean {
      return !!this.user?.is_developer;
    }
  },

  actions: {
    /**
     * Define o token ativo e atualiza o payload decodificado de forma reativa
     */
    setToken(token: string | null, user: User | null, persist: boolean = true): void {
      this.token = token;

      if (token && user) {
        try {
          this.payload = jwtDecode<JwtPayload>(token);
          this.user = user;

          if (persist) {
            localStorage.setItem('access_token', token);
          }
        } catch {
          this.logout();
        }
      } else {
        this.payload = null;
        this.user = null;
        localStorage.removeItem('access_token');
      }
    },

    logout(): void {
      this.setToken(null, null, false);
    },

    hasPermission(permission: string): boolean {
      if (this.isDeveloper) return true;
      return this.permissions.includes(permission);
    },

    hasRole(role: string): boolean {
      if (this.isDeveloper) return true;
      return this.roles.includes(role);
    },

    async refetchUser() {
      try {
        const { data } = await api.post(`${import.meta.env.VITE_API_URL}/auth/refresh`);
        this.setToken(data.access_token, data.user, true);
      } catch (err) {
        this.logout();
      }
    },

    async initAuth() {
      if (!this.token) return;
      try {
        const { data } = await axios.post(`${import.meta.env.VITE_API_URL}/auth/refresh`, {}, {
          headers: { Authorization: `Bearer ${this.token}` }
        });

        this.setToken(data.access_token, data.user, true);
      } catch (err) {
        this.logout();
      }
    },
  }
});