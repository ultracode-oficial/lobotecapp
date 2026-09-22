<?php

namespace App\Http\Controllers;

use App\Http\Requests\TipoTarefaRequest;
use App\Models\TipoTarefa;
use Illuminate\Http\Request;

class TipoTarefaController extends Controller
{
    public function tipoTarefaOptions()
    {
        return TipoTarefa::select('id', 'name')->get();
    }

    public function index(Request $request)
    {
        $query = TipoTarefa::query(); // Carrega os usuários da tipoTarefa

        if ($request->filled('search')) {
            $query->where('name', 'like', "%{$request->search}%");
        }

        return $query->paginate($request->input('per_page', 15));
    }

    public function store(TipoTarefaRequest $request)
    {
        $tipoTarefa = TipoTarefa::create($request->validated());

        return response()->json(['data' => $tipoTarefa], 201);
    }

    public function show(TipoTarefa $tipoTarefa)
    {
        return response()->json(['data' => $tipoTarefa]);
    }

    public function update(TipoTarefaRequest $request, TipoTarefa $tipoTarefa)
    {
        $tipoTarefa->update($request->validated());

        return response()->json(['data' => $tipoTarefa]);
    }

    public function destroy(TipoTarefa $tipoTarefa)
    {
        $tipoTarefa->delete();
        return response()->noContent();
    }
}
