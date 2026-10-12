<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;

class AdminSecretMiddleware
{
    public function handle(Request $request, Closure $next)
    {
        $secret = config('app.admin_secret');
        $provided = $request->header('X-Admin-Secret');

        if (!$secret || $provided !== $secret) {
            return response()->json(['message' => 'Forbidden'], 403);
        }

        return $next($request);
    }
}
