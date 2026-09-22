<?php

namespace App\Services;

use App\Models\NotificationLog;
use App\Models\UserNotification;
use App\Events\NotificationDispatched;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

class SendNotificationService
{
  /**
   * Despacha uma notificação para múltiplos usuários (Fan-out on Write).
   */
  public function send(
    array $userIds,
    string $title,
    string $body,
    string $resource,
    string $resourceId,
    string $action
  ): void {
    if (empty($userIds)) {
      return;
    }

    DB::transaction(function () use ($userIds, $title, $body, $resource, $resourceId, $action) {
      // 1. Cria o log central
      $log = NotificationLog::create([
        'title' => $title,
        'body' => $body,
        'resource' => $resource,
        'resource_id' => $resourceId,
        'action' => $action,
      ]);

      $now = Carbon::now();

      // 2. Prepara o array para Bulk Insert na tabela pivot
      $pivotData = array_map(fn($userId) => [
        'user_id' => $userId,
        'notification_log_id' => $log->id,
        'read_at' => null,
        'created_at' => $now,
        'updated_at' => $now,
      ], array_unique($userIds));

      // Insere em lote para alta performance
      UserNotification::insert($pivotData);

      // 3. Busca os registros recém criados para despachar os eventos
      $notifications = UserNotification::with('log')
        ->where('notification_log_id', $log->id)
        ->get();

      foreach ($notifications as $notification) {
        // Dispara o evento WebSockets para cada usuário
        broadcast(new NotificationDispatched($notification));
      }
    });
  }
}