<?php

namespace Database\Seeders;

use App\Models\TipoServico;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class TipoServicoSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $tiposDeServico = [
            'PMOC' => 'Plano de Manutenção, Operação e Controle. Execução de rotinas obrigatórias de manutenção preventiva e higienização de ar-condicionado, garantindo a conformidade com a Lei Federal 13.589/2018 e evitando multas sanitárias.',
            'HVAC' => 'Aquecimento, Ventilação e Ar-Condicionado. Projeto, cálculo e instalação de sistemas complexos de climatização, ventilação mecânica e renovação de ar para ambientes industriais, comerciais e residenciais de grande porte.',
        ];

        foreach ($tiposDeServico as $name => $description) {
            TipoServico::firstOrCreate(['name' => $name], ['name' => $name, 'description' => $description]);
        }
    }
}
