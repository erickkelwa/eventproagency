<?php

namespace App\Http\Controllers;

use App\Models\Event;
use App\Models\Booking;
use App\Models\Payment;
use App\Models\ServiceBooking;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class AdminController extends Controller
{
    public function dashboard(Request $request)
    {
        $completedBookingRev = Booking::where('status', 'completed')->sum('amount');
        $completedPaymentRev = Payment::where('status', 'completed')->sum('amount');
        $totalRevenue = max((float)$completedBookingRev, (float)$completedPaymentRev);
        
        $totalBookings = Booking::count();
        $totalEvents = Event::count();
        $totalUsers = User::count();
        $totalIssues = Payment::whereIn('status', ['failed', 'cancelled'])
            ->orWhere(function($q) {
                $q->where('status', 'pending')->where('created_at', '<', now()->subMinutes(15));
            })->count();

        // 7-day revenue trend
        $revenueChart = [];
        for ($i = 6; $i >= 0; $i--) {
            $day = now()->subDays($i);
            $dayRev = Payment::where('status', 'completed')
                ->whereDate('created_at', $day->toDateString())
                ->sum('amount');
            $revenueChart[] = [
                'day' => $day->format('D'),
                'amount' => (float)$dayRev,
            ];
        }

        // 7-day bookings trend
        $bookingsChart = [];
        for ($i = 6; $i >= 0; $i--) {
            $day = now()->subDays($i);
            $count = Booking::whereDate('created_at', $day->toDateString())->count();
            $bookingsChart[] = [
                'day' => $day->format('D'),
                'count' => $count,
            ];
        }

        return response()->json([
            'total_revenue' => $totalRevenue,
            'total_bookings' => $totalBookings,
            'total_events' => $totalEvents,
            'total_users' => $totalUsers,
            'total_issues' => $totalIssues,
            'revenue_chart' => $revenueChart,
            'bookings_chart' => $bookingsChart,
        ]);
    }

    public function events()
    {
        $events = Event::with('organizer')->latest()->get();
        return response()->json(['data' => $events]);
    }

    public function storeEvent(Request $request)
    {
        $request->validate([
            'title' => 'required|string|max:255',
            'date' => 'required',
            'price' => 'nullable|numeric',
        ]);

        $organizerId = $request->user()?->id ?? User::where('role', 'admin')->first()?->id ?? 1;

        $event = new Event();
        $event->title = $request->title;
        $event->description = $request->description ?? '';
        $event->category = $request->category ?? 'Music';
        $event->venue = $request->venue ?? 'Event Venue';
        $event->address = $request->address ?? $request->venue;
        $event->date = $request->date;
        $event->price = $request->price ?? 0;
        $event->capacity = $request->capacity ?? 100;
        $event->booked_count = 0;
        $event->image_url = $request->image_url ?? $request->image;
        $event->latitude = $request->latitude ? (float)$request->latitude : null;
        $event->longitude = $request->longitude ? (float)$request->longitude : null;
        $event->is_featured = filter_var($request->is_featured, FILTER_VALIDATE_BOOLEAN);
        $event->organizer_id = $organizerId;
        $event->save();

        return response()->json([
            'message' => 'Event created successfully',
            'event' => $event,
        ], 201);
    }

    public function updateEvent(Request $request, $id)
    {
        $event = Event::findOrFail($id);
        $data = $request->all();
        if (isset($data['is_featured'])) {
            $data['is_featured'] = filter_var($data['is_featured'], FILTER_VALIDATE_BOOLEAN);
        }
        $event->update($data);
        return response()->json(['message' => 'Event updated successfully', 'event' => $event]);
    }

    public function deleteEvent($id)
    {
        $event = Event::findOrFail($id);
        $event->delete();
        return response()->json(['message' => 'Event deleted successfully']);
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
        $totalCompletedRev = (float) Payment::where('status', 'completed')->sum('amount');
        if ($totalCompletedRev == 0) {
            $totalCompletedRev = (float) Booking::where('status', 'completed')->sum('amount');
        }

        $totalCompletedCount = Payment::where('status', 'completed')->count();
        $totalFailedCount = Payment::whereIn('status', ['failed', 'cancelled'])->count();

        // Top events by booking count
        $topEvents = Event::withCount('bookings')
            ->orderBy('bookings_count', 'desc')
            ->take(5)
            ->get()
            ->map(function ($e) {
                return [
                    'id' => $e->id,
                    'title' => $e->title,
                    'bookings' => $e->bookings_count,
                    'revenue' => (float) ($e->bookings_count * $e->price),
                ];
            });

        // Category breakdown
        $categories = Event::select('category', DB::raw('count(*) as count'))
            ->groupBy('category')
            ->pluck('count', 'category')
            ->toArray();

        // 7-day revenue chart
        $revenueChart = [];
        for ($i = 6; $i >= 0; $i--) {
            $day = now()->subDays($i);
            $amount = (float) Payment::where('status', 'completed')
                ->whereDate('created_at', $day->toDateString())
                ->sum('amount');
            $revenueChart[] = [
                'day' => $day->format('M d'),
                'amount' => $amount > 0 ? $amount : 0,
            ];
        }

        // Gateways breakdown (M-Pesa vs others)
        $gateways = Payment::select('payment_method', DB::raw('count(*) as count'), DB::raw('sum(amount) as revenue'))
            ->groupBy('payment_method')
            ->get();

        return response()->json([
            'total_revenue' => $totalCompletedRev,
            'completed_transactions' => $totalCompletedCount,
            'failed_transactions' => $totalFailedCount,
            'revenue_chart' => $revenueChart,
            'top_events' => $topEvents,
            'category_breakdown' => $categories,
            'gateways' => $gateways,
        ]);
    }

    public function users(Request $request)
    {
        $users = User::latest()->get()->map(function ($u) {
            $bookingCount = Booking::where('user_id', $u->id)->count();
            
            // Check for failed payments associated with this user
            $failedPayments = Payment::where(function ($q) use ($u) {
                if ($u->email) $q->where('email', $u->email);
                if ($u->phone) $q->orWhere('phone', 'like', '%' . substr($u->phone, -8));
            })->whereIn('status', ['failed', 'cancelled'])->get();

            $hasIssues = $failedPayments->isNotEmpty();
            $issueDetails = $hasIssues ? $failedPayments->map(fn($p) => [
                'transaction_id' => $p->transaction_id,
                'amount' => $p->amount,
                'payment_method' => $p->payment_method,
                'status' => $p->status,
                'created_at' => $p->created_at?->toDateTimeString(),
            ]) : [];

            return [
                'id' => (string)$u->id,
                'name' => $u->name,
                'email' => $u->email,
                'phone' => $u->phone,
                'role' => $u->role ?? 'user',
                'created_at' => $u->created_at?->toIso8601String(),
                'bookings_count' => $bookingCount,
                'has_issues' => $hasIssues,
                'issues' => $issueDetails,
            ];
        });

        return response()->json([
            'total' => $users->count(),
            'users' => $users,
        ]);
    }

    public function issues(Request $request)
    {
        $issues = Payment::whereIn('status', ['failed', 'cancelled'])
            ->orWhere(function ($q) {
                $q->where('status', 'pending')->where('created_at', '<', now()->subMinutes(15));
            })
            ->latest()
            ->take(50)
            ->get()
            ->map(function ($p) {
                $user = User::where('email', $p->email)
                    ->orWhere('phone', 'like', '%' . substr($p->phone ?? '', -8))
                    ->first();

                return [
                    'id' => $p->id,
                    'transaction_id' => $p->transaction_id,
                    'amount' => $p->amount,
                    'currency' => $p->currency ?? 'KES',
                    'payment_method' => $p->payment_method,
                    'phone' => $p->phone,
                    'email' => $p->email,
                    'status' => $p->status,
                    'booking_type' => $p->booking_type,
                    'booking_id' => $p->booking_id,
                    'user_name' => $user?->name ?? 'Guest Customer',
                    'created_at' => $p->created_at?->toDateTimeString(),
                ];
            });

        return response()->json([
            'total' => $issues->count(),
            'issues' => $issues,
        ]);
    }
}
