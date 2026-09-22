<?php

namespace App\Http\Requests;

use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;

class DeleteEspecializacaoRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        $especializacao = $this->route('especializacao');

        // if ($especializacao->contratos()->exists()) {
        //     abort(response()->json(['message' => 'Não é possível excluir esta especialização, pois está vinculada a algum contrato.'], 409));
        // }

        // if ($especializacao->servicos()->exists()) {
        //     abort(response()->json(['message' => 'Não é possível excluir esta especialização, pois está vinculada a algum serviço.'], 409));
        // }

        if ($especializacao->users()->exists()) {
            abort(response()->json(['message' => 'Não é possível excluir esta especialização, pois está vinculada a algum funcionário.'], 409));
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
