<?php

namespace Database\Seeders;

use App\Models\TipoEquipamento;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class TipoEquipamentoSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $tiposDeEquipamento = [
            'ACJ' => 'Ar-Condicionado de Janela. Equipamento compacto que concentra todos os componentes (evaporadora e condensadora) em uma única caixa.',
            'Split' => 'Sistema dividido em duas partes: unidade interna (evaporadora) e unidade externa (condensadora)'
        ];

        foreach ($tiposDeEquipamento as $name => $description) {
            TipoEquipamento::firstOrCreate(['name' => $name], ['name' => $name, 'description' => $description]);
        }
    }
}
