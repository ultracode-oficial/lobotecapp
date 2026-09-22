## Backend:
  - Laravel 13
  - PHP 8.5
  - Laravel Sail
  - JWT Auth
  - Spatie Permissions
  - MySQL
  - Redis

## Frontend:
  - Node 24
  - Vue 3 (Vite, Composition API, Vue Router, Pinia)
  - TailwindCSS 4
  - Axios
  - TanStack Vue Query 5
  - Lucide Icons

## dev:
  - backend: sail up -d
  - backend: sail artisan reverb:start & sail artisan queue:listen &
  - frontend: npm run dev

## Servidor WebSockets
php artisan reverb:start

## Fila de Processamento (E-mails, processamento de WebSockets, ...)
php artisan queue:listen

## Lembrete para configuração de proxy reverso:
  - /api -> backend web
  - /broadcasting -> backend web
  - /app -> backend websockets
  - /apps -> backend websockets
  - / -> frontend