<?php

namespace App\Events;

use App\Models\UserNotification;
use App\Http\Resources\NotificationResource;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class NotificationDispatched implements ShouldBroadcastNow
{
    use Dispatchable, SerializesModels;

    public function __construct(
        public readonly UserNotification $userNotification
    ) {
    }

    public function broadcastOn(): array
    {
        return [
            new PrivateChannel('user.' . $this->userNotification->user_id),
        ];
    }

    public function broadcastAs(): string
    {
        return 'NotificationReceived';
    }

    /**
     * Retorna exatamente a mesma estrutura da API REST via WebSocket
     */
    public function broadcastWith(): array
    {
        // Carrega a relação para garantir que o Resource funcione
        $this->userNotification->load('log');

        return (new NotificationResource($this->userNotification))->resolve();
    }
}