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
        Schema::create('vendedor_configs', function (Blueprint $table) {
            $table->id();
            $table->enum('tipo_comissao', ["VALOR_FIXO", "PORCENTAGEM"]);
            $table->decimal('porcentagem_comissao', 5, 2);
            $table->bigInteger('valor_fixo_comissao_centavos');
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->timestamps();
            $table->unique(['user_id']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('vendedor_configs');
    }
};
