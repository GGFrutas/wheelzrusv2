<?php

// namespace Database\Seeders;

// use App\Models\User;
// // use Illuminate\Database\Console\Seeds\WithoutModelEvents;
// use Illuminate\Database\Seeder;
// use Illuminate\Support\Facades\DB;
// use Illuminate\Support\Str;
// use Illuminate\Support\Facades\Hash;



class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        // User::factory(10)->create();

        User::create([
         
            'company_id' => 1,  // Random company ID between 1 and 5
            'partner_id' => 1,  // Random partner ID between 1 and 100
            'login' => 'user' . rand(1000, 9999) . '@example.com',  // Random email
            'password' => bcrypt('password'),  // Hashed password
            'active' => true,  // Set active to true
            'create_date' => now(),  // Current timestamp
            'action_id' => 1,  // Random action ID between 1 and 10
            'create_uid' => 1,  // Random user ID for creator
            'write_uid' => 1,  // Random user ID for last updater
            'signature' => 'Best regards, User ' . rand(1, 100),  // Random signature
            'share' => rand(0, 1) == 1,  // Random boolean for share
            'write_date' => now(),  // Current timestamp
            'totp_secret' => Str::random(16),  // Random string for TOTP secret
            'sidebar_type' => ['classic', 'compact', 'minimal'][array_rand(['classic', 'compact', 'minimal'])],  // Random sidebar type
            'notification_type' => 'email',  // Random notification type
            'odoobot_state' => ['active', 'inactive', 'paused'][array_rand(['active', 'inactive', 'paused'])],  // Random bot status
            'sale_team_id' => 1,  // Random sales team ID
            'target_sales_won' => rand(1000, 10000),  // Random sales won target
            'target_sales_done' => rand(1000, 10000),
        ]);
    }
}
