<?php

use App\Http\Controllers\NotificationController;
use App\Http\Controllers\AssetsController;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\ClienteController;
use App\Http\Controllers\EquipeController;
use App\Http\Controllers\EspecializacaoController;
use App\Http\Controllers\ForgotPasswordController;
use App\Http\Controllers\MfaController;
use App\Http\Controllers\ProfileController;
use App\Http\Controllers\RoleController;
use App\Http\Controllers\TipoEquipamentoController;
use App\Http\Controllers\TipoServicoController;
use App\Http\Controllers\TipoTarefaController;
use App\Http\Controllers\UserController;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\TestNotificationController;

// prefixo: /api/

Route::get('/banner.png', [AssetsController::class, 'banner']);

Route::post('/auth/login', [AuthController::class, 'login'])->name('login');
Route::post('/auth/forgot-password', [ForgotPasswordController::class, 'sendResetCode']);
Route::post('/auth/verify-code', [ForgotPasswordController::class, 'verifyCode']);
Route::post('/auth/reset-password', [ForgotPasswordController::class, 'resetPassword']);

Route::middleware('auth:api')->group(function () {
    Route::post('/test-route/{id}', [TestNotificationController::class, 'finishService']);

    // Sessão
    Route::post('/auth/logout', [AuthController::class, 'logout']);
    Route::post('/auth/refresh', [AuthController::class, 'refresh']);

    // Perfil
    Route::get('/auth/me', [AuthController::class, 'me']);
    Route::put('/profile', [ProfileController::class, 'update']);
    Route::post('/profile/photo', [ProfileController::class, 'uploadPhoto']);

    // Segurança da Conta
    Route::post('/auth/change-password', [AuthController::class, 'changePassword']);
    Route::prefix('auth/mfa')->group(function () {
        Route::get('/setup', [MfaController::class, 'setup']);     // Inicializa e gera o QR Code
        Route::post('/verify', [AuthController::class, 'verify']);   // Validação no Login (Token Temporário)
        Route::post('/enable', [MfaController::class, 'enable']);   // Confirma código e ativa
        Route::post('/disable', [MfaController::class, 'disable']); // Desativa (Requer senha + código)
        Route::get('/recovery-code', [MfaController::class, 'getRecoveryCode']); // Visualizar Código de Recuperação
    });

    // Notificações
    Route::prefix('notifications')->group(function () {
        Route::get('/', [NotificationController::class, 'index']);
        Route::post('/read-all', [NotificationController::class, 'markAllAsRead']);
        Route::patch('/{id}/read', [NotificationController::class, 'markAsRead']);
    });

    // Clientes
    Route::middleware('permission:VER_CLIENTES')->group(function () {
        Route::get('/clientes', [ClienteController::class, 'index']);
        Route::get('/clientes/{cliente}', [ClienteController::class, 'show']);
    });
    Route::middleware('permission:CRIAR_CLIENTES|GERIR_CLIENTES')->group(function () {
        Route::post('/clientes', [ClienteController::class, 'store']);

        // GERIR_CLIENTES = pode editar/deletar qualquer cliente, CRIAR_CLIENTES = pode criar n ovos clientes, editar/deletar clientes criados (não pode editar/deletar os que não criou);
        Route::put('/clientes/{cliente}', [ClienteController::class, 'update']);
        Route::delete('/clientes/{cliente}', [ClienteController::class, 'destroy']);
    });

    // Users
    Route::middleware('permission:VER_USUARIOS')->group(function () {
        Route::get('/users', [UserController::class, 'index']);
        Route::get('/users/{user}', [UserController::class, 'show'])->withTrashed();
    });
    Route::middleware('permission:CRIAR_USUARIOS')->group(function () {
        Route::post('/users', [UserController::class, 'store']);
    });
    Route::middleware('permission:GERIR_USUARIOS')->group(function () {
        Route::put('/users/{user}', [UserController::class, 'update']);
        Route::delete('/users/{user}', [UserController::class, 'destroy']);
        Route::post('users/{id}/restore', [UserController::class, 'restore']);
    });

    // Equipes
    Route::middleware('permission:VER_EQUIPES')->group(function () {
        Route::get('/equipes', [EquipeController::class, 'index']);
        Route::get('/equipes/{equipe}', [EquipeController::class, 'show']);
    });
    Route::middleware('permission:CRIAR_EQUIPES')->group(function () {
        Route::post('/equipes', [EquipeController::class, 'store']);
    });
    Route::middleware('permission:GERIR_EQUIPES')->group(function () {
        Route::put('/equipes/{equipe}', [EquipeController::class, 'update']);
        Route::delete('/equipes/{equipe}', [EquipeController::class, 'destroy']);
    });

    // Configurações
    Route::middleware('permission:VER_CONFIGURACOES')->group(function () {
        // Tipos de Serviço
        Route::get('/tipoServicos', [TipoServicoController::class, 'index']);
        Route::get('/tipoServicos/{tipoServico}', [TipoServicoController::class, 'show']);

        // Tipos de Tarefa
        Route::get('/tipoTarefas', [TipoTarefaController::class, 'index']);
        Route::get('/tipoTarefas/{tipoTarefa}', [TipoTarefaController::class, 'show']);

        // Tipos de Equipamento
        Route::get('/tipoEquipamentos', [TipoEquipamentoController::class, 'index']);
        Route::get('/tipoEquipamentos/{tipoEquipamento}', [TipoEquipamentoController::class, 'show']);

        // Especializações/Requisitos
        Route::get('/especializacoes', [EspecializacaoController::class, 'index']);
        Route::get('/especializacoes/{especializacao}', [EspecializacaoController::class, 'show']);

        // Cargos
        Route::get('/roles', [RoleController::class, 'index']);
        Route::get('/roles/{role}', [RoleController::class, 'show']);
    });
    Route::middleware('permission:GERIR_CONFIGURACOES')->group(function () {
        // Tipos de Serviço
        Route::post('/tipoServicos', [TipoServicoController::class, 'store']);
        Route::put('/tipoServicos/{tipoServico}', [TipoServicoController::class, 'update']);
        Route::delete('/tipoServicos/{tipoServico}', [TipoServicoController::class, 'destroy']);

        // Tipos de Tarefa
        Route::post('/tipoTarefas', [TipoTarefaController::class, 'store']);
        Route::put('/tipoTarefas/{tipoTarefa}', [TipoTarefaController::class, 'update']);
        Route::delete('/tipoTarefas/{tipoTarefa}', [TipoTarefaController::class, 'destroy']);

        // Tipos de Equipamento
        Route::post('/tipoEquipamentos', [TipoEquipamentoController::class, 'store']);
        Route::put('/tipoEquipamentos/{tipoEquipamento}', [TipoEquipamentoController::class, 'update']);
        Route::delete('/tipoEquipamentos/{tipoEquipamento}', [TipoEquipamentoController::class, 'destroy']);

        // Especializações/Requisitos
        Route::post('/especializacoes', [EspecializacaoController::class, 'store']);
        Route::put('/especializacoes/{especializacao}', [EspecializacaoController::class, 'update']);
        Route::delete('/especializacoes/{especializacao}', [EspecializacaoController::class, 'destroy']);

        // Cargos
        Route::post('/roles', [RoleController::class, 'store']);
        Route::put('/roles/{role}', [RoleController::class, 'update']);
        Route::delete('/roles/{role}', [RoleController::class, 'destroy']);
    });

    // Dados Auxiliares (opções para formulários, filtros, etc)
    Route::get('/roles-options', [RoleController::class, 'roleOptions']);
    Route::get('/especializacoes-options', [EspecializacaoController::class, 'especializacaoOptions']);
    Route::get('/tipoServicos-options', [TipoServicoController::class, 'tipoServicoOptions']);
    Route::get('/tipoEquipamentos-options', [TipoEquipamentoController::class, 'tipoEquipamentoOptions']);
});