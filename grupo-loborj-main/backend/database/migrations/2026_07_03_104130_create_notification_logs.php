<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('notification_logs', function (Blueprint $table) {
            $table->id();
            $table->string('title');
            $table->text('body');
            $table->string('resource')->comment('Ex: SERVICO, CONTRATO, PAGAMENTO, ESTOQUE');
            $table->string('resource_id')->comment('ID do recurso impactado (string para suportar tanto UUIDs quanto IDs alfa)');
            $table->string('action')->comment('Ex: APROVAR, REALOCAR, CHECAR_ESTOQUE');
            $table->timestamps();

            // Índices para otimizar relatórios e buscas por recurso
            $table->index(['resource', 'resource_id']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('notification_logs');
    }
};
