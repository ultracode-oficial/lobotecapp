<?php

namespace App\Auth;

use Illuminate\Auth\EloquentUserProvider;
use Illuminate\Contracts\Auth\Authenticatable;

class CustomEloquentUserProvider extends EloquentUserProvider
{
  /**
   * Retrieve a user by their unique identifier.
   */
  public function retrieveById($identifier)
  {
    $model = $this->createModel();

    return $model->newQuery()
      ->withoutGlobalScopes() // Bypasses all global scopes
      ->where($model->getAuthIdentifierName(), $identifier)
      ->first();
  }

  /**
   * Retrieve a user by the given credentials.
   */
  public function retrieveByCredentials(array $credentials)
  {
    if (empty($credentials) || (count($credentials) === 1 && array_key_exists('password', $credentials))) {
      return null;
    }

    $query = $this->createModel()->newQuery()->withoutGlobalScopes(); // Bypasses all global scopes

    foreach ($credentials as $key => $value) {
      if (str_contains($key, 'password')) {
        continue;
      }

      if (is_array($value) || $value instanceof \Illuminate\Contracts\Support\Arrayable) {
        $query->whereIn($key, $value);
      } else {
        $query->where($key, $value);
      }
    }

    return $query->first();
  }
}
