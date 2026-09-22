<?php

namespace App\Http\Requests;

use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;

class DeleteRoleRequest extends FormRequest
{
    // Cargos do sistema que não podem ser excluídos
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
        $role = $this->route('role');

        if (in_array($role->name, ['ADMINISTRADOR', 'VENDEDOR', 'REPRESENTANTE', 'TÉCNICO', 'FINANCEIRO'])) {
            abort(response()->json(['message' => 'Este é um cargo padrão do sistema e não pode ser excluído.'], 409));
        }

        if ($role->users()->exists()) {
            abort(response()->json(['message' => 'Não é possível excluir este cargo, pois está vinculado a algum funcionário.'], 409));
        }

        return true;
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            //
        ];
    }
}
