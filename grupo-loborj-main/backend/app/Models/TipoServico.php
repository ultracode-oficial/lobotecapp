<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;

#[Fillable('name', 'description')]
class TipoServico extends Model
{
    // public function servicos(): BelongsToMany
    // {
    //     return $this->belongsToMany(Servico::class, 'tipo_servico_servico');
    // }
    // public function contratos(): BelongsToMany
    // {
    //     return $this->belongsToMany(Contrato::class, 'tipo_servico_contrato');
    // }
}
