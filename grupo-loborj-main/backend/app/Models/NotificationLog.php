<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

#[Fillable(['title', 'body', 'resource', 'resource_id', 'action'])]
class NotificationLog extends Model
{
    public function userNotifications(): HasMany
    {
        return $this->hasMany(UserNotification::class);
    }
}
