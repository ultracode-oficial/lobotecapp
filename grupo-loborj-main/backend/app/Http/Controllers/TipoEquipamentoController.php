<?php

namespace App\Http\Controllers;

use App\Http\Requests\TipoEquipamentoRequest;
use App\Models\TipoEquipamento;
use Illuminate\Http\Request;

class TipoEquipamentoController extends Controller
{
    public function tipoEquipamentoOptions()
    {
        return TipoEquipamento::select('id', 'name')->get();
    }

    public function index(Request $request)
    {
        $query = TipoEquipamento::query(); // Carrega os usuários da tipoEquipamento

        if ($request->filled('search')) {
            $query->where('name', 'like', "%{$request->search}%");
        }

        return $query->paginate($request->input('per_page', 15));
    }

    public function store(TipoEquipamentoRequest $request)
    {
        $tipoEquipamento = TipoEquipamento::create($request->validated());

        return response()->json(['data' => $tipoEquipamento], 201);
    }

    public function show(TipoEquipamento $tipoEquipamento)
    {
        return response()->json(['data' => $tipoEquipamento]);
    }

    public function update(TipoEquipamentoRequest $request, TipoEquipamento $tipoEquipamento)
    {
        $tipoEquipamento->update($request->validated());

        return response()->json(['data' => $tipoEquipamento]);
    }

    public function destroy(TipoEquipamento $tipoEquipamento)
    {
        $tipoEquipamento->delete();
        return response()->noContent();
    }
}
