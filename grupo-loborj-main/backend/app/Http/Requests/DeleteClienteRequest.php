<?php

namespace App\Http\Requests;

use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;

class DeleteClienteRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        $cliente = $this->route('cliente');

        // if ($cliente->contratos()->exists()) {
        //     abort(response()->json(['message' => 'Não é possível excluir este cliente, pois está relacionado a algum contrato.'], 409));
        // }
        // if ($cliente->servicos()->exists()) {
        //     abort(response()->json(['message' => 'Não é possível excluir este cliente, pois está relacionado a algum serviço.'], 409));
        // }
        if ($cliente->equipamentos()->where('is_generic', false)->exists()) {
            abort(response()->json(['message' => 'Não é possível excluir este cliente, pois está relacionado a algum equipamento não-genérico.'], 409));
        }

        if (auth()->user()->can('GERIR_CLIENTES')) {
            return true;
        }

        if (auth()->user()->id !== $cliente->user_id) {
            abort(response()->json(['message' => 'Você não possui permissão para excluir este cliente.'], 401));
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
