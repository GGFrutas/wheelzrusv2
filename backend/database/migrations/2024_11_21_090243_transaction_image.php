use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('transaction_images', function (Blueprint $table) {
            $table->id();
            $table->foreignId('transaction_id')->constrained('transactions')->onDelete('cascade'); // Foreign key to transactions table
            $table->string('file_path'); // Path to the image file (signature or image proof)
            $table->enum('type', ['signature', 'image_proof']); // Type: signature or image proof
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('transaction_images');
    }
};
