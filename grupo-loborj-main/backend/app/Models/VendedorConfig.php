<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use OwenIt\Auditing\Contracts\Auditable;

#[Fillable(['tipo_comissao', 'porcentagem_comissao', 'valor_fixo_comissao_centavos', 'user_id'])]
class VendedorConfig extends Model implements Auditable
{
    use \OwenIt\Auditing\Auditable;

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
