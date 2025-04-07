<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class Partners extends Model
{
    use HasFactory, HasApiTokens, Notifiable;
    protected $connection = 'odoo'; // Specify the Odoo database connection
    protected $table = 'res_partner'; // Specify the Odoo table
    protected $primaryKey = 'id'; // Primary key of the Odoo table
    public $timestamps = false; // Disable Laravel timestamps if not present in the Odoo table

   
}
