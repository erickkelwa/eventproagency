<?php

namespace App\Http\Controllers;

use App\Models\Service;
use App\Models\ServiceBooking;
use Illuminate\Http\Request;

class ServiceController extends Controller
{
    public function index(Request $request)
    {
        $query = Service::query();
        
        if ($request->has('category')) {
            $query->where('category', $request->category);
        }
        
        $services = $query->get();
        return response()->json(['data' => $services]);
    }

    public function show($id)
    {
        $service = Service::findOrFail($id);
        return response()->json(['service' => $service]);
    }

    public function storeBooking(Request $request)
    {
        $request->validate([
            'service_id' => 'required|exists:services,id',
            'event_date' => 'required|date',
        ]);

        $booking = new ServiceBooking();
        $booking->service_id = $request->service_id;
        $booking->user_id = $request->user()->id;
        $booking->event_date = $request->event_date;
        $booking->notes = $request->notes;
        $booking->status = 'pending';
        $booking->save();

        return response()->json(['message' => 'Booking created', 'booking' => $booking]);
    }
}
