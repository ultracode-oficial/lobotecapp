<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class EspecializacaoRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true; // Use suas permissões (Gate) aqui se necessário
    }

    public function rules(): array
    {
        $especializacaoId = $this->route('especializacao');
        $str = isset($especializacaoId) ? ",$especializacaoId->id" : "";

        return [
            'name' => ['required', 'string', 'max:255', "unique:especializacaos,name$str"],
            'description' => ['nullable', 'string']
        ];
    }

    public function messages(): array
    {
        return [
            // Nome
            'name.unique' => 'Já existe uma especialização com este nome.',
            'name.required' => 'O campo nome é obrigatório.',
            'name.string' => 'O nome deve ser um texto válido.',
            'name.max' => 'O nome não pode ter mais de 255 caracteres.',
        ];
    }
}