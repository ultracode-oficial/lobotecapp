<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;

#[Fillable('name', 'recurrence_days', 'description')]
class TipoTarefa extends Model
{
    // public function tarefas(): BelongsToMany
    // {
    //     return $this->belongsToMany(Tarefa::class, 'tipo_tarefa_tarefa');
    // }

    // public function etapas(): BelongsToMany
    // {
    //     return $this->belongsToMany(Etapa::class, '?');
    // }

    // public function servicos(): BelongsToMany
    // {
    //     return $this->belongsToMany(Servico::class, '?');
    // }

    // public function contratos(): BelongsToMany
    // {
    //     return $this->belongsToMany(Contrato::class, '?');
    // }

    // public function clientes(): BelongsToMany
    // {
    //     return $this->belongsToMany(Cliente::class, '?');
    // }
}
