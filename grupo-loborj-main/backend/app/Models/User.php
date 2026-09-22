<?php

namespace App\Models;

// use Illuminate\Contracts\Auth\MustVerifyEmail;

use App\Models\Scopes\HideDevelopersScope;
use Database\Factories\UserFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\Hidden;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasManyThrough;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use OwenIt\Auditing\Contracts\Auditable;
use PHPOpenSourceSaver\JWTAuth\Contracts\JWTSubject;
use Spatie\Permission\Traits\HasRoles;

#[Fillable(['name', 'email', 'cpf', 'phone', 'photo', 'bio', 'password', 'mfa_secret', 'mfa_enabled', 'mfa_required', 'mfa_recovery_code', 'change_password_required', 'deleted_at', 'updated_at'])]
#[Hidden(['password', 'remember_token'])]
class User extends Authenticatable implements JWTSubject, Auditable
{
    /** @use HasFactory<UserFactory> */
    use HasFactory, Notifiable, HasRoles, SoftDeletes, \OwenIt\Auditing\Auditable;

    protected static function booted(): void
    {
        // Ativa a invisibilidade global do usuário
        static::addGlobalScope(new HideDevelopersScope);

        // Bloqueia qualquer tentativa de alteração via aplicação/API
        static::updating(function ($user) {
            if ($user->getOriginal('is_developer') || $user->is_developer) {
                abort(403, 'Usuários desenvolvedores não podem ser modificados pela interface.');
            }
        });

        // Bloqueia qualquer tentativa de exclusão via aplicação/API
        static::deleting(function ($user) {
            if ($user->is_developer) {
                abort(403, 'Usuários desenvolvedores não podem ser excluídos do sistema.');
            }
        });
    }

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
        ];
    }

    /**
     * Get the identifier that will be stored in the subject claim of the JWT.
     *
     * @return mixed
     */
    public function getJWTIdentifier()
    {
        return $this->getKey();
    }

    /**
     * Injeta as roles e permissões dentro do Token JWT.
     * Quando o token for "refreshado", essa lista será atualizada.
     */
    public function getJWTCustomClaims()
    {
        // $path_file_storage = config('app.filestorage_path');

        $userData = [
            'id' => $this->id,
            // 'name' => $this->name,
            // 'email' => $this->email,
            // 'cpf' => $this->cpf,
            // 'phone' => $this->phone,
            // 'photo' => $this->photo ? $path_file_storage . $this->photo : null,
            'is_developer' => $this->is_developer ? true : false,
        ];

        return [
            'user' => $userData,
            'roles' => $this->getRoleNames(),
            'permissions' => $this->getAllPermissions()->pluck('name'),
        ];
    }

    /**
     * Relacionamento 1:N com as entregas individuais de notificações (Tabela Pivot/Filtro).
     * Permite obter os registros de leitura de forma direta.
     *
     * @return HasMany
     */
    public function notifications(): HasMany
    {
        return $this->hasMany(UserNotification::class);
    }

    /**
     * Relacionamento N:N indireto (HasManyThrough) com a tabela central de logs.
     * Permite obter os payloads e intenções originais das notificações do usuário diretamente.
     *
     * @return HasManyThrough
     */
    public function notificationLogs(): HasManyThrough
    {
        return $this->hasManyThrough(
            NotificationLog::class,
            UserNotification::class,
            'user_id',             // Chave estrangeira em user_notifications apontando para users
            'id',                  // Chave primária em notification_logs
            'id',                  // Chave primária em users
            'notification_log_id'  // Chave estrangeira em user_notifications apontando para notification_logs
        );
    }

    /**
     * Escopo auxiliar para buscar apenas as notificações pendentes (não lidas) do usuário.
     *
     * @return HasMany
     */
    public function unreadNotifications(): HasMany
    {
        return $this->notifications()->whereNull('read_at');
    }

    public function especializacoes(): BelongsToMany
    {
        return $this->belongsToMany(Especializacao::class, 'especializacao_user', 'user_id', 'especializacao_id');
    }

    public function vendedorConfig(): HasOne
    {
        return $this->hasOne(VendedorConfig::class);
    }

    public function equipes(): BelongsToMany
    {
        return $this->belongsToMany(Equipe::class, 'equipe_user');
    }

    public function clientes(): BelongsToMany
    {
        return $this->belongsToMany(Cliente::class);
    }
}
