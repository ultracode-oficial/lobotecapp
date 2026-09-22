<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class UserResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'email' => $this->email,
            'cpf' => $this->cpf,
            'phone' => $this->phone,
            'bio' => $this->bio,
            'photo' => $this->photo ? config('app.filestorage_path') . $this->photo : null,
            'mfa_enabled' => (bool) $this->mfa_enabled,
            'mfa_required' => (bool) $this->mfa_required,
            'change_password_required' => (bool) $this->change_password_required,
            'is_active' => !$this->trashed(),
            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),

            // Relacionamentos carregados sob demanda ou carregamento padrão
            'roles' => $this->getRoleNames(),
            'permissions' => $this->getDirectPermissions()->pluck('name'),
            'especializacoes' => $this->relationLoaded('especializacoes')
                ? $this->especializacoes->map(fn($e) => ['id' => $e->id, 'nome' => $e->nome])
                : [],
            'vendedor_config' => $this->relationLoaded('vendedorConfig') ? $this->vendedorConfig : null,
        ];
    }
}