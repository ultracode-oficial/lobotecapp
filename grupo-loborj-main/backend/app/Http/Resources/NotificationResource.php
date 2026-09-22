<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class NotificationResource extends JsonResource
{
    /**
     * Transforma a pivot table e a log table num formato client-agnostic limpo.
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'title' => $this->log->title,
            'body' => $this->log->body,
            'is_read' => !is_null($this->read_at),
            'read_at' => $this->read_at?->toIso8601String(),
            'created_at' => $this->created_at->toIso8601String(),

            // O payload de roteamento baseado em intenção
            'routing' => [
                'resource' => $this->log->resource,
                'resource_id' => $this->log->resource_id,
                'action' => $this->log->action,
            ]
        ];
    }
}
