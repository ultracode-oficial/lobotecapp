<?php

namespace App\Http\Requests;

use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;

class DeleteEquipeRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        $equipe = $this->route('equipe');

        // if ($equipe->etapas()->exists()) {
        //     abort(response()->json(['message' => 'Não é possível excluir esta equipe, pois está relacionada a alguma etapa de serviço.'], 409));
        // }

        if ($equipe->users()->exists()) {
            abort(response()->json(['message' => 'Não é possível excluir esta equipe, pois está relacionada a algum funcionário.'], 409));
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
