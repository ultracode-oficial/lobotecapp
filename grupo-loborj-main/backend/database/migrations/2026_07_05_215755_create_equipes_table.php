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
        Schema::create('equipes', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->text('description')->nullable();
            $table->timestamps();

            $table->softDeletes();
            // Coluna gerada: 1 se ativo (deleted_at é NULL), NULL se deletado
            $table->boolean('active')->storedAs('IF(deleted_at IS NULL, 1, NULL)');

            // Indices UNIQUE usando a nova coluna 'active'
            $table->unique(['name', 'active']);
        });

        // Tabela pivô para o relacionamento N:N
        Schema::create('equipe_user', function (Blueprint $table) {
            $table->foreignId('equipe_id')->constrained('equipes')->restrictOnDelete();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->primary(['equipe_id', 'user_id']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('equipes');
    }
};
