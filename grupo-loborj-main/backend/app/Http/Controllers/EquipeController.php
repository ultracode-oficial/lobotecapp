<?php

namespace App\Http\Controllers;

use App\Http\Requests\DeleteEquipeRequest;
use App\Models\Equipe;
use App\Http\Requests\EquipeRequest;
use Illuminate\Http\Request;
use OwenIt\Auditing\Facades\Auditor;

class EquipeController extends Controller
{
    public function index(Request $request)
    {
        $query = Equipe::with('users'); // Carrega os usuários da equipe

        if ($request->filled('search')) {
            $query->where('name', 'like', "%{$request->search}%");
        }

        return $query->paginate($request->input('per_page', 15));
    }

    public function store(EquipeRequest $request)
    {
        $equipe = Equipe::create($request->validated());

        if ($request->has('users')) {
            $equipe->users()->sync($request->users);
        }

        return response()->json(['data' => $equipe->load('users')], 201);
    }

    public function show(Equipe $equipe)
    {
        return response()->json(['data' => $equipe->load('users')]);
    }

    public function update(EquipeRequest $request, Equipe $equipe)
    {
        $equipe->update($request->validated());

        if ($request->has('users')) {
            $changes = $equipe->users()->sync($request->users);

            if (!empty($changes['attached']) || !empty($changes['detached'])) {
                $equipe->auditEvent = 'sync_usuarios';
                $equipe->isCustomEvent = true;
                $equipe->audit_old = empty($changes['detached']) ? [] : ['usuarios_removidos' => $changes['detached']];
                $equipe->audit_new = empty($changes['attached']) ? [] : ['usuarios_adicionados' => $changes['attached']];
                Auditor::execute($equipe);
            }
        }

        return response()->json(['data' => $equipe->load('users')]);
    }

    public function destroy(DeleteEquipeRequest $request, Equipe $equipe)
    {
        $equipe->delete();
        return response()->noContent();
    }
}