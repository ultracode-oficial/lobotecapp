<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Response;

class AssetsController extends Controller
{
    public function banner()
    {
        $path = public_path('banner.png');

        // Verifica se o arquivo realmente existe na pasta public
        if (!File::exists($path)) {
            abort(404);
        }

        $file = File::get($path);
        $type = File::mimeType($path);

        // Retorna a imagem com o Header correto para o navegador renderizar
        return Response::make($file, 200)->header("Content-Type", $type);
    }
}
