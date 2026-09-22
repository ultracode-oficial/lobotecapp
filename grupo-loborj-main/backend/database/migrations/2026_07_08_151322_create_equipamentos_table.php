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
        Schema::create('equipamentos', function (Blueprint $table) {
            $table->id();
            $table->foreignId('cliente_id')->constrained('clientes')->cascadeOnDelete();
            $table->foreignId('tipo_equipamento_id')->constrained('tipo_equipamentos')->restrictOnDelete();

            // Info extra (para não-genéricos)
            $table->string('tag')->nullable();
            $table->string('localizacao')->nullable();
            $table->string('marca')->nullable();
            $table->string('modelo')->nullable();
            $table->string('btu')->nullable();
            $table->string('evaporadora')->nullable();
            $table->string('condensadora')->nullable();
            $table->string('observacoes', 1000)->nullable();

            $table->boolean('is_generic')->default(false);

            $table->softDeletes();

            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('equipamentos');
    }
};
