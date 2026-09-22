<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use App\Models\User;
use Illuminate\Validation\Rule;

class EquipeRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true; // Use suas permissões (Gate) aqui se necessário
    }

    public function rules(): array
    {
        $equipeRoute = $this->route('equipe');
        $equipeId = $equipeRoute instanceof \App\Models\Equipe ? $equipeRoute->id : $equipeRoute;

        return [
            'name' => [
                'required',
                'string',
                'max:255',
                Rule::unique('equipes', 'name')
                    ->ignore($equipeId)
                    ->whereNull('deleted_at')
            ],
            'description' => ['nullable', 'string'],
            'users' => ['nullable', 'array'],
            'users.*' => [
                'exists:users,id',
                function ($attribute, $value, $fail) {
                    $user = User::find($value);
                    if ($user && !$user->hasRole('TÉCNICO')) {
                        $fail("O usuário selecionado ({$user->name}) não possui o perfil de TÉCNICO.");
                    }
                }
            ],
        ];
    }

    public function messages(): array
    {
        return [
            // Nome
            'name.unique' => 'Já existe uma equipe com este nome.',
            'name.required' => 'O campo nome é obrigatório.',
            'name.string' => 'O nome deve ser um texto válido.',
            'name.max' => 'O nome não pode ter mais de 255 caracteres.',

            // Técnicos (users)
            'users.array' => 'O formato dos membros é inválido (deve ser um array).',
            'users.*.id' => 'O membro informado é inválido.',
            'users.*.exists' => 'O membro selecionado não existe no sistema.',
        ];
    }
}