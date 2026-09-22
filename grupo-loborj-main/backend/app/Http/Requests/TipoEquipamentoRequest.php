<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class TipoEquipamentoRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true; // Use suas permissões (Gate) aqui se necessário
    }

    public function rules(): array
    {
        $tipoEquipamentoId = $this->route('tipoEquipamento');
        $str = isset($tipoEquipamentoId) ? ",$tipoEquipamentoId->id" : "";

        return [
            'name' => ['required', 'string', 'max:255', "unique:tipo_equipamentos,name$str"],
            'description' => ['nullable', 'string']
        ];
    }

    public function messages(): array
    {
        return [
            // Nome
            'name.unique' => 'Já existe um tipo de equipamento com este nome.',
            'name.required' => 'O campo nome é obrigatório.',
            'name.string' => 'O nome deve ser um texto válido.',
            'name.max' => 'O nome não pode ter mais de 255 caracteres.',
        ];
    }
}