<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Event extends Model
{
    use HasFactory;

    protected $fillable = [
        'title',
        'description',
        'category',
        'venue',
        'address',
        'date',
        'price',
        'capacity',
        'booked_count',
        'image_url',
        'latitude',
        'longitude',
        'organizer_id',
        'is_featured',
    ];

    protected $casts = [
        'date' => 'datetime',
        'is_featured' => 'boolean',
    ];

    public function organizer()
    {
        return $this->belongsTo(User::class, 'organizer_id');
    }

    public function bookings()
    {
        return $this->hasMany(Booking::class);
    }
}
