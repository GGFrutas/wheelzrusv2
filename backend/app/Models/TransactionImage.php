<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class TransactionImage extends Model
{
    use HasFactory;

    protected $fillable = [
        'transaction_id', 'file_path',
    ];

    // Define the inverse relationship with Transaction
    public function transaction()
    {
        return $this->belongsTo(Transaction::class);
    }
}