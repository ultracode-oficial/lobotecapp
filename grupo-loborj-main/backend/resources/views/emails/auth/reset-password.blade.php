<x-mail::message>
  {{-- Exemplo de inserção de um Banner (Opcional). A imagem deve estar online e ser responsiva. --}}
  ![Banner]({{ url('/api/banner.png') }})

  # Olá,

  Você solicitou a recuperação de senha da sua conta.
  Utilize o código de verificação abaixo para criar uma nova senha.

  <x-mail::panel>
    <div style="text-align: center; font-size: 32px; letter-spacing: 8px; font-weight: bold; color: #1e293b;">
      {{ $code }}
    </div>
  </x-mail::panel>

  Este código é válido por **15 minutos**. Se você não solicitou esta alteração, pode ignorar este e-mail com segurança.
  Nenhuma alteração será feita na sua conta.

  Atenciosamente,<br>
  {{ config('app.name') }}
</x-mail::message>