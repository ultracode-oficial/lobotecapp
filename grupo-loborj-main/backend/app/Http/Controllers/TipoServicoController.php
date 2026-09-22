<?php

namespace App\Http\Controllers;

use App\Http\Requests\TipoServicoRequest;
use App\Models\TipoServico;
use Illuminate\Http\Request;

class TipoServicoController extends Controller
{
    public function tipoServicoOptions()
    {
        return TipoServico::select('id', 'name')->get();
    }

    public function index(Request $request)
    {
        $query = TipoServico::query(); // Carrega os usuários da tipoServico

        if ($request->filled('search')) {
            $query->where('name', 'like', "%{$request->search}%");
        }

        return $query->paginate($request->input('per_page', 15));
    }

    public function store(TipoServicoRequest $request)
    {
        $tipoServico = TipoServico::create($request->validated());

        return response()->json(['data' => $tipoServico], 201);
    }

    public function show(TipoServico $tipoServico)
    {
        return response()->json(['data' => $tipoServico]);
    }

    public function update(TipoServicoRequest $request, TipoServico $tipoServico)
    {
        $tipoServico->update($request->validated());

        return response()->json(['data' => $tipoServico]);
    }

    public function destroy(TipoServico $tipoServico)
    {
        $tipoServico->delete();
        return response()->noContent();
    }
}
