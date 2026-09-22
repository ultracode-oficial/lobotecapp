<?php

namespace App\Http\Controllers;

use App\Models\User;
use App\Services\SendNotificationService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class TestNotificationController extends Controller
{
    // O Laravel resolve automaticamente o serviço pelo Container de Serviços
    public function __construct(
        protected SendNotificationService $notificationService
    ) {
    }

    /**
     * Simula a aprovação de uma Ordem de Serviço de Ar-Condicionado.
     */
    public function finishService(int $id): JsonResponse
    {
        // 1. Executa a lógica de finalização...
        // $serviceOrder = ServiceOrder::findOrFail($id);
        // $serviceOrder->update(['status' => 'FINISHED']);

        // ====================================================================
        // CASO 1: Enviar Notificação Individual (Para o Técnico da O.S.)
        // ====================================================================
        $tecnicoId = auth()->user()->id;

        $this->notificationService->send(
            userIds: [$tecnicoId], // Passado como array de um único elemento
            title: '[User] Ordem de Serviço Finalizada',
            body: "A O.S. #CODIGO_OS para o cliente #NOME_CLIENTE foi finalizada.",
            resource: 'SERVICOS',
            resourceId: 123,
            action: 'CHECK'
        );

        // ====================================================================
        // CASO 2: Enviar Notificação para Role 'ADMINISTRADOR' (Spatie)
        // ====================================================================
        $adminIds = User::role('ADMINISTRADOR')->pluck('id')->toArray();

        // O serviço está preparado para fazer Bulk Insert se houver múltiplos admins
        $this->notificationService->send(
            userIds: $adminIds,
            title: '[Administrador] Ordem de Serviço Finalizada',
            body: "A O.S. #CODIGO_OS para o cliente #NOME_CLIENTE foi finalizada.",
            resource: 'SERVICOS',
            resourceId: 123,
            action: 'CHECK'
        );

        return response()->json([
            'success' => true,
            'message' => 'Ordem de serviço finalizada e notificações enviadas com sucesso.'
        ]);
    }
}
