<?php

namespace App\Http\Controllers;

use App\Http\Requests\DeleteRoleRequest;
use App\Http\Requests\RoleRequest;
use Illuminate\Http\Request;
use Spatie\Permission\Models\Permission;
use Spatie\Permission\Models\Role;

class RoleController extends Controller
{
    public function roleOptions()
    {
        return [
            'roles' => Role::whereNot('name', 'DESENVOLVEDOR')->orderBy('id')->get(),
            'permissions' => Permission::orderBy('id')->get()
        ];
    }

    public function index(Request $request)
    {
        $query = Role::with('permissions')->withCount('users')->whereNot('name', 'DESENVOLVEDOR');

        if ($request->filled('search')) {
            $query->where('name', 'like', "%{$request->search}%");
        }

        return $query->paginate($request->input('per_page', 15));
    }

    public function store(RoleRequest $request)
    {
        $data = $request->validated();

        $role = Role::create([
            "name" => $data['name'],
            'guard_name' => 'api'
        ]);

        if ($request->has('permissions')) {
            $role->syncPermissions($data['permissions']);
        }

        return response()->json(['data' => $role->load('permissions')], 201);
    }

    public function show(Role $role)
    {
        return response()->json(['data' => $role->load('permissions')]);
    }

    public function update(RoleRequest $request, Role $role)
    {
        $data = $request->validated();

        $role->update([
            'name' => $data['name'],
            'guard_name' => 'api'
        ]);

        if ($request->has('permissions')) {
            $role->syncPermissions($data['permissions']);
        }

        return response()->json(['data' => $role->load('permissions')]);
    }

    public function destroy(DeleteRoleRequest $request, Role $role)
    {
        $role->delete();
        return response()->noContent();
    }
}
