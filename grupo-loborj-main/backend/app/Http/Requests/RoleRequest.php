<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;
use Spatie\Permission\Models\Role;

class RoleRequest extends FormRequest
{
    // Cargos do sistema que não podem ter o nome alterado
    protected array $systemRoles = [
        'FINANCEIRO',
        'ADMINISTRADOR',
        'VENDEDOR',
        'TÉCNICO',
        'REPRESENTANTE',
        'DESENVOLVEDOR'
    ];

    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        $role = $this->route('role');
        $roleId = is_object($role) ? $role->id : $role;

        $nameRules = [
            'required',
            'string',
            'max:255',
            Rule::unique('roles', 'name')->ignore($roleId),
            Rule::notIn(['DESENVOLVEDOR'])
        ];

        if ($roleId) {
            $currentRole = is_object($role) ? $role : Role::find($roleId);

            if ($currentRole && in_array($currentRole->name, $this->systemRoles)) {
                if ($this->input('name') !== $currentRole->name) {
                    $nameRules[] = 'prohibited';
                }
            }
        }

        return [
            'name' => $nameRules,
            'permissions' => ['present', 'array'],
            'permissions.*' => ['integer', 'exists:permissions,id'],
        ];
    }

    protected function prepareForValidation(): void
    {
        if ($this->filled('name')) {
            $this->merge(['name' => Str::upper($this->input('name'))]);
        }
    }

    public function messages(): array
    {
        return [
            // Nome
            'name.unique' => 'Já existe um cargo com este nome.',
            'name.required' => 'O campo nome é obrigatório.',
            'name.string' => 'O nome deve ser um texto válido.',
            'name.max' => 'O nome não pode ter mais de 255 caracteres.',
            'name.not_in' => 'Não é possível utilizar este nome de cargo protegido.',
            'name.prohibited' => 'Este é um cargo padrão do sistema e o seu nome não pode ser alterado.',

            // Permissões
            'permissions.present' => 'O formato das permissões é inválido.',
            'permissions.array' => 'O formato das permissões é inválido (deve ser um array).',
            'permissions.*.integer' => 'A permissão informada deve ser um número inteiro.',
            'permissions.*.exists' => 'A permissão selecionada não existe no sistema.',
        ];
    }
}