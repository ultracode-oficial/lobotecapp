<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class GeocodingService
{
  /**
   * @param array{numero_logradouro: string, logradouro: string, bairro: string, municipio: string, uf: string, cep: string} $inputAddress
   */
  public function getLatLng(array $inputAddress)
  {
    try {
      $address = $inputAddress['numero_logradouro'] . ',' . $inputAddress['logradouro'] . ',' . $inputAddress['bairro'] . ',' . $inputAddress['municipio'] . ',' . $inputAddress['uf'] . ',' . $inputAddress['cep'];

      $apiKey = config('app.maps_api_key');

      $response = Http::get('https://maps.googleapis.com/maps/api/geocode/json', [
        'address' => $address,
        'key' => $apiKey,
      ]);

      $response->throw();

      $data = $response->json();

      if (isset($data['results']) && count($data['results']) > 0) {
        $firstResult = $data['results'][0];

        if (isset($firstResult['geometry']['location'])) {
          $location = $firstResult['geometry']['location'];

          return [
            'lat' => $location['lat'],
            'lng' => $location['lng'],
          ];
        }
      }

    } catch (\Throwable $th) {
      Log::error($th, ['Error trying to get lat/lng', $inputAddress]);
      return [
        'lat' => null,
        'lng' => null,
      ];
    }
  }
}