<?php
namespace App\Http\Controllers;

use Illuminate\Support\Facades\Auth;
use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use PragmaRX\Google2FA\Google2FA;

class AuthController extends Controller
{
    public function login(Request $request)
    {
        $request->validate([
            'login' => 'required|string',
            'password' => 'required|string',
        ]);

        $loginInput = $request->input('login');
        $field = $this->determineLoginField($loginInput);

        // Sanitiza o valor se for CPF ou Telefone (mantém apenas números)
        $sanitizedLogin = ($field === 'email') ? $loginInput : preg_replace('/\D/', '', $loginInput);

        // Busca o usuário no banco de dados, ignorando filtros de invisibilidade
        if ($field === 'cpf-ou-phone') {
            $user = User::withoutGlobalScopes()->withTrashed()->where('cpf', $sanitizedLogin)->orWhere('phone', $sanitizedLogin)->first();
        } else {
            $user = User::withoutGlobalScopes()->withTrashed()->where($field, $sanitizedLogin)->first();
        }

        if (!$user || !Hash::check($request->password, $user->password)) {
            return response()->json(['message' => 'Credenciais inválidas'], 401);
        }

        // 1. Validação de Segurança Global (Bloqueio Total)
        if (isset($user->deleted_at)) {
            return response()->json(['message' => 'Sua conta foi desativada'], 403);
        }

        if (!$user->hasPermissionTo('LOGIN') || isset($user->deleted_at)) {
            return response()->json(['message' => 'Sua conta não tem permissão de acesso ao sistema'], 403);
        }

        // 2. Validação por Plataforma (Web vs Mobile)
        // O frontend deve enviar um header identificando a plataforma, ex: X-Platform: mobile
        $platform = $request->header('X-Platform', 'web');

        if ($platform === 'mobile' && !$user->hasPermissionTo('ACESSO_MOBILE')) {
            return response()->json(['message' => 'Sua conta não tem permissão para acesso mobile'], 403);
        }

        if ($platform === 'web' && !$user->hasPermissionTo('ACESSO_WEB')) {
            return response()->json(['message' => 'Sua conta não tem permissão para acesso web'], 403);
        }

        // 3. Validação do Fluxo de MFA (TOTP)
        if ($this->isMfaRequiredFor($user)) {
            // Gera um token temporário de 5 minutos apenas para a verificação do código
            $mfaToken = auth()->claims(['mfa_pending' => true])->setTTL(5)->login($user);

            return response()->json([
                'status' => 'requires_mfa',
                'mfa_token' => $mfaToken
            ], 200);
        }

        // Login padrão caso MFA não seja exigido
        $token = auth()->login($user);
        return $this->respondWithToken($token);
    }

    /**
     * Validação intermediária durante o fluxo de Login (MFA Obrigatório).
     */
    public function verify(Request $request)
    {
        $request->validate([
            'code' => 'required|string', // Remove o size:6, pois o código de recuperação é maior
        ]);

        $user = auth()->user();
        $payload = auth()->payload();

        if (!$payload->get('mfa_pending')) {
            return response()->json(['message' => 'Token inválido para esta operação.'], 401);
        }

        $google2fa = new Google2FA();
        $secret = decrypt($user->mfa_secret);
        $isValidAuth = false;
        $usedRecoveryCode = false;

        // 1. Tenta validar via aplicativo TOTP (Código de 6 dígitos)
        if (strlen($request->code) === 6 && $google2fa->verifyKey($secret, $request->code)) {
            $isValidAuth = true;
        }
        // 2. Se falhar ou for maior, tenta validar o código de recuperação
        elseif ($user->mfa_recovery_code && decrypt($user->mfa_recovery_code) === strtolower($request->code)) {
            $isValidAuth = true;
            $usedRecoveryCode = true;
        }

        if (!$isValidAuth) {
            return response()->json(['message' => 'Código inválido ou expirado.'], 422);
        }

        // Se usou código de recuperação, desativamos o MFA por segurança 
        // (assume-se que ele perdeu o dispositivo)
        if ($usedRecoveryCode) {
            $user->mfa_enabled = false;
            $user->mfa_secret = null;
            $user->mfa_recovery_code = null;
            $user->save();
        }

        auth()->invalidate();
        $finalToken = auth()->claims(['mfa_pending' => false])->setTTL(10080)->login($user);

        return $this->respondWithToken($finalToken, $usedRecoveryCode);
    }

    /**
     * Detecta o tipo de dado informado no input único de login.
     */
    private function determineLoginField(string $input): string
    {
        if (filter_var($input, FILTER_VALIDATE_EMAIL)) {
            return 'email';
        }

        // Remove tudo que não for número para avaliar o tamanho
        $numbersOnly = preg_replace('/\D/', '', $input);

        // CPFs e Telefone celular possuem exatamente 11 dígitos
        if (strlen($numbersOnly) === 11) {
            return 'cpf-ou-phone';
        }

        // Telefones fixos possuem 10 dígitos
        if (strlen($numbersOnly) === 10) {
            return 'phone';
        }

        // Fallback padrão caso não bata com nenhuma regra estruturada
        return 'email';
    }

    /**
     * Regra hierárquica para checar se o MFA é obrigatório.
     */
    private function isMfaRequiredFor(User $user): bool
    {
        // 1. Verifica se está ativado globalmente no .env do sistema
        if (config('auth.mfa_globally_required', false) && $user->mfa_enabled) {
            return true;
        }

        // 2. Verifica se este usuário específico foi marcado como obrigatório
        if ($user->mfa_required && $user->mfa_enabled) {
            return true;
        }

        // 3. Se o usuário ativou voluntariamente nas configurações dele
        return $user->mfa_enabled;
    }

    /**
     * Get the authenticated User.
     *
     * @return \Illuminate\Http\JsonResponse
     */
    public function me()
    {
        $user = auth()->user()->load('especializacoes', 'vendedorConfig', 'equipes');
        $path_file_storage = config('app.filestorage_path');

        return response()->json([
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'cpf' => $user->cpf,
                'phone' => $user->phone,
                'photo' => isset($user->photo) ? $path_file_storage . $user->photo : null,
                'bio' => $user->bio,
                'mfa_enabled' => $user->mfa_enabled,
                'mfa_required' => $user->mfa_required,
                'change_password_required' => $user->change_password_required,
                'created_at' => $user->created_at,
                'updated_at' => $user->updated_at,
                'vendedorConfig' => $user->vendedorConfig,
                'especializacoes' => $user->especializacoes,
                'equipes' => $user->equipes,
                'is_developer' => $user->is_developer ? true : false,
            ],
            'roles' => $user->getRoleNames(),
            'permissions' => $user->getAllPermissions()->pluck('name'),
        ]);
    }

    /**
     * Log the user out (Invalidate the token).
     *
     * @return \Illuminate\Http\JsonResponse
     */
    public function logout()
    {
        auth()->logout();

        return response()->json(['message' => 'Successfully logged out']);
    }

    /**
     * Refresh a token.
     *
     * @return \Illuminate\Http\JsonResponse
     */
    public function refresh()
    {
        $user = auth()->user();

        if ($user) {
            $user->refresh();
        }

        auth()->login($user);

        return $this->respondWithToken(auth()->refresh());
    }

    /**
     * Get the token array structure.
     *
     * @param  string $token
     *
     * @return \Illuminate\Http\JsonResponse
     */
    protected function respondWithToken($token, $usedRecoveryCode = false)
    {
        $user = auth()->user();

        $path_file_storage = config('app.filestorage_path');

        return response()->json([
            'access_token' => $token,
            'token_type' => 'bearer',
            'expires_in' => auth()->factory()->getTTL() * 60,
            'mfa_disabled_due_to_recovery' => $usedRecoveryCode,
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'cpf' => $user->cpf,
                'phone' => $user->phone,
                'photo' => isset($user->photo) ? $path_file_storage . $user->photo : null,
                'bio' => $user->bio,
                'mfa_enabled' => $user->mfa_enabled,
                'mfa_required' => $user->mfa_required,
                'change_password_required' => $user->change_password_required,
                'is_developer' => $user->is_developer ? true : false,
            ],
        ]);
    }

    public function changePassword(Request $request)
    {
        $passwordRules = ['required', 'string', 'confirmed'];

        if (config('auth.password_rules.min_8')) {
            $passwordRules[] = 'min:8';
        }

        if (config('auth.password_rules.uppercase')) {
            $passwordRules[] = 'regex:/[A-Z]/'; // Pelo menos uma letra maiúscula
        }

        if (config('auth.password_rules.number')) {
            $passwordRules[] = 'regex:/[0-9]/'; // Pelo menos um número
        }

        if (config('auth.password_rules.symbol')) {
            $passwordRules[] = 'regex:/[^a-zA-Z0-9]/'; // Pelo menos um símbolo
        }

        $customMessages = [
            'password.regex' => 'A nova senha não atende aos requisitos de complexidade.',
            'current_password.required' => "Informe a senha atual.",
            'password.required' => "Informe a nova senha.",
            'password.confirmed' => "A nova senha e a confirmação da nova senha devem ser iguais.",
        ];

        $request->validate([
            'current_password' => 'required|string',
            'password' => $passwordRules,
        ], $customMessages);

        $user = Auth::user();

        if (!Hash::check($request->current_password, $user->password)) {
            return response()->json(['message' => 'Senha atual incorreta'], 401);
        }

        $user->password = Hash::make($request->password);
        $user->change_password_required = false;
        $user->save();

        return response()->json([
            "message" => "Senha alterada com sucesso!"
        ]);
    }
}