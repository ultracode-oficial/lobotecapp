<?php

namespace Database\Seeders;

use App\Models\TipoTarefa;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class TipoTarefaSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $tiposDeTarefa = [];

        foreach ($tiposDeTarefa as $name => $description) {
            TipoTarefa::firstOrCreate(['name' => $name], ['name' => $name, 'description' => $description]);
        }
    }
}
