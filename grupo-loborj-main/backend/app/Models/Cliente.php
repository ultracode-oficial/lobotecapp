<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;
use OwenIt\Auditing\Contracts\Auditable;

#[Fillable('razao_social', 'cnpj', 'nome_fantasia', 'observacoes', 'email', 'phone', 'nome_representante', 'cep', 'logradouro', 'numero_logradouro', 'complemento', 'bairro', 'municipio', 'uf', 'lat', 'lng', 'creator_id', 'vendedor_id')]
class Cliente extends Model implements Auditable
{
    use \OwenIt\Auditing\Auditable, SoftDeletes;

    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'creator_id');
    }
    public function vendedor(): BelongsTo
    {
        return $this->belongsTo(User::class, 'vendedor_id');
    }
    public function equipamentos(): HasMany
    {
        return $this->hasMany(Equipamento::class);
    }
    // public function servicos(): HasMany
    // {

    // }
    // public function contratos(): HasMany
    // {

    // }
}
