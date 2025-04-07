<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class PersonalAccessToken extends SanctumPersonalAccessToken
{
    protected $connection = 'odoo'; // Specify the Odoo database connection
}
