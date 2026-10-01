<?php

namespace App\Http\Controllers;

use App\Models\Event;
use Illuminate\Http\Request;

class EventController extends Controller
{
    public function index(Request $request)
    {
        $query = Event::query();

        if ($request->has('category')) {
            $query->where('category', $request->category);
        }

        $events = $query->get();

        return response()->json(['data' => $events]);
    }

    public function show($id)
    {
        $event = Event::findOrFail($id);
        return response()->json(['event' => $event]);
    }
}
