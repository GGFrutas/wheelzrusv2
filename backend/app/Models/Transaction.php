<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class Transaction extends Model
{
    use HasFactory, HasApiTokens, Notifiable;

    protected $connection = 'odoo';
    protected $table = 'dispatch_manager';
    protected $primaryKey = 'id';
    

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
        'status',
       'signature_path', // Add this to allow signature path saving
    ];
    public $timestamps = false;
    // Define relationships
    public function user() {
        return $this->belongsTo(User::class);
    }
    public function images()
    {
        return $this->hasMany(TransactionImage::class); // A transaction has many proofs (signature/image proofs)
    }
    protected $casts = [
        'eta' => 'datetime',
        'etd' => 'datetime',
        'transaction_date' => 'datetime',
    ];
}
