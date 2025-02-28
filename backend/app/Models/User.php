<?php

namespace App\Models;

// use Illuminate\Contracts\Auth\MustVerifyEmail;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasFactory, HasApiTokens, Notifiable;
    // // protected $table = 'res_users'; 
    // /**
    //  * The attributes that are mass assignable.
    //  *
    //  * @var array<int, string>
    //  */
    // protected $fillable = [
    //     'name',
    //     'email',
    //     'mobile',
    //     'company_code',
    //     // 'login',
    //     'password',
    //     'picture',
    // ];

    // /**
    //  * The attributes that should be hidden for serialization.
    //  *
    //  * @var array<int, string>
    //  */
    // protected $hidden = [
    //     'password',
    //     'remember_token',
    // ];

    // /**
    //  * Get the attributes that should be cast.
    //  *
    //  * @return array<string, string>
    //  */
    // protected function casts(): array
    // {
    //     return [
    //         'email_verified_at' => 'datetime',
    //         'password' => 'hashed',
    //     ];
    // }
    protected $connection = 'odoo'; // Specify the Odoo database connection
    protected $table = 'res_users'; // Specify the Odoo table
    protected $primaryKey = 'id'; // Primary key of the Odoo table
    public $timestamps = false; // Disable Laravel timestamps if not present in the Odoo table

    protected $fillable = ['company_id', 'partner_id', 'login', 'password'];

    protected $hidden = [
        'password', // Hide sensitive fields when serialized
    ];

    protected $casts = [
        'create_date' => 'datetime', // If Odoo has datetime fields
    ];
}
