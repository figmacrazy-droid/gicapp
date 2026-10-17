import 'package:supabase/supabase.dart';

void main() async {
  final client = SupabaseClient(
    'https://mpcyblhdfecveamaessd.supabase.co',
    'sb_publishable__JN9KI2E5PMF680CUF-ydQ_DijaqBYH',
  );

  print('=== UPDATING ACADEMIC TREE ===');

  final healthDeptId = '627f9b73-8d28-4cad-94bd-1d9c404150d8';
  
  final existingMidwifery = await client
      .from('academic_tree')
      .select()
      .eq('parent_id', healthDeptId)
      .eq('title', 'فني قبالة وتوليد')
      .maybeSingle();

  String midwiferySpecId;
  if (existingMidwifery != null) {
    midwiferySpecId = existingMidwifery['id'];
    print('فني قبالة وتوليد موجودة مسبقاً: $midwiferySpecId');
  } else {
    final inserted = await client.from('academic_tree').insert({
      'parent_id': healthDeptId,
      'title': 'فني قبالة وتوليد',
      'node_type': 'specialty',
    }).select().single();
    midwiferySpecId = inserted['id'];
    print('تمت إضافة تخصص فني قبالة وتوليد: $midwiferySpecId');
  }

  final existingBatch3 = await client
      .from('academic_tree')
      .select()
      .eq('parent_id', midwiferySpecId)
      .eq('title', 'الدفعة 3')
      .maybeSingle();

  String batch3Id;
  if (existingBatch3 != null) {
    batch3Id = existingBatch3['id'];
    print('الدفعة 3 موجودة مسبقاً: $batch3Id');
  } else {
    final inserted = await client.from('academic_tree').insert({
      'parent_id': midwiferySpecId,
      'title': 'الدفعة 3',
      'node_type': 'group_shift',
    }).select().single();
    batch3Id = inserted['id'];
    print('تمت إضافة الدفعة 3: $batch3Id');
  }

  final existingSem5 = await client
      .from('academic_tree')
      .select()
      .eq('parent_id', batch3Id)
      .eq('title', 'الفصل الخامس')
      .maybeSingle();

  if (existingSem5 != null) {
    print('الفصل الخامس موجود مسبقاً: ${existingSem5['id']}');
  } else {
    final inserted = await client.from('academic_tree').insert({
      'parent_id': batch3Id,
      'title': 'الفصل الخامس',
      'node_type': 'group_shift',
    }).select().single();
    print('تمت إضافة الفصل الخامس: ${inserted['id']}');
  }

  final itSpecId = '3a88503e-55e1-4817-ab7b-b8e62d7f286e';
  
  final existingItBatch1 = await client
      .from('academic_tree')
      .select()
      .eq('parent_id', itSpecId)
      .eq('title', 'الدفعة 1')
      .maybeSingle();

  String itBatch1Id;
  if (existingItBatch1 != null) {
    itBatch1Id = existingItBatch1['id'];
    print('الدفعة 1 لتقنية المعلومات موجودة مسبقاً: $itBatch1Id');
  } else {
    final inserted = await client.from('academic_tree').insert({
      'parent_id': itSpecId,
      'title': 'الدفعة 1',
      'node_type': 'group_shift',
    }).select().single();
    itBatch1Id = inserted['id'];
    print('تمت إضافة الدفعة 1 لتقنية المعلومات: $itBatch1Id');
  }

  final existingItSem1 = await client
      .from('academic_tree')
      .select()
      .eq('parent_id', itBatch1Id)
      .eq('title', 'الفصل الأول')
      .maybeSingle();

  if (existingItSem1 != null) {
    print('الفصل الأول لتقنية المعلومات موجود مسبقاً: ${existingItSem1['id']}');
  } else {
    final inserted = await client.from('academic_tree').insert({
      'parent_id': itBatch1Id,
      'title': 'الفصل الأول',
      'node_type': 'group_shift',
    }).select().single();
    print('تمت إضافة الفصل الأول لتقنية المعلومات: ${inserted['id']}');
  }

  await client.from('students').update({
    'specialty': 'تقنية المعلومات',
    'batch': 'الدفعة 1',
    'semester': 'الفصل الأول',
  }).eq('academic_id', '2025010101');
  print('تم تحديث بيانات الطالب 2025010101');

  await client.from('students').update({
    'specialty': 'فني قبالة وتوليد',
    'batch': 'الدفعة 3',
    'semester': 'الفصل الخامس',
  }).eq('academic_id', '2021030551');
  print('تم تحديث بيانات الطالب 2021030551');

  print('\n=== ALL 6 STUDENTS IN DATABASE ===');
  final students = await client.from('students').select('*');
  for (var s in students) {
    print('${s["academic_id"]} | ${s["full_name"]} | ${s["specialty"]} | ${s["batch"]} | ${s["semester"]}');
  }
}
