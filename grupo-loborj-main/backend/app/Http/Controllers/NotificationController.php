<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Http\Resources\NotificationResource;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Http\JsonResponse;

class NotificationController extends Controller
{
    public function index(Request $request): AnonymousResourceCollection
    {
        $query = $request->user()->notifications()->with('log')->latest();

        $unreadCount = $request->user()->notifications()->whereNull('read_at')->count();

        if ($request->query('status') === 'unread') {
            $query->whereNull('read_at');
        }

        return NotificationResource::collection($query->paginate(15))->additional(['unread' => $unreadCount]);
    }

    public function markAsRead(Request $request, int $id): JsonResponse
    {
        $notification = $request->user()
            ->notifications()
            ->findOrFail($id);

        if (is_null($notification->read_at)) {
            $notification->update(['read_at' => now()]);
        }

        return response()->json(['message' => 'Notificação marcada como lida.']);
    }

    public function markAllAsRead(Request $request): JsonResponse
    {
        $request->user()
            ->notifications()
            ->whereNull('read_at')
            ->update(['read_at' => now()]);

        return response()->json(['message' => 'Todas as notificações foram marcadas como lidas.']);
    }
}