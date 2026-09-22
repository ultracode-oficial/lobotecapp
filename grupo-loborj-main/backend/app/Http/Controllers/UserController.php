<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreUserRequest;
use App\Http\Requests\UpdateUserRequest;
use App\Http\Resources\UserResource;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Spatie\Permission\Models\Permission;
use Spatie\Permission\Models\Role;

class UserController extends Controller
{
    public function index(Request $request)
    {
        $query = User::with(['roles', 'permissions', 'especializacoes', 'vendedorConfig']);

        // --- FILTROS ---
        // Busca textual global (Nome, Email, CPF, Telefone)
        if ($search = $request->input('search')) {
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                    ->orWhere('email', 'like', "%{$search}%")
                    ->orWhere('cpf', 'like', "%{$search}%")
                    ->orWhere('phone', 'like', "%{$search}%");
            });
        }

        // Filtro por Perfil (Role Spatie)
        if ($roles = $request->input('roles')) {
            $query->role($roles);
        }

        // Filtro por Status (Ativo / Desativado via SoftDeletes)
        if ($status = $request->input('status')) {
            if ($status === 'all') {
                $query->withTrashed();
            } elseif ($status === 'disabled') {
                $query->onlyTrashed();
            } elseif ($status === 'enabled') {
                $query->whereNull('deleted_at');
            }
        }

        // Filtro por Configurações de Conta (MFA e Troca Obrigatória de Senha)
        if ($request->has('mfa_enabled')) {
            $query->where('mfa_enabled', $request->boolean('mfa_enabled'));
        }
        if ($request->has('change_password_required')) {
            $query->where('change_password_required', $request->boolean('change_password_required'));
        }

        // Filtro por Especialização específica
        if ($especializacaoId = $request->input('especializacao_id')) {
            $query->whereHas('especializacoes', function ($q) use ($especializacaoId) {
                $q->where('especializacoes.id', $especializacaoId);
            });
        }

        // --- ORDENAÇÃO ---
        $allowedSorts = ['name', 'email', 'created_at', 'status'];
        $sort = $request->input('sort_by', 'created_at');
        $direction = $request->input('sort_dir', 'desc');

        if (in_array($sort, $allowedSorts)) {
            if ($sort === 'status') {
                // Ordenação customizada para SoftDeletes (Registros ativos primeiro)
                $query->orderByRaw('deleted_at IS NULL DESC');
            } else {
                $query->orderBy($sort, $direction === 'asc' ? 'asc' : 'desc');
            }
        }

        // --- Paginação
        $perPage = $request->integer('per_page', 15);
        $users = $query->paginate($perPage);

        return UserResource::collection($users);
    }

    public function store(StoreUserRequest $request)
    {
        return DB::transaction(function () use ($request) {
            $data = $request->validated();
            // $data['password'] = Hash::make($data['password']);
            // $data['change_password_required'] = true; // Força troca no primeiro login B2B

            // Remove 'is_developer' caso tenha sido enviado no payload bruto e força como false
            $userData = collect($data)->except(['roles', 'permissions', 'is_developer'])->toArray();
            $userData['is_developer'] = false;
            $userData['password'] = $data['password'];

            // Cria o registro (o Global Scope o protegerá de listagens automaticamente)
            $user = User::create($userData);

            // Sincroniza acessos
            $filteredRoles = array_filter($data['roles'], function ($role) {
                return $role !== 'DESENVOLVEDOR';
            });

            $user->syncRoles($filteredRoles);
            $user->syncPermissions($data['permissions']);

            // Sincroniza Especializações
            $user->especializacoes()->sync($data['especializacoes'] ?? []);

            // Cria regras de vendedor condicionalmente
            $hasVendedorRole = count(array_intersect(['VENDEDOR', 'REPRESENTANTE'], $data['roles'])) > 0;
            if ($hasVendedorRole && isset($data['vendedor_config'])) {
                $user->vendedorConfig()->create($data['vendedor_config']);
            }

            return response()->json([
                'message' => 'Usuário criado com sucesso!',
                'data' => new UserResource($user->load(['roles', 'permissions', 'especializacoes', 'vendedorConfig'])),
            ], 210);
        });
    }

    public function show(User $user)
    {
        return new UserResource($user->load(['roles', 'permissions', 'especializacoes', 'vendedorConfig']));
    }

    public function update(UpdateUserRequest $request, int $id)
    {
        // Encontra o usuário permitindo inclusive os desativados para reativação cadastral
        $user = User::withTrashed()->findOrFail($id);

        return DB::transaction(function () use ($request, $user) {
            $data = $request->validated();

            if (!empty($data['password'])) {
                $data['password'] = Hash::make($data['password']);
            } else {
                unset($data['password']);
            }

            $user->update($data);

            // Atualiza acessos
            $filteredRoles = array_filter($data['roles'], function ($role) {
                return $role !== 'DESENVOLVEDOR';
            });
            $user->syncRoles($filteredRoles);
            $user->syncPermissions($data['permissions'] ?? []);

            // Atualiza Especializações
            $user->especializacoes()->sync($data['especializacoes'] ?? []);

            // Controla a persistência da configuração de Vendedor de acordo com o Perfil
            $hasVendedorRole = count(array_intersect(['VENDEDOR', 'REPRESENTANTE'], $data['roles'])) > 0;
            if ($hasVendedorRole && isset($data['vendedor_config'])) {
                $user->vendedorConfig()->updateOrCreate([], $data['vendedor_config']);
            } else {
                // Se a role mudou e ele deixou de ser vendedor, removemos as configurações órfãs
                $user->vendedorConfig()->delete();
            }

            return response()->json([
                'message' => 'Usuário atualizado com sucesso!',
                'data' => new UserResource($user->load(['roles', 'permissions', 'especializacoes', 'vendedorConfig']))
            ]);
        });
    }

    public function destroy(User $user)
    {
        $user->delete();

        return response()->json([
            'message' => 'Usuário desativado com sucesso do sistema.'
        ]);
    }

    public function restore(int $id)
    {
        // Reativação cadastral de um usuário excluído logicamente
        $user = User::onlyTrashed()->findOrFail($id);
        $user->restore();

        return response()->json([
            'message' => 'Usuário reativado com sucesso.',
            'data' => new UserResource($user)
        ]);
    }
}