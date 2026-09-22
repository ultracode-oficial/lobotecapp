<?php

namespace App\Models\Scopes;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Scope;

class HideDevelopersScope implements Scope
{
  public function apply(Builder $builder, Model $model): void
  {
    // Força todas as queries a buscarem apenas quem NÃO é desenvolvedor
    $builder->where('is_developer', false);
  }
}