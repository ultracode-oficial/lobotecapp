<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Controller;
use Endroid\QrCode\Color\Color;
use Endroid\QrCode\ErrorCorrectionLevel;
use Endroid\QrCode\RoundBlockSizeMode;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use PragmaRX\Google2FA\Google2FA;
use Str;
use Endroid\QrCode\Encoding\Encoding;
use Endroid\QrCode\QrCode;
use Endroid\QrCode\Writer\PngWriter;

class MfaController extends Controller
{
    /**
     * Passo 1: Inicializa o fluxo de ativação do MFA.
     * Gera a chave secreta e o QR Code, mantendo o status desativado.
     */
    public function setup()
    {
        $user = auth()->user();
        $google2fa = new Google2FA();

        // Gera uma chave secreta TOTP única
        $secret = $google2fa->generateSecretKey();

        // Armazena criptografada no banco, mas mantém desativado até a confirmação
        $user->mfa_secret = encrypt($secret);
        $user->mfa_enabled = false;
        $user->save();

        $qrCodeUrl = $google2fa->getQRCodeUrl(
            config('app.name', 'Nome do Sistema'),
            $user->email,
            $secret
        );

        $qrCode = new QrCode(
            data: $qrCodeUrl,
            encoding: new Encoding('UTF-8'),
            errorCorrectionLevel: ErrorCorrectionLevel::Low,
            size: 300,
            margin: 10,
            roundBlockSizeMode: RoundBlockSizeMode::Margin,
            foregroundColor: new Color(0, 0, 0),
            backgroundColor: new Color(255, 255, 255)
        );

        $writer = new PngWriter();
        $result = $writer->write($qrCode);
        $dataUri = $result->getDataUri();

        return response()->json([
            'secret' => $secret,
            'qr_code_url' => $qrCodeUrl,
            'qr_code_base64' => $dataUri
        ], 200);
    }

    /**
     * Passo 2: Confirma o código do app do usuário e ativa o MFA definitivamente.
     */
    public function enable(Request $request)
    {
        $request->validate([
            'code' => 'required|string|size:6'
        ]);

        $user = auth()->user();

        if (!$user->mfa_secret) {
            return response()->json(['message' => 'MFA não foi inicializado. Utilize o endpoint de setup primeiro.'], 400);
        }

        $google2fa = new Google2FA();
        $secret = decrypt($user->mfa_secret);

        if (!$google2fa->verifyKey($secret, $request->code)) {
            return response()->json(['message' => 'Código de confirmação inválido.'], 422);
        }

        $recoveryCode = strtolower(Str::random(4) . '-' . Str::random(4) . '-' . Str::random(4));

        $user->mfa_enabled = true;
        $user->mfa_recovery_code = encrypt($recoveryCode);
        $user->save();

        return response()->json([
            'message' => 'Autenticação de dois fatores ativada com sucesso.',
            'recovery_code' => $recoveryCode
        ], 200);
    }

    /**
     * Retorna o código de recuperação atual a qualquer momento.
     */
    public function getRecoveryCode()
    {
        $user = auth()->user();

        if (!$user->mfa_enabled || !$user->mfa_recovery_code) {
            return response()->json(['message' => 'MFA não está ativo nesta conta.'], 404);
        }

        return response()->json([
            'recovery_code' => decrypt($user->mfa_recovery_code)
        ], 200);
    }

    /**
     * Desativação segura do MFA. Exige a senha atual e um código TOTP válido.
     */
    public function disable(Request $request)
    {
        $request->validate([
            'password' => 'required|string',
            'code' => 'required|string|size:6'
        ]);

        $user = auth()->user();

        if (!$user->mfa_enabled) {
            return response()->json(['message' => 'O MFA já está desativado.'], 400);
        }

        if (!Hash::check($request->password, $user->password)) {
            return response()->json(['message' => 'Senha incorreta.'], 422);
        }

        $google2fa = new Google2FA();
        $secret = decrypt($user->mfa_secret);

        if (!$google2fa->verifyKey($secret, $request->code)) {
            return response()->json(['message' => 'Código MFA inválido.'], 422);
        }

        $user->mfa_secret = null;
        $user->mfa_enabled = false;
        $user->mfa_recovery_code = null;
        $user->save();

        return response()->json(['message' => 'Autenticação de dois fatores desativada.'], 200);
    }
}