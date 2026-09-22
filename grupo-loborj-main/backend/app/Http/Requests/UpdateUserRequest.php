<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class UpdateUserRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        $userId = $this->route('user');

        return [
            'name' => 'required|string|max:255',
            'email' => "required|email|unique:users,email,{$userId}",
            'cpf' => "required|string|min:11|max:11|unique:users,cpf,{$userId}",
            'phone' => "nullable|string|min:10|max:11|unique:users,phone,{$userId}",
            'bio' => 'nullable|string',
            'password' => 'nullable|string|min:8|confirmed',
            'mfa_required' => 'required|boolean',
            'change_password_required' => 'required|boolean',

            'roles' => 'present|array',
            'roles.*' => 'string|exists:roles,name',
            'permissions' => 'present|array',
            'permissions.*' => 'string|exists:permissions,name',

            // Especializações do Técnico
            'especializacoes' => 'present|array',
            'especializacoes.*' => 'integer|exists:especializacaos,id',

            'vendedor_config' => 'required_if_any_role:VENDEDOR,REPRESENTANTE|array',
            'vendedor_config.tipo_comissao' => 'required_with:vendedor_config|in:VALOR_FIXO,PORCENTAGEM',
            'vendedor_config.porcentagem_comissao' => 'required_if:vendedor_config.tipo_comissao,PORCENTAGEM|numeric|min:0',
            'vendedor_config.valor_fixo_comissao_centavos' => 'required_if:vendedor_config.tipo_comissao,VALOR_FIXO|numeric|min:0',
        ];
    }

    protected function prepareForValidation(): void
    {
        if ($this->filled('cpf')) {
            $this->merge(['cpf' => preg_replace('/\D/', '', $this->input('cpf'))]);
        } else {
            $this->merge([
                'cpf' => null,
            ]);
        }

        if ($this->filled('phone')) {
            $this->merge([
                'phone' => preg_replace('/\D/', '', $this->input('phone')),
            ]);
        } else {
            $this->merge([
                'phone' => null,
            ]);
        }

        // Custom rule Macro helper ou lógica inline para validar se alguma role bate
        $this->getValidatorInstance()->addExtension('required_if_any_role', function ($attribute, $value, $parameters) {
            $inputRoles = $this->input('roles', []);
            return count(array_intersect($inputRoles, $parameters)) === 0 || !empty($value);
        }, 'As configurações de vendedor são obrigatórias para perfis de Vendedor ou Representante.');
    }

    public function messages(): array
    {
        return [
            // Nome
            'name.required' => 'O campo nome é obrigatório.',
            'name.string' => 'O nome deve ser um texto válido.',
            'name.max' => 'O nome não pode ter mais de 255 caracteres.',

            // E-mail
            'email.required' => 'O campo e-mail é obrigatório.',
            'email.email' => 'Informe um endereço de e-mail válido.',
            'email.unique' => 'Este e-mail já está em uso por outro usuário.',

            // CPF
            'cpf.required' => 'O campo CPF é obrigatório.',
            'cpf.string' => 'O CPF deve ser um formato de texto válido.',
            'cpf.min' => 'O CPF deve ter exatamente 11 dígitos.',
            'cpf.max' => 'O CPF deve ter exatamente 11 dígitos.',
            'cpf.unique' => 'Este CPF já está cadastrado para outro usuário.',

            // Telefone
            'phone.required' => 'O campo telefone é obrigatório.',
            'phone.string' => 'O telefone deve ser um formato de texto válido.',
            'phone.min' => 'O telefone deve ter pelo menos 10 dígitos.',
            'phone.max' => 'O telefone não pode ter mais de 11 dígitos.',
            'phone.unique' => 'Este telefone já está cadastrado para outro usuário.',

            // Bio
            'bio.string' => 'A biografia deve ser um texto válido.',

            // Senha
            'password.string' => 'A senha deve ser um texto válido.',
            'password.min' => 'A senha deve ter no mínimo 8 caracteres.',
            'password.confirmed' => 'As senhas informadas não conferem.',

            // Booleanos
            'mfa_required.required' => 'O campo de autenticação em dois fatores (MFA) é obrigatório.',
            'mfa_required.boolean' => 'O campo MFA deve ser verdadeiro ou falso.',
            'change_password_required.required' => 'O campo de alteração de senha obrigatória é obrigatório.',
            'change_password_required.boolean' => 'O campo de alteração de senha obrigatória deve ser verdadeiro ou falso.',

            // Perfis (Roles)
            'roles.required' => 'É necessário informar pelo menos um perfil de acesso.',
            'roles.array' => 'O formato dos perfis é inválido (deve ser um array).',
            'roles.*.string' => 'O perfil informado é inválido.',
            'roles.*.exists' => 'O perfil selecionado não existe no sistema.',

            // Permissões
            'permissions.array' => 'O formato das permissões é inválido (deve ser um array).',
            'permissions.*.string' => 'A permissão informada é inválida.',
            'permissions.*.exists' => 'A permissão selecionada não existe no sistema.',

            // Especializações
            'especializacoes.array' => 'O formato das especializações é inválido (deve ser um array).',
            'especializacoes.*.integer' => 'O ID da especialização deve ser um número inteiro.',
            'especializacoes.*.exists' => 'A especialização selecionada não existe no sistema.',

            // Configurações de Vendedor
            'vendedor_config.array' => 'As configurações de vendedor devem ser enviadas em formato de conjunto (array).',
            'vendedor_config.tipo_comissao.required_with' => 'O tipo de comissão é obrigatório quando há configurações de vendedor.',
            'vendedor_config.tipo_comissao.in' => 'O tipo de comissão deve ser "VALOR_FIXO" ou "PORCENTAGEM".',
            'vendedor_config.porcentagem_comissao.required_if' => 'A porcentagem de comissão é obrigatória quando o tipo de comissão for PORCENTAGEM.',
            'vendedor_config.porcentagem_comissao.numeric' => 'A porcentagem de comissão deve ser um número.',
            'vendedor_config.porcentagem_comissao.min' => 'A porcentagem de comissão não pode ser menor que zero.',
            'vendedor_config.valor_fixo_comissao_centavos.required_if' => 'O valor fixo da comissão é obrigatório quando o tipo de comissão for VALOR_FIXO.',
            'vendedor_config.valor_fixo_comissao_centavos.numeric' => 'O valor fixo da comissão deve ser um número.',
            'vendedor_config.valor_fixo_comissao_centavos.min' => 'O valor fixo da comissão não pode ser menor que zero.',
        ];
    }
}