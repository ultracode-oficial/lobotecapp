<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;
use OwenIt\Auditing\Contracts\Auditable;

#[Fillable('cliente_id', 'tipo_equipamento_id', 'is_generic', 'tag', 'localizacao', 'marca', 'modelo', 'btu', 'evaporadora', 'condensadora', 'observacoes')]
class Equipamento extends Model implements Auditable
{
    use \OwenIt\Auditing\Auditable, SoftDeletes;

    public function tipoEquipamento(): BelongsTo
    {
        return $this->belongsTo(TipoEquipamento::class);
    }
    public function cliente(): BelongsTo
    {
        return $this->belongsTo(Cliente::class);
    }
    // public function servicos(): BelongsToMany
    // {

    // }
    // public function etapas(): BelongsToMany
    // {

    // }
    // public function contratos(): BelongsToMany
    // {

    // }
    // public function checklists(): HasMany
    // {

    // }
}