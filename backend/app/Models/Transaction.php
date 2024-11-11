<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Transaction extends Model
{
    use HasFactory;

    protected $table = 'transactions';

    protected $fillable = [
        'user_id',
        'amount',
        'transaction_date',
        'description',
        'transaction_id',
        'booking',
        'location',
        'destination',
        'eta',
        'etd',
        'status'
    ];

    // Define relationships
    public function user() {
        return $this->belongsTo(User::class);
    }
}
