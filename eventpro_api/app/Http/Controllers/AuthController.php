<?php

namespace App\Http\Controllers;

use App\Models\User;
use App\Services\BrevoMailService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Auth;
use Kreait\Firebase\Contract\Auth as FirebaseAuth;

class AuthController extends Controller
{
    public function register(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users',
            'password' => 'required|string|min:8|confirmed',
            'phone' => 'nullable|string',
        ]);

        $user = User::create([
            'name' => $request->name,
            'email' => $request->email,
            'password' => Hash::make($request->password),
            'phone' => $request->phone,
            'role' => 'user',
        ]);

        $token = $user->createToken('auth_token')->plainTextToken;

        // Send welcome email
        try {
            app(BrevoMailService::class)->sendWelcome($user->email, $user->name);
        } catch (\Throwable $e) {
            \Illuminate\Support\Facades\Log::error('Welcome email failed: ' . $e->getMessage());
        }

        return response()->json([
            'user' => $user,
            'token' => $token,
        ]);
    }

    public function login(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'password' => 'required',
        ]);

        if (!Auth::attempt($request->only('email', 'password'))) {
            return response()->json(['message' => 'Invalid login credentials'], 401);
        }

        $user = User::where('email', $request->email)->firstOrFail();
        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'user' => $user,
            'token' => $token,
        ]);
    }

    public function googleLogin(Request $request, FirebaseAuth $firebaseAuth)
    {
        $request->validate([
            'firebase_token' => 'required|string',
        ]);

        try {
            $verifiedIdToken = $firebaseAuth->verifyIdToken($request->firebase_token);
            $uid = $verifiedIdToken->claims()->get('sub');
            $firebaseUser = $firebaseAuth->getUser($uid);

            $isNew = !User::where('email', $firebaseUser->email)->exists();

            $user = User::updateOrCreate(
                ['email' => $firebaseUser->email],
                [
                    'name' => $firebaseUser->displayName ?? 'User',
                    'password' => Hash::make(uniqid()), // Random password
                    'role' => 'user',
                ]
            );

            // Send welcome email only for brand-new Google sign-ups
            if ($isNew) {
                try {
                    app(BrevoMailService::class)->sendWelcome($user->email, $user->name);
                } catch (\Throwable $e) {
                    \Illuminate\Support\Facades\Log::error('Welcome email failed: ' . $e->getMessage());
                }
            }

            $token = $user->createToken('auth_token')->plainTextToken;

            return response()->json([
                'user' => $user,
                'token' => $token,
            ]);
        } catch (\Exception $e) {
            return response()->json(['message' => 'Unauthorized'], 401);
        }
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();
        return response()->json(['message' => 'Successfully logged out']);
    }

    public function me(Request $request)
    {
        return response()->json([
            'user' => $request->user(),
        ]);
    }

    public function updateFcmToken(Request $request)
    {
        $request->validate(['fcm_token' => 'required|string']);
        $user = clone $request->user();
        $user->fcm_token = $request->fcm_token;
        $user->save();

        return response()->json(['message' => 'Token updated']);
    }
}
