<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class TipoServicoRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true; // Use suas permissões (Gate) aqui se necessário
    }

    public function rules(): array
    {
        $tipoServicoId = $this->route('tipoServico');
        $str = isset($tipoServicoId) ? ",$tipoServicoId->id" : "";

        return [
            'name' => ['required', 'string', 'max:255', "unique:tipo_servicos,name$str"],
            'description' => ['nullable', 'string']
        ];
    }

    public function messages(): array
    {
        return [
            // Nome
            'name.unique' => 'Já existe um tipo de serviço com este nome.',
            'name.required' => 'O campo nome é obrigatório.',
            'name.string' => 'O nome deve ser um texto válido.',
            'name.max' => 'O nome não pode ter mais de 255 caracteres.',
        ];
    }
}