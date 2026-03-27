<?php

namespace App\Http\Controllers;

abstract class Controller
{
    protected $odooUrl;
    protected $odooDb;

    public function __construct () {
        $this->odooUrl = config('odoo.odoo_url');
        $this->odooDb = config('odoo.odoo_db');
    }
}
