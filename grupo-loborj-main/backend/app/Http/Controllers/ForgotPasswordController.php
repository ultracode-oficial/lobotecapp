<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Str;

class ForgotPasswordController extends Controller
{
    /**
     * Passo 1: Recebe o e-mail, gera o código de 6 dígitos e envia.
     */
    public function sendResetCode(Request $request)
    {
        $request->validate(['email' => 'required|email']);

        $user = User::where('email', $request->email)->first();

        if (!$user) {
            // Retornamos 200 de qualquer forma por segurança (prevenir user enumeration)
            return response()->json(['message' => 'Se o e-mail existir, um código foi enviado.'], 200);
        }

        // Gera um código numérico de 6 dígitos
        $code = str_pad(random_int(0, 999999), 6, '0', STR_PAD_LEFT);

        // Atualiza ou insere o código na tabela de password_reset_tokens
        DB::table('password_reset_tokens')->updateOrInsert(
            ['email' => $user->email],
            [
                'token' => Hash::make($code), // Hasheamos o código no DB por segurança
                'created_at' => now()
            ]
        );

        Mail::to($user->email)->send(new \App\Mail\ResetPasswordMail($code));

        return response()->json(['message' => 'Código enviado com sucesso.'], 200);
    }

    /**
     * Passo 2: Valida se o código de 6 dígitos está correto.
     */
    public function verifyCode(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'code' => 'required|digits:6',
        ]);

        $resetRequest = DB::table('password_reset_tokens')->where('email', $request->email)->first();

        if (!$resetRequest || !Hash::check($request->code, $resetRequest->token)) {
            return response()->json(['message' => 'Código inválido ou expirado.'], 400);
        }

        // Verifica se expirou (ex: validade de 15 minutos)
        if (now()->subMinutes(15)->gt($resetRequest->created_at)) {
            DB::table('password_reset_tokens')->where('email', $request->email)->delete();
            return response()->json(['message' => 'O código expirou. Solicite um novo.'], 400);
        }

        return response()->json(['message' => 'Código validado com sucesso.'], 200);
    }

    /**
     * Passo 3: Recebe a nova senha e a atualiza no banco.
     */
    public function resetPassword(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'code' => 'required|digits:6',
            'password' => 'required|string|min:8|confirmed',
        ]);

        // Dupla checagem do código por segurança antes de alterar a senha
        $resetRequest = DB::table('password_reset_tokens')->where('email', $request->email)->first();

        if (!$resetRequest || !Hash::check($request->code, $resetRequest->token)) {
            return response()->json(['message' => 'Código inválido ou expirado.'], 400);
        }

        // Atualiza a senha
        $user = User::where('email', $request->email)->first();
        $user->password = Hash::make($request->password);
        $user->change_password_required = false;
        $user->save();

        // Limpa o token utilizado
        DB::table('password_reset_tokens')->where('email', $request->email)->delete();

        return response()->json(['message' => 'Senha atualizada com sucesso.'], 200);
    }
}