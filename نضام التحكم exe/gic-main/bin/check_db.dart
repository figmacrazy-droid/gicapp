import 'package:supabase/supabase.dart';

void main() async {
  final client = SupabaseClient(
    'https://mpcyblhdfecveamaessd.supabase.co',
    'sb_publishable__JN9KI2E5PMF680CUF-ydQ_DijaqBYH',
  );

  final s = await client.from('students').select('*').eq('academic_id', '2025551551');
  print('STUDENT 2025551551: $s');
  final r = await client.from('student_results').select('*').eq('academic_id', '2025551551');
  print('RESULT 2025551551: $r');
  final allR = await client.from('student_results').select('*');
  print('ALL RESULTS COUNT: ${allR.length}');
  for (var res in allR) {
    print('RESULT: ${res["academic_id"]} | ${res["student_name"]}');
  }
}
