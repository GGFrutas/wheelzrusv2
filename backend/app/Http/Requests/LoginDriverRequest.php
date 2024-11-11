<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class LoginDriverRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true; // Allow all requests
    }

    public function rules(): array
    {
        return [
            'login' => 'required|string', // or 'email' if you are using email for login
            'password' => 'required|string', // Adjust the minimum length as needed
        ];
    }

    public function messages(): array
    {
        return [
            'login.required' => 'The login field is required.',
            'password.required' => 'The password field is required.',
            // 'password.min' => 'The password must be at least :min characters.',
        ];
    }
}
