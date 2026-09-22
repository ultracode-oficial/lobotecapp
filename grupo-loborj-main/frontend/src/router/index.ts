import { createRouter, createWebHistory, type RouteRecordRaw } from 'vue-router';
import { useAuthStore } from '@/stores/auth';
import PublicLayout from '@/layouts/PublicLayout.vue';
import AuthLayout from '@/layouts/AuthLayout.vue';
import { useToastStore } from '@/stores/toast';

const routes: RouteRecordRaw[] = [
  // --- ROTAS PÚBLICAS (NÃO LOGADAS) ---
  {
    path: '/login',
    name: 'login',
    component: () => import('@/views/Login.vue'),
    meta: {
      layout: PublicLayout,
      title: 'Login',
      guestOnly: true // Flag para impedir que usuários logados voltem para o login
    }
  },
  {
    path: '/forgot-password',
    name: 'forgot-password',
    component: () => import('@/views/ForgotPassword.vue'),
    meta: {
      layout: PublicLayout,
      title: 'Esqueci minha senha',
      guestOnly: true // Flag para impedir que usuários logados voltem para o forgot password
    }
  },

  // --- ROTAS PROTEGIDAS (LOGADAS) ---
  {
    path: '/',
    name: 'dashboard',
    component: () => import('@/views/Dashboard.vue'),
    meta: {
      layout: AuthLayout,
      title: 'Dashboard',
      requiresAuth: true
    }
  },

  {
    path: '/notifications',
    name: 'notifications',
    component: () => import('@/views/Notifications.vue'),
    meta: {
      layout: AuthLayout,
      title: 'Notificações',
      requiresAuth: true
    }
  },

  {
    path: '/profile',
    name: 'profile',
    component: () => import('@/views/MeuPerfil.vue'),
    meta: {
      layout: AuthLayout,
      title: 'Meu Perfil',
      requiresAuth: true
    }
  },
  {
    path: '/security',
    name: 'security',
    component: () => import('@/views/SegurancaDaConta.vue'),
    meta: {
      layout: AuthLayout,
      title: 'Segurança da Conta',
      requiresAuth: true
    }
  },

  // Clientes
  {
    path: '/clientes',
    name: 'clientes.index',
    component: () => import('@/views/clientes/Index.vue'),
    meta: {
      layout: AuthLayout,
      title: 'Clientes',
      requiresAuth: true
    },
    beforeEnter: (to, from) => {
      const authStore = useAuthStore();
      const toastStore = useToastStore();

      if (!authStore.hasPermission('VER_CLIENTES')) {
        toastStore.send({
          message: 'Você não possui permissão para acessar este recurso.',
          style: 'warning'
        });

        return { name: 'dashboard' };
      }

      return true;
    }
  },
  {
    path: '/clientes/create',
    name: 'clientes.create',
    component: () => import('@/views/clientes/Create.vue'),
    meta: {
      layout: AuthLayout,
      title: 'Criar Cliente',
      requiresAuth: true
    },
    beforeEnter: (to, from) => {
      const authStore = useAuthStore();
      const toastStore = useToastStore();

      if (!authStore.hasPermission('CRIAR_CLIENTES')) {
        toastStore.send({
          message: 'Você não possui permissão para acessar este recurso.',
          style: 'warning'
        });

        return { name: 'dashboard' };
      }

      return true;
    }
  },
  {
    path: '/clientes/:id/edit',
    name: 'clientes.edit',
    component: () => import('@/views/clientes/Edit.vue'),
    meta: {
      layout: AuthLayout,
      title: 'Editar Cliente',
      requiresAuth: true
    },
    beforeEnter: (to, from) => {
      const authStore = useAuthStore();
      const toastStore = useToastStore();

      if (!authStore.hasPermission('CRIAR_CLIENTES') && !authStore.hasPermission('GERIR_CLIENTES')) {
        toastStore.send({
          message: 'Você não possui permissão para acessar este recurso.',
          style: 'warning'
        });

        return { name: 'dashboard' };
      }

      return true;
    }
  },

  // Usuários
  {
    path: '/users',
    name: 'users.index',
    component: () => import('@/views/users/Index.vue'),
    meta: {
      layout: AuthLayout,
      title: 'Usuários',
      requiresAuth: true
    },
    beforeEnter: (to, from) => {
      const authStore = useAuthStore();
      const toastStore = useToastStore();

      if (!authStore.hasPermission('VER_USUARIOS')) {
        toastStore.send({
          message: 'Você não possui permissão para acessar este recurso.',
          style: 'warning'
        });

        return { name: 'dashboard' };
      }

      return true;
    }
  },
  {
    path: '/users/create',
    name: 'users.create',
    component: () => import('@/views/users/Create.vue'),
    meta: {
      layout: AuthLayout,
      title: 'Criar Usuário',
      requiresAuth: true
    },
    beforeEnter: (to, from) => {
      const authStore = useAuthStore();
      const toastStore = useToastStore();

      if (!authStore.hasPermission('CRIAR_USUARIOS')) {
        toastStore.send({
          message: 'Você não possui permissão para acessar este recurso.',
          style: 'warning'
        });

        return { name: 'dashboard' };
      }

      return true;
    }
  },
  {
    path: '/users/:id/edit',
    name: 'users.edit',
    component: () => import('@/views/users/Edit.vue'),
    meta: {
      layout: AuthLayout,
      title: 'Editar Usuário',
      requiresAuth: true
    },
    beforeEnter: (to, from) => {
      const authStore = useAuthStore();
      const toastStore = useToastStore();

      if (!authStore.hasPermission('GERIR_USUARIOS')) {
        toastStore.send({
          message: 'Você não possui permissão para acessar este recurso.',
          style: 'warning'
        });

        return { name: 'dashboard' };
      }

      return true;
    }
  },

  // Equipes
  {
    path: '/equipes',
    name: 'equipes.index',
    component: () => import('@/views/equipes/Index.vue'),
    meta: {
      layout: AuthLayout,
      title: 'Equipes',
      requiresAuth: true
    },
    beforeEnter: (to, from) => {
      const authStore = useAuthStore();
      const toastStore = useToastStore();

      if (!authStore.hasPermission('VER_EQUIPES')) {
        toastStore.send({
          message: 'Você não possui permissão para acessar este recurso.',
          style: 'warning'
        });

        return { name: 'dashboard' };
      }

      return true;
    }
  },
  {
    path: '/equipes/create',
    name: 'equipes.create',
    component: () => import('@/views/equipes/Create.vue'),
    meta: {
      layout: AuthLayout,
      title: 'Criar Equipe',
      requiresAuth: true
    },
    beforeEnter: (to, from) => {
      const authStore = useAuthStore();
      const toastStore = useToastStore();

      if (!authStore.hasPermission('CRIAR_EQUIPES')) {
        toastStore.send({
          message: 'Você não possui permissão para acessar este recurso.',
          style: 'warning'
        });

        return { name: 'dashboard' };
      }

      return true;
    }
  },
  {
    path: '/equipes/:id/edit',
    name: 'equipes.edit',
    component: () => import('@/views/equipes/Edit.vue'),
    meta: {
      layout: AuthLayout,
      title: 'Editar Equipe',
      requiresAuth: true
    },
    beforeEnter: (to, from) => {
      const authStore = useAuthStore();
      const toastStore = useToastStore();

      if (!authStore.hasPermission('GERIR_EQUIPES')) {
        toastStore.send({
          message: 'Você não possui permissão para acessar este recurso.',
          style: 'warning'
        });

        return { name: 'dashboard' };
      }

      return true;
    }
  },

  // Especializações
  {
    path: '/configuracoes/roles',
    name: 'roles.index',
    component: () => import('@/views/roles/Index.vue'),
    meta: {
      layout: AuthLayout,
      title: 'Cargos',
      requiresAuth: true
    },
    beforeEnter: (to, from) => {
      const authStore = useAuthStore();
      const toastStore = useToastStore();

      if (!authStore.hasPermission('VER_CONFIGURACOES')) {
        toastStore.send({
          message: 'Você não possui permissão para acessar este recurso.',
          style: 'warning'
        });

        return { name: 'dashboard' };
      }

      return true;
    }
  },
  {
    path: '/configuracoes/roles/create',
    name: 'roles.create',
    component: () => import('@/views/roles/Create.vue'),
    meta: {
      layout: AuthLayout,
      title: 'Criar Cargo',
      requiresAuth: true
    },
    beforeEnter: (to, from) => {
      const authStore = useAuthStore();
      const toastStore = useToastStore();

      if (!authStore.hasPermission('GERIR_CONFIGURACOES')) {
        toastStore.send({
          message: 'Você não possui permissão para acessar este recurso.',
          style: 'warning'
        });

        return { name: 'dashboard' };
      }

      return true;
    }
  },
  {
    path: '/configuracoes/roles/:id/edit',
    name: 'roles.edit',
    component: () => import('@/views/roles/Edit.vue'),
    meta: {
      layout: AuthLayout,
      title: 'Editar Cargo',
      requiresAuth: true
    },
    beforeEnter: (to, from) => {
      const authStore = useAuthStore();
      const toastStore = useToastStore();

      if (!authStore.hasPermission('GERIR_CONFIGURACOES')) {
        toastStore.send({
          message: 'Você não possui permissão para acessar este recurso.',
          style: 'warning'
        });

        return { name: 'dashboard' };
      }

      return true;
    }
  },

  // Especializações
  {
    path: '/configuracoes/especializacoes',
    name: 'especializacoes.index',
    component: () => import('@/views/especializacoes/Index.vue'),
    meta: {
      layout: AuthLayout,
      title: 'Especializações e Requisitos',
      requiresAuth: true
    },
    beforeEnter: (to, from) => {
      const authStore = useAuthStore();
      const toastStore = useToastStore();

      if (!authStore.hasPermission('VER_CONFIGURACOES')) {
        toastStore.send({
          message: 'Você não possui permissão para acessar este recurso.',
          style: 'warning'
        });

        return { name: 'dashboard' };
      }

      return true;
    }
  },
  {
    path: '/configuracoes/especializacoes/create',
    name: 'especializacoes.create',
    component: () => import('@/views/especializacoes/Create.vue'),
    meta: {
      layout: AuthLayout,
      title: 'Criar Especialização/Requisito',
      requiresAuth: true
    },
    beforeEnter: (to, from) => {
      const authStore = useAuthStore();
      const toastStore = useToastStore();

      if (!authStore.hasPermission('GERIR_CONFIGURACOES')) {
        toastStore.send({
          message: 'Você não possui permissão para acessar este recurso.',
          style: 'warning'
        });

        return { name: 'dashboard' };
      }

      return true;
    }
  },
  {
    path: '/configuracoes/especializacoes/:id/edit',
    name: 'especializacoes.edit',
    component: () => import('@/views/especializacoes/Edit.vue'),
    meta: {
      layout: AuthLayout,
      title: 'Editar Especialização/Requisito',
      requiresAuth: true
    },
    beforeEnter: (to, from) => {
      const authStore = useAuthStore();
      const toastStore = useToastStore();

      if (!authStore.hasPermission('GERIR_CONFIGURACOES')) {
        toastStore.send({
          message: 'Você não possui permissão para acessar este recurso.',
          style: 'warning'
        });

        return { name: 'dashboard' };
      }

      return true;
    }
  },

  // Tipos de Serviço
  {
    path: '/configuracoes/tipoServicos',
    name: 'tipoServicos.index',
    component: () => import('@/views/tipoServicos/Index.vue'),
    meta: {
      layout: AuthLayout,
      title: 'Tipos de Serviço',
      requiresAuth: true
    },
    beforeEnter: (to, from) => {
      const authStore = useAuthStore();
      const toastStore = useToastStore();

      if (!authStore.hasPermission('VER_CONFIGURACOES')) {
        toastStore.send({
          message: 'Você não possui permissão para acessar este recurso.',
          style: 'warning'
        });

        return { name: 'dashboard' };
      }

      return true;
    }
  },
  {
    path: '/configuracoes/tipoServicos/create',
    name: 'tipoServicos.create',
    component: () => import('@/views/tipoServicos/Create.vue'),
    meta: {
      layout: AuthLayout,
      title: 'Criar Tipo de Serviço',
      requiresAuth: true
    },
    beforeEnter: (to, from) => {
      const authStore = useAuthStore();
      const toastStore = useToastStore();

      if (!authStore.hasPermission('GERIR_CONFIGURACOES')) {
        toastStore.send({
          message: 'Você não possui permissão para acessar este recurso.',
          style: 'warning'
        });

        return { name: 'dashboard' };
      }

      return true;
    }
  },
  {
    path: '/configuracoes/tipoServicos/:id/edit',
    name: 'tipoServicos.edit',
    component: () => import('@/views/tipoServicos/Edit.vue'),
    meta: {
      layout: AuthLayout,
      title: 'Editar Tipo de Serviço',
      requiresAuth: true
    },
    beforeEnter: (to, from) => {
      const authStore = useAuthStore();
      const toastStore = useToastStore();

      if (!authStore.hasPermission('GERIR_CONFIGURACOES')) {
        toastStore.send({
          message: 'Você não possui permissão para acessar este recurso.',
          style: 'warning'
        });

        return { name: 'dashboard' };
      }

      return true;
    }
  },

  // Tipos de Tarefas
  {
    path: '/configuracoes/tipoTarefas',
    name: 'tipoTarefas.index',
    component: () => import('@/views/tipoTarefas/Index.vue'),
    meta: {
      layout: AuthLayout,
      title: 'Tipos de Tarefa',
      requiresAuth: true
    },
    beforeEnter: (to, from) => {
      const authStore = useAuthStore();
      const toastStore = useToastStore();

      if (!authStore.hasPermission('VER_CONFIGURACOES')) {
        toastStore.send({
          message: 'Você não possui permissão para acessar este recurso.',
          style: 'warning'
        });

        return { name: 'dashboard' };
      }

      return true;
    }
  },
  {
    path: '/configuracoes/tipoTarefas/create',
    name: 'tipoTarefas.create',
    component: () => import('@/views/tipoTarefas/Create.vue'),
    meta: {
      layout: AuthLayout,
      title: 'Criar Tipo de Tarefa',
      requiresAuth: true
    },
    beforeEnter: (to, from) => {
      const authStore = useAuthStore();
      const toastStore = useToastStore();

      if (!authStore.hasPermission('GERIR_CONFIGURACOES')) {
        toastStore.send({
          message: 'Você não possui permissão para acessar este recurso.',
          style: 'warning'
        });

        return { name: 'dashboard' };
      }

      return true;
    }
  },
  {
    path: '/configuracoes/tipoTarefas/:id/edit',
    name: 'tipoTarefas.edit',
    component: () => import('@/views/tipoTarefas/Edit.vue'),
    meta: {
      layout: AuthLayout,
      title: 'Editar Tipo de Tarefa',
      requiresAuth: true
    },
    beforeEnter: (to, from) => {
      const authStore = useAuthStore();
      const toastStore = useToastStore();

      if (!authStore.hasPermission('GERIR_CONFIGURACOES')) {
        toastStore.send({
          message: 'Você não possui permissão para acessar este recurso.',
          style: 'warning'
        });

        return { name: 'dashboard' };
      }

      return true;
    }
  },

  // Tipos de Equipamentos
  {
    path: '/configuracoes/tipoEquipamentos',
    name: 'tipoEquipamentos.index',
    component: () => import('@/views/tipoEquipamentos/Index.vue'),
    meta: {
      layout: AuthLayout,
      title: 'Tipos de Equipamento',
      requiresAuth: true
    },
    beforeEnter: (to, from) => {
      const authStore = useAuthStore();
      const toastStore = useToastStore();

      if (!authStore.hasPermission('VER_CONFIGURACOES')) {
        toastStore.send({
          message: 'Você não possui permissão para acessar este recurso.',
          style: 'warning'
        });

        return { name: 'dashboard' };
      }

      return true;
    }
  },
  {
    path: '/configuracoes/tipoEquipamentos/create',
    name: 'tipoEquipamentos.create',
    component: () => import('@/views/tipoEquipamentos/Create.vue'),
    meta: {
      layout: AuthLayout,
      title: 'Criar Tipo de Equipamento',
      requiresAuth: true
    },
    beforeEnter: (to, from) => {
      const authStore = useAuthStore();
      const toastStore = useToastStore();

      if (!authStore.hasPermission('GERIR_CONFIGURACOES')) {
        toastStore.send({
          message: 'Você não possui permissão para acessar este recurso.',
          style: 'warning'
        });

        return { name: 'dashboard' };
      }

      return true;
    }
  },
  {
    path: '/configuracoes/tipoEquipamentos/:id/edit',
    name: 'tipoEquipamentos.edit',
    component: () => import('@/views/tipoEquipamentos/Edit.vue'),
    meta: {
      layout: AuthLayout,
      title: 'Editar Tipo de Equipamento',
      requiresAuth: true
    },
    beforeEnter: (to, from) => {
      const authStore = useAuthStore();
      const toastStore = useToastStore();

      if (!authStore.hasPermission('GERIR_CONFIGURACOES')) {
        toastStore.send({
          message: 'Você não possui permissão para acessar este recurso.',
          style: 'warning'
        });

        return { name: 'dashboard' };
      }

      return true;
    }
  },

  // Fallback genérico para rotas não encontradas
  {
    path: '/:pathMatch(.*)*',
    redirect: '/'
  }
];

const router = createRouter({
  history: createWebHistory(),
  routes
});

router.beforeEach((to, from) => {
  const defaultTitle = import.meta.env.VITE_APP_NAME;
  document.title = to.meta?.title ? `${to.meta.title} | ${import.meta.env.VITE_APP_NAME}` : defaultTitle;

  const authStore = useAuthStore();
  const toastStore = useToastStore();
  const isAuth = authStore.isAuthenticated;
  const user = authStore.user;

  // 1. O usuário está tentando acessar uma rota protegida sem estar logado
  if (to.meta.requiresAuth && !isAuth) {
    return { name: 'login' };
  }

  // 2. O usuário já está autenticado, mas tentou acessar a tela de Login (ou rotas de visitante)
  if (to.meta.guestOnly && isAuth) {
    return { name: 'dashboard' };
  }

  // 3. Verificações de segurança (MFA e Senha) para usuários autenticados
  // O "to.name !== 'security'" é vital para não causar um loop infinito de redirecionamento.
  if (isAuth && to.name !== 'security') {

    // Required: Troca de senha
    if (user?.change_password_required) {
      toastStore.send({
        message: `É necessário alterar sua senha para acessar o sistema.`,
        style: 'warning',
      });

      return { name: 'security' };
    }

    // Required: Verificação de MFA
    if (user?.mfa_required && !user?.mfa_enabled) {
      toastStore.send({
        message: 'A ativação do MFA é obrigatório para o acesso a esta conta.',
        style: 'warning',
      });

      return { name: 'security' };
    }
  }

  // 4. Tudo certo, o fluxo segue normalmente
  return true;
});

export default router;