<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Intervention\Image\Drivers\Gd\Driver;
use Intervention\Image\Encoders\WebpEncoder;
use Intervention\Image\Format;
use Intervention\Image\ImageManager;
use Str;

class ProfileController extends Controller
{
    /**
     * Atualiza os dados textuais do perfil.
     */
    public function update(Request $request)
    {
        $user = auth()->user();

        $data = $request->only(['name', 'email', 'cpf', 'phone', 'bio']);

        if (isset($data['cpf'])) {
            $data['cpf'] = preg_replace('/\D/', '', $data['cpf']);
        }

        if (isset($data['phone'])) {
            $data['phone'] = preg_replace('/\D/', '', $data['phone']);
        }

        $validated = validator($data, [
            'name' => 'required|string|max:255',
            'email' => 'required|email|unique:users,email,' . $user->id,
            'cpf' => 'nullable|digits:11|unique:users,cpf,' . $user->id,
            'phone' => 'nullable|digits_between:10,11|unique:users,phone,' . $user->id,
            'bio' => 'nullable|string|max:1000',
        ])->validate();

        $user->update($validated);

        return response()->json(['message' => 'Perfil atualizado!', 'user' => $user], 200);
    }

    /**
     * Atualiza a foto de perfil.
     */
    public function uploadPhoto(Request $request)
    {
        $request->validate([
            'photo' => 'required|image|mimes:jpeg,png,jpg|max:2048'
        ]);

        $user = auth()->user();

        if (isset($user->photo)) {
            Storage::delete($user->photo);
        }

        $baseName = Str::uuid()->toString();
        $basePath = trim('avatars', '/')
            ? "avatars/{$baseName}"
            : $baseName;

        $file = $request->file('photo');

        $manager = ImageManager::usingDriver(Driver::class);
        $image = $manager->decode($file->getPathname())->orient();
        $image->cover(400, 400);
        $encoded = $image->encodeUsingFormat(Format::WEBP, quality: 85);
        $filename = "{$basePath}.webp";

        Storage::put($filename, (string) $encoded);

        $user->update(['photo' => $filename]);

        $path_file_storage = config('app.filestorage_path');

        return response()->json([
            'message' => 'Foto atualizada com sucesso.',
            'photo_url' => $path_file_storage . $filename
        ], 200);
    }
}