class SupabaseConfig {
  // Supabase project URL and anon key (client-safe)
  static const String supabaseUrl = 'https://ihwtzdnlansftzqbocaz.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imlod3R6ZG5sYW5zZnR6cWJvY2F6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM5ODIzMDEsImV4cCI6MjA2OTU1ODMwMX0.5sHwTR33vmVL8cAF4S_a45kr7sW30hX6G9XYCervdE4';

  // Storage bucket for profile images (ensure this bucket exists; set public for getPublicUrl)
  static const String profileImagesBucket = 'lawiseImages';
}