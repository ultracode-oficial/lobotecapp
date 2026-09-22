<?php

namespace App\Http\Controllers;

use App\Http\Requests\DeleteClienteRequest;
use App\Http\Requests\StoreClienteRequest;
use App\Http\Requests\UpdateClienteRequest;
use App\Models\Cliente;
use App\Models\Equipamento;
use App\Services\GeocodingService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class ClienteController extends Controller
{
    public function __construct(
        protected GeocodingService $geocodingService
    ) {
    }

    public function index(Request $request)
    {
        $query = Cliente::query();

        // Quando não tem permissão de gerência de clientes, vê apenas clientes aos quais o usuário é responsável.
        if (!auth()->user()->can('GERIR_CLIENTES')) {
            $query->where('vendedor_id', auth()->user()->id);
        }

        // --- FILTROS ---
        // Busca textual global (Nome, Email, CNPJ, Telefone)
        if ($search = $request->input('search')) {
            $query->where(function ($q) use ($search) {
                $q->where('razao_social', 'like', "%{$search}%")
                    ->orWhere('nome_fantasia', 'like', "%{$search}%")
                    ->orWhere('cnpj', 'like', "%{$search}%")
                    ->orWhere('email', 'like', "%{$search}%")
                    ->orWhere('phone', 'like', "%{$search}%");
            });
        }

        // --- ORDENAÇÃO ---
        $allowedSorts = ['razao_social', 'created_at'];
        $sort = $request->input('sort_by', 'created_at');
        $direction = $request->input('sort_dir', 'desc');

        if (in_array($sort, $allowedSorts)) {
            $query->orderBy($sort, $direction === 'asc' ? 'asc' : 'desc');
        }

        // --- Paginação
        $perPage = $request->integer('per_page', 15);
        $clientes = $query->paginate($perPage);

        return $clientes;
    }

    public function store(StoreClienteRequest $request)
    {
        return DB::transaction(function () use ($request) {
            $data = $request->validated();

            $clienteData = collect($data)->except(['equipamentos'])->toArray();

            if (
                array_all([
                    'cep',
                    'logradouro',
                    'numero_logradouro',
                    'bairro',
                    'municipio',
                    'uf',
                ], fn($e) => filled($e))
            ) {
                $result = $this->geocodingService->getLatLng([
                    'cep' => $data['cep'],
                    'logradouro' => $data['logradouro'],
                    'numero_logradouro' => $data['numero_logradouro'],
                    'bairro' => $data['bairro'],
                    'municipio' => $data['municipio'],
                    'uf' => $data['uf'],
                ]);

                if (isset($result)) {
                    $clienteData['lat'] = $result['lat'];
                    $clienteData['lng'] = $result['lng'];
                }
            }

            $clienteData['creator_id'] = auth()->user()->id;

            if (!isset($clienteData['vendedor_id'])) {
                $clienteData['vendedor_id'] = auth()->user()->hasRole(['VENDEDOR', 'REPRESENTANTE']) ? auth()->user()->id : null;
            }

            $cliente = Cliente::create($clienteData);

            $equipsArray = [];

            // criar equipamentos
            foreach ($data['equipamentos'] as $tipo_equipamento_id => $quantity) {
                for ($i = 0; $i < $quantity; $i++) {
                    $equipsArray[] = [
                        'cliente_id' => $cliente->id,
                        'tipo_equipamento_id' => $tipo_equipamento_id,
                        'is_generic' => true,
                    ];
                }
            }

            if (!empty($equipsArray)) {
                Equipamento::insert($equipsArray);
            }

            return response()->json([
                'message' => 'Cliente registrado com sucesso!',
                'data' => $cliente
            ], 210);
        });
    }

    public function show(Cliente $cliente)
    {
        return ['data' => $cliente->load(['equipamentos'])];
    }

    public function update(UpdateClienteRequest $request, Cliente $cliente)
    {
        return DB::transaction(function () use ($request, $cliente) {
            $data = $request->validated();

            if (!isset($data['vendedor_id'])) {
                $data['vendedor_id'] = auth()->user()->hasRole(['VENDEDOR', 'REPRESENTANTE']) ? auth()->user()->id : null;
            }

            $cliente->update($data);

            if (
                $cliente->wasChanged([
                    'cep',
                    'logradouro',
                    'numero_logradouro',
                    'bairro',
                    'municipio',
                    'uf',
                ])
            ) {
                $result = $this->geocodingService->getLatLng([
                    'cep' => $data['cep'],
                    'logradouro' => $data['logradouro'],
                    'numero_logradouro' => $data['numero_logradouro'],
                    'bairro' => $data['bairro'],
                    'municipio' => $data['municipio'],
                    'uf' => $data['uf'],
                ]);

                if (isset($result['lat'], $result['lng'])) {
                    $cliente->update($result);
                }
            };

            foreach ($data['equipamentos'] as $tipo_equipamento_id => $quantity) {
                $targetQuantity = isset($quantity) ? (int) $quantity : 0;

                $genericQuery = $cliente->equipamentos()
                    ->where('tipo_equipamento_id', $tipo_equipamento_id)
                    ->where('is_generic', true);

                $currentQuantity = $genericQuery->count();
                $diff = $targetQuantity - $currentQuantity;

                if ($diff > 0) {
                    // Cenário A: Criar novos registros
                    $newEquipments = array_fill(0, $diff, [
                        'tipo_equipamento_id' => $tipo_equipamento_id,
                        'is_generic' => true,
                    ]);

                    $cliente->equipamentos()->createMany($newEquipments);
                } elseif ($diff < 0) {
                    // Cenário B: Deletar excedentes
                    $amountToDelete = abs($diff);

                    $idsToDelete = $genericQuery->limit($amountToDelete)->pluck('id');
                    $cliente->equipamentos()->whereIn('id', $idsToDelete)->delete();
                } else {
                    // Cenário C: Nenhuma mudança necessária
                }
            }

            return response()->json([
                'message' => 'Cliente atualizado com sucesso!',
                'data' => $cliente
            ]);
        });
    }

    public function destroy(DeleteClienteRequest $request, Cliente $cliente)
    {
        $cliente->delete();

        return response()->json([
            'message' => 'Cliente excluído com sucesso.'
        ]);
    }
}
