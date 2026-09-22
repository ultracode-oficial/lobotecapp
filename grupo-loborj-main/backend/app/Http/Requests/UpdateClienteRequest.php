<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateClienteRequest extends FormRequest
{
    public function authorize(): bool
    {
        $cliente = $this->route('cliente');

        if (auth()->user()->can('GERIR_CLIENTES')) {
            return true;
        }

        if (auth()->user()->id !== $cliente->user_id) {
            abort(response()->json(['message' => 'Você não possui permissão para editar este cliente.'], 401));
        }

        return true;
    }

    public function rules(): array
    {
        $clienteRoute = $this->route('cliente');
        $clienteId = $clienteRoute instanceof \App\Models\Cliente ? $clienteRoute->id : $clienteRoute;

        return [
            // Info
            'razao_social' => 'required|string|max:255',
            'nome_fantasia' => 'nullable|string|max:255',
            'cnpj' => [
                'required',
                'string',
                'size:14',
                'regex:/^[A-Z0-9]{12}[0-9]{2}$/',
                Rule::unique('clientes', 'cnpj')
                    ->ignore($clienteId)
                    ->whereNull('deleted_at') // Garante que só conflita com clientes ativos
            ],
            'observacoes' => 'nullable|string|max:1000',

            // Contato
            'email' => [
                'nullable',
                'email',
                Rule::unique('clientes', 'email')
                    ->ignore($clienteId)
                    ->whereNull('deleted_at')
            ],
            'phone' => [
                'nullable',
                'string',
                'min:10',
                'max:11',
                Rule::unique('clientes', 'phone')
                    ->ignore($clienteId)
                    ->whereNull('deleted_at')
            ],
            'nome_representante' => "nullable|string|max:255",

            // Equipamentos Genéricos
            'equipamentos' => 'present|array',
            'equipamentos.*' => 'nullable|integer',
            'equipamentos_ids.*' => 'integer|exists:tipo_equipamentos,id',

            // Vendedor Responsável
            'vendedor_id' => 'nullable|integer|exists:users,id',

            // Endereço
            'cep' => 'nullable|string|size:8',
            'logradouro' => 'nullable|string|max:255',
            'numero_logradouro' => 'nullable|string|max:20',
            'complemento' => 'nullable|string|max:255',
            'bairro' => 'nullable|string|max:100',
            'municipio' => 'nullable|string|max:100',
            'uf' => 'nullable|string|size:2',
            // 'lat' => 'nullable|numeric|between:-90,90',
            // 'lng' => 'nullable|numeric|between:-180,180',
        ];
    }

    protected function prepareForValidation(): void
    {
        if ($this->filled('cnpj')) {
            $cnpjLimpo = preg_replace('/[^A-Za-z0-9]/', '', $this->input('cnpj'));
            $this->merge(['cnpj' => strtoupper($cnpjLimpo)]);
        } else {
            $this->merge([
                'cnpj' => null,
            ]);
        }

        if ($this->filled('phone')) {
            $this->merge([
                'phone' => preg_replace('/\D/', '', $this->input('phone')),
            ]);
        } else {
            $this->merge([
                'phone' => null,
            ]);
        }

        if ($this->filled('cep')) {
            $this->merge([
                'cep' => preg_replace('/\D/', '', $this->input('cep')),
            ]);
        } else {
            $this->merge([
                'cep' => null,
            ]);
        }

        if ($this->has('equipamentos') && is_array($this->equipamentos)) {
            $equipamentosFormatados = array_map(function ($item) {
                if (isset($item['quantity']) && (int) $item['quantity'] <= 0) {
                    $item['quantity'] = null;
                }
                return $item;
            }, $this->equipamentos);

            $this->merge([
                'equipamentos' => $equipamentosFormatados,
            ]);
        }
    }

    public function messages(): array
    {
        return [
            // Regras Genéricas
            'required' => 'O campo :attribute é obrigatório.',
            'string' => 'O campo :attribute deve ser um texto válido.',
            'max' => 'O campo :attribute não pode ter mais de :max caracteres.',
            'min' => 'O campo :attribute deve ter pelo menos :min caracteres.',
            'size' => 'O campo :attribute deve ter exatamente :size caracteres.',
            'unique' => 'Este :attribute já está cadastrado no sistema.',
            'email' => 'Informe um endereço de e-mail válido.',
            'integer' => 'O campo :attribute deve ser um número inteiro.',
            'numeric' => 'O campo :attribute deve ser um número válido.',
            'between' => 'O campo :attribute deve estar entre :min e :max.',
            'array' => 'O formato do campo :attribute é inválido.',
            'present' => 'O campo :attribute deve estar presente na requisição.',

            // Validações Específicas / Relacionamentos
            'cnpj.regex' => 'O formato do CNPJ é inválido.',
            'cnpj.size' => 'O CNPJ deve ter exatamente 14 caracteres (letras e números).',
            'phone.min' => 'O telefone deve ter pelo menos 10 dígitos (com DDD).',
            'phone.max' => 'O telefone não pode ter mais de 11 dígitos.',

            // Equipamentos Asterisco (*)
            'equipamentos.*.tipo_equipamento_id.integer' => 'O ID do tipo de equipamento deve ser um número inteiro.',
            'equipamentos.*.tipo_equipamento_id.exists' => 'O tipo de equipamento selecionado não existe no sistema.',
            'equipamentos.*.quantity.integer' => 'A quantidade do equipamento deve ser um número inteiro.',
        ];
    }

    public function attributes(): array
    {
        return [
            'razao_social' => 'Razão Social',
            'nome_fantasia' => 'Nome Fantasia',
            'cnpj' => 'CNPJ',
            'observacoes' => 'Observações',
            'email' => 'E-mail',
            'phone' => 'Telefone',
            'nome_representante' => 'Nome do Representante',
            'equipamentos' => 'Equipamentos',
            'cep' => 'CEP',
            'logradouro' => 'Logradouro',
            'numero_logradouro' => 'Número',
            'complemento' => 'Complemento',
            'bairro' => 'Bairro',
            'municipio' => 'Município',
            'uf' => 'UF',
            // 'lat' => 'Latitude',
            // 'lng' => 'Longitude',
        ];
    }
}