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
        Schema::create('clientes', function (Blueprint $table) {
            $table->id();

            // Dados Pessoa Jurídica
            $table->string('razao_social');
            $table->string('nome_fantasia')->nullable();
            $table->string('cnpj', 14);
            $table->text('observacoes')->nullable();

            // Contato
            $table->string('email')->nullable();
            $table->string('phone', 11)->nullable();
            $table->string('nome_representante')->nullable();

            // Endereço
            $table->string('cep')->nullable();
            $table->string('logradouro')->nullable();
            $table->string('numero_logradouro')->nullable();
            $table->string('complemento')->nullable();
            $table->string('bairro')->nullable();
            $table->string('municipio')->nullable();
            $table->string('uf')->nullable();
            $table->decimal('lat', 10, 8)->nullable();
            $table->decimal('lng', 10, 8)->nullable();

            $table->foreignId('vendedor_id')->nullable()->constrained('users')->nullOnDelete();
            $table->foreignId('creator_id')->nullable()->constrained('users')->nullOnDelete();

            $table->softDeletes();
            // Coluna gerada: 1 se ativo (deleted_at é NULL), NULL se deletado
            $table->boolean('active')->storedAs('IF(deleted_at IS NULL, 1, NULL)');

            // Indices UNIQUE usando a nova coluna 'active'
            $table->unique(['cnpj', 'active']);
            $table->unique(['email', 'active']);
            $table->unique(['phone', 'active']);

            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('clientes');
    }
};
