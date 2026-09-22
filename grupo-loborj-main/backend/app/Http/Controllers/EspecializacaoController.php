<?php

namespace App\Http\Controllers;

use App\Http\Requests\DeleteEspecializacaoRequest;
use App\Http\Requests\EspecializacaoRequest;
use App\Models\Especializacao;
use Illuminate\Http\Request;

class EspecializacaoController extends Controller
{
    public function especializacaoOptions()
    {
        return Especializacao::select('id', 'name')->get();
    }

    public function index(Request $request)
    {
        $query = Especializacao::withCount('users'); // Carrega os usuários da especializacao

        if ($request->filled('search')) {
            $query->where('name', 'like', "%{$request->search}%");
        }

        return $query->paginate($request->input('per_page', 15));
    }

    public function store(EspecializacaoRequest $request)
    {
        $especializacao = Especializacao::create($request->validated());

        return response()->json(['data' => $especializacao->load('users')], 201);
    }

    public function show(Especializacao $especializacao)
    {
        return response()->json(['data' => $especializacao->load('users')]);
    }

    public function update(EspecializacaoRequest $request, Especializacao $especializacao)
    {
        $especializacao->update($request->validated());

        return response()->json(['data' => $especializacao->load('users')]);
    }

    public function destroy(DeleteEspecializacaoRequest $request, Especializacao $especializacao)
    {
        $especializacao->delete();
        return response()->noContent();
    }
}
