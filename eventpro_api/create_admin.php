<?php
require __DIR__.'/vendor/autoload.php';
$app = require_once __DIR__.'/bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

$user = new App\Models\User();
$user->name = 'Admin';
$user->email = 'admin@eventpro.com';
$user->password = bcrypt('admin123');
$user->role = 'admin';
$user->save();
echo "Admin created successfully!\n";
