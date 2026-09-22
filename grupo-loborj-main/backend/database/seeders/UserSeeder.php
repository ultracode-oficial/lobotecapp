<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Spatie\Permission\Models\Role;

class UserSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        User::withoutGlobalScopes()->firstOrCreate(["email" => "victor.mussel@hotmail.com"], [
            'name' => 'Victor Mussel Candido',
            'email' => 'victor.mussel@hotmail.com',
            'password' => 'teste123', //'$2y$10$eMMXLkP579E/hf8.oSBJRu.yndQDIU0XrjRsY/R9Sr6hxzjToy0gC', 
            'cpf' => '16347992752',
            'phone' => '21992754062',
            'is_developer' => true,
        ]);

        $userId = DB::table('users')
            ->where('email', 'victor.mussel@hotmail.com')
            ->first()
            ->id;

        $user = User::withoutGlobalScopes()->findOrFail($userId);
        $role = Role::firstOrCreate(['name' => 'DESENVOLVEDOR']);
        $user->assignRole($role);
    }
}
