<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Spatie\Permission\Models\Permission;
use Spatie\Permission\Models\Role;

class PermissionsSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $todasAsPermissoes = [
            'LOGIN',
            'ACESSO_WEB',
            'ACESSO_MOBILE',
            'VER_CONFIGURACOES',
            'GERIR_CONFIGURACOES',

            'VER_AGENDA',
            'VER_OPORTUNIDADES',
            'VER_RELATORIOS',

            'VER_PAGAMENTOS',
            'GERIR_PAGAMENTOS', // confirmar, alterar

            'VER_ESTOQUE',
            'GERIR_ESTOQUE', // movimentar

            'VER_CLIENTES',
            'CRIAR_CLIENTES',
            'GERIR_CLIENTES',

            'VER_SERVICOS',
            'CRIAR_SERVICOS', // cadastrar serviço (Vendedor)
            'GERIR_SERVICOS', // confirmar, alterar, movimentar coisas
            'EXECUTAR_SERVICOS', // check-in em etapa, checklist, detalhar equipamento

            'VER_CONTRATOS',
            'CRIAR_CONTRATOS', // cadastrar contrato (Vendedor)
            'GERIR_CONTRATOS', // confirmar, alterar, movimentar coisas
            'CRIAR_SERVICO_EMERGENCIAL', // Administrador

            'VER_EQUIPES',
            'CRIAR_EQUIPES',
            'GERIR_EQUIPES',

            'VER_USUARIOS',
            'CRIAR_USUARIOS',
            'GERIR_USUARIOS',
        ];

        app()[\Spatie\Permission\PermissionRegistrar::class]->forgetCachedPermissions();

        // Dev
        $role = Role::firstOrCreate(['name' => 'DESENVOLVEDOR']);

        foreach ($todasAsPermissoes as $permissao) {
            Permission::firstOrCreate(['name' => $permissao, 'guard_name' => 'api']);
            $role->givePermissionTo($permissao);
        }

        // Roles Regra de Negócio:
        $systemRoles = [
            'VENDEDOR' => [
                'LOGIN',
                'ACESSO_WEB',
                'VER_AGENDA',
                'VER_OPORTUNIDADES',
                'VER_CLIENTES',
                'CRIAR_CLIENTES',
                'CRIAR_SERVICOS',
                'CRIAR_CONTRATOS'
            ],
            'REPRESENTANTE' => [
                'LOGIN',
                'ACESSO_WEB',
                'VER_AGENDA',
                'VER_OPORTUNIDADES',
                'VER_CLIENTES',
                'CRIAR_CLIENTES',
                'CRIAR_SERVICOS',
                'CRIAR_CONTRATOS'
            ],
            'TÉCNICO' => [
                'LOGIN',
                'ACESSO_MOBILE',
                'VER_AGENDA',
                'EXECUTAR_SERVICOS'
            ],
            'FINANCEIRO' => [
                'LOGIN',
                'ACESSO_WEB',
                'VER_RELATORIOS',
            ],
            'ADMINISTRADOR' => [
                'LOGIN',
                'ACESSO_WEB',
                'VER_CONFIGURACOES',
                'GERIR_CONFIGURACOES',
                'VER_AGENDA',
                'VER_OPORTUNIDADES',
                'VER_RELATORIOS',

                'VER_PAGAMENTOS',
                'GERIR_PAGAMENTOS',

                'VER_ESTOQUE',
                'GERIR_ESTOQUE',

                'VER_CLIENTES',
                'CRIAR_CLIENTES',
                'GERIR_CLIENTES',

                'VER_SERVICOS',
                'CRIAR_SERVICOS',
                'GERIR_SERVICOS',

                'VER_CONTRATOS',
                'CRIAR_CONTRATOS',
                'GERIR_CONTRATOS',
                'CRIAR_SERVICO_EMERGENCIAL',

                'VER_EQUIPES',
                'CRIAR_EQUIPES',
                'GERIR_EQUIPES',

                'VER_USUARIOS',
                'CRIAR_USUARIOS',
                'GERIR_USUARIOS',
            ],
        ];

        foreach ($systemRoles as $roleKey => $permissions) {
            $role = Role::firstOrCreate(['name' => $roleKey]);

            $permissionIds = [];
            foreach ($permissions as $permission) {
                $permissionModel = Permission::firstOrCreate([
                    'name' => $permission,
                    'guard_name' => 'api'
                ]);

                $permissionIds[] = $permissionModel->id;
            }

            $role->syncPermissions($permissionIds);
        }
    }
}
