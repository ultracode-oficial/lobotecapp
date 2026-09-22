<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\Table;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;

#[Table('especializacaos')]
#[Fillable(['name', 'description'])]
class Especializacao extends Model
{
    public function users(): BelongsToMany
    {
        return $this->belongsToMany(User::class, 'especializacao_user');
    }
}
