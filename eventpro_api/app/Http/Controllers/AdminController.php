<?php

namespace App\Http\Controllers;

use App\Models\Event;
use App\Models\Booking;
use App\Models\User;
use Illuminate\Http\Request;

class AdminController extends Controller
{
    public function dashboard(Request $request)
    {
        $totalRevenue = Booking::where('status', 'completed')->sum('amount');
        $totalBookings = Booking::count();
        $totalEvents = Event::count();
        $totalUsers = User::count();

        // Dummy data for charts
        $revenueChart = [
            ['day' => 1, 'amount' => 1000],
            ['day' => 2, 'amount' => 1500],
            ['day' => 3, 'amount' => 1200],
        ];

        $bookingsChart = [
            ['day' => 1, 'count' => 5],
            ['day' => 2, 'count' => 8],
            ['day' => 3, 'count' => 6],
        ];

        return response()->json([
            'total_revenue' => $totalRevenue,
            'total_bookings' => $totalBookings,
            'total_events' => $totalEvents,
            'total_users' => $totalUsers,
            'revenue_chart' => $revenueChart,
            'bookings_chart' => $bookingsChart,
        ]);
    }

    public function events()
    {
        $events = Event::all();
        return response()->json(['data' => $events]);
    }

    public function storeEvent(Request $request)
    {
        $request->validate([
            'title' => 'required|string',
            'date' => 'required|date',
            'price' => 'required|numeric',
        ]);

        $event = new Event();
        $event->title = $request->title;
        $event->description = $request->description ?? '';
        $event->category = $request->category ?? 'Other';
        $event->venue = $request->venue ?? 'TBD';
        $event->address = $request->address;
        $event->date = $request->date;
        $event->price = $request->price;
        $event->capacity = $request->capacity ?? 100;
        $event->is_featured = $request->is_featured ?? false;
        $event->organizer_id = $request->user()->id;
        $event->save();

        return response()->json(['message' => 'Event created', 'event' => $event]);
    }

    public function updateEvent(Request $request, $id)
    {
        $event = Event::findOrFail($id);
        $event->update($request->all());
        return response()->json(['message' => 'Event updated', 'event' => $event]);
    }

    public function deleteEvent($id)
    {
        $event = Event::findOrFail($id);
        $event->delete();
        return response()->json(['message' => 'Event deleted']);
    }

    public function checkIn(Request $request)
    {
        $request->validate(['qr_code' => 'required|string']);
        
        $booking = Booking::where('qr_code', $request->qr_code)->first();
        
        if (!$booking) {
            return response()->json(['message' => 'Invalid ticket'], 400);
        }

        if ($booking->status === 'checked_in') {
            return response()->json(['message' => 'Ticket already used'], 400);
        }

        $booking->status = 'checked_in';
        $booking->save();

        return response()->json([
            'message' => 'Check-in successful',
            'attendee_name' => $booking->user->name ?? 'Attendee',
            'event_title' => $booking->event->title ?? 'Event',
        ]);
    }

    public function reports(Request $request)
    {
        // Simple dummy report response
        return response()->json([
            'revenue_chart' => [['amount' => 5000]],
            'top_events' => [
                ['title' => 'Festival', 'bookings' => 50, 'revenue' => 50000]
            ],
            'category_breakdown' => ['Music' => 10, 'Tech' => 5]
        ]);
    }
}
