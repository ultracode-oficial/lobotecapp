import type { RouteLocationRaw } from 'vue-router';

export interface NotificationRouting {
  resource: string;
  resource_id: string;
  action: string;
}

/**
 * Função pura que traduz intenções do Backend para rotas concretas do Vue Router.
 */
export function resolveNotificationRoute(routing: NotificationRouting): RouteLocationRaw {
  const { resource, resource_id, action } = routing;

  switch (resource) {
    case 'SERVICO':
      return {
        name: 'servicos.show',
        params: { id: resource_id },
        query: action ? { action: action.toLowerCase() } : undefined
      };

    case 'CONTRATO':
      return {
        name: 'contratos.show',
        params: { id: resource_id }
      };

    case 'ESTOQUE':
      if (action === 'VIEW_STOCK') {
        return {
          name: 'estoque.itens.show',
          params: { id: resource_id }
        };
      }
      return { name: 'estoque.index' };

    default:
      // Fallback seguro caso um recurso novo seja adicionado no backend antes do frontend ser atualizado
      console.warn(`Recurso de notificação desconhecido: ${resource}`);
      return { name: 'dashboard' };
  }
}