<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;

#[Fillable('name', 'description')]
class TipoEquipamento extends Model
{
    // public function equipamentos(): BelongsToMany
    // {
    //     return $this->belongsToMany(Equipamento::class, 'tipo_equipamento_equipamento');
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
