<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Carbon\Carbon;

class TransactionRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        return true;
    }

    protected function prepareForValidation()
    {
        $this->merge([
            'transaction_date'  => $this->convertToDateTime($this->transaction_date),
            'eta' => $this->convertToDateTime($this->eta),
            'etd' => $this->convertToDateTime($this->etd),
        ]);
    }

    private function convertToDateTime($dateTime)
    {
        return $dateTime ? Carbon::createFromFormat('Y-m-d H:i:s.u', $dateTime)->format('Y-m-d H:i:s') : null;
    }
    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, \Illuminate\Contracts\Validation\ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'user_id' => 'nullable|exists:users,id',
            'amount' => 'nullable|numeric|min:0',
            'transaction_date' => 'nullable|date',
            'description' => 'nullable|string|max:255',
            'transaction_id' => 'nullable|string|unique:transactions,transaction_id',
            'booking' => 'nullable|string|max:255',
            'location' => 'nullable|string|max:255',
            'destination' => 'nullable|string|max:255',
            'eta' => 'nullable|date',
            'etd' => 'nullable|date',
            'status' => 'nullable|string|in:Pending,Completed,Cancelled,Ongoing',
        ];
    }
    public function messages()
    {
        return [
            'user_id.required' => 'A user ID is required.',
            'transaction_id.unique' => 'This transaction ID is already used.',
            'status.in' => 'Status must be either pending, completed, or cancelled.',
        ];
    }
}
