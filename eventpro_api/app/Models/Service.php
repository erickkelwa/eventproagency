<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Service extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'description',
        'category',
        'price_from',
        'price_to',
        'image_url',
        'phone',
        'email',
        'rating',
        'review_count',
        'is_available',
    ];

    protected $casts = [
        'is_available' => 'boolean',
    ];

    public function bookings()
    {
        return $this->hasMany(ServiceBooking::class);
    }
}
