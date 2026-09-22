<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\SoftDeletes;
use OwenIt\Auditing\Contracts\Auditable;

#[Fillable('name', 'description')]
class Equipe extends Model implements Auditable
{
    use \OwenIt\Auditing\Auditable, SoftDeletes;

    public function users(): BelongsToMany
    {
        return $this->belongsToMany(User::class, 'equipe_user');
    }

    /**
     * Intercepta a auditoria antes de salvar no banco para injetar nossos dados customizados
     */
    public function transformAudit(array $data): array
    {
        // Se for o nosso evento customizado do controller, injetamos os arrays de IDs
        if ($this->auditEvent === 'sync_usuarios') {
            $data['old_values'] = $this->audit_old ?? [];
            $data['new_values'] = $this->audit_new ?? [];
        }

        return $data;
    }
}
