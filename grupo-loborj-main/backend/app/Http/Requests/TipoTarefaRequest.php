<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class TipoTarefaRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true; // Use suas permissões (Gate) aqui se necessário
    }

    public function rules(): array
    {
        $tipoTarefaId = $this->route('tipoTarefa');
        $str = isset($tipoTarefaId) ? ",$tipoTarefaId->id" : "";

        return [
            'name' => ['required', 'string', 'max:255', "unique:tipo_tarefas,name$str"],
            'recurrence_days' => ['nullable', 'numeric', 'min:1'],
            'description' => ['nullable', 'string']
        ];
    }

    public function messages(): array
    {
        return [
            // Nome
            'name.unique' => 'Já existe um tipo de tarefa com este nome.',
            'name.required' => 'O campo nome é obrigatório.',
            'name.string' => 'O nome deve ser um texto válido.',
            'name.max' => 'O nome não pode ter mais de 255 caracteres.',

            // Recorrência Sugerida
            'recurrence_days.required' => 'O campo de retorno indicado é obrigatório.',
            'recurrence_days.numeric' => 'O período de retorno deve ser um número válido.',
            'recurrence_days.min' => 'O período de retorno deve ser maior que zero (0).',
        ];
    }

    protected function prepareForValidation()
    {
        if ($this->recurrence_days == 0) {
            $this->merge(['recurrence_days' => null]);
        }
    }
}