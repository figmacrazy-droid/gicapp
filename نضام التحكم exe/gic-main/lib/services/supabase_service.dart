import 'package:supabase_flutter/supabase_flutter.dart';

class AdminSupabase {
  static const String supabaseUrl = 'https://mpcyblhdfecveamaessd.supabase.co';
  static const String anonKey = 'sb_publishable__JN9KI2E5PMF680CUF-ydQ_DijaqBYH';

  static final SupabaseClient client = SupabaseClient(
    supabaseUrl,
    anonKey,
  );
}
