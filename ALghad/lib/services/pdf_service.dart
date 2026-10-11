import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/app_models.dart';

class PdfService {
  static Future<File> generateRegistrationPdf(OnlineRegistrationForm form) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Padding(
              padding: const pw.EdgeInsets.all(24),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Header
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.indigo900,
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Column(
                      children: [
                        pw.Text(
                          'كلية الغد المشرق العلوم الطبية والتطبيقية',
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'استمارة التسجيل والقبول الإلكتروني',
                          style: pw.TextStyle(
                            fontSize: 14,
                            color: PdfColors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 16),

                  // Section 1: Personal Info
                  _buildPdfSectionTitle('1. البيانات الشخصية للطالب:'),
                  _buildPdfRow('الاسم الكامل:', '${form.firstName} ${form.fatherName} ${form.grandfatherName} ${form.lastName}'),
                  _buildPdfRow('الجنسية:', form.nationality),
                  _buildPdfRow('تاريخ الميلاد:', form.birthDate),
                  _buildPdfRow('مكان الميلاد:', form.birthPlace),
                  _buildPdfRow('الجنس:', form.gender),
                  _buildPdfRow('البريد الإلكتروني:', form.email),
                  _buildPdfRow('رقم هاتف الطالب:', form.studentPhone),
                  _buildPdfRow('رقم هاتف ولي الأمر:', form.parentPhone),
                  pw.SizedBox(height: 12),

                  // Section 2: Educational Info
                  _buildPdfSectionTitle('2. بيانات المؤهل والوثائق:'),
                  _buildPdfRow('نوع الشهادة:', form.certificateType),
                  _buildPdfRow('رقم الجلوس:', form.seatingNumber),
                  _buildPdfRow('المعدل العام:', '${form.gpaPercentage}%'),
                  _buildPdfRow('عام التخرج:', form.graduationYear),
                  _buildPdfRow('الوثائق المرفقة المحددة:', 
                    [
                      if (form.hasOriginalCert) 'أصل الشهادة',
                      if (form.hasTrueCopyCert) 'صورة طبق الأصل',
                      if (form.hasPersonalPhotos) '10 صور شخصية 4x6',
                      if (form.hasIdCopy) 'صورة البطاقة الشخصية',
                    ].join(' - ')
                  ),
                  pw.SizedBox(height: 12),

                  // Section 3: Specialty Choices & Declaration
                  _buildPdfSectionTitle('3. التخصص المختار والتعهد:'),
                  if (form.bachelorSpecialty.isNotEmpty)
                    _buildPdfRow('تخصص البكالوريوس المختار:', form.bachelorSpecialty),
                  if (form.diplomaSpecialty.isNotEmpty)
                    _buildPdfRow('تخصص الدبلوم المختار:', form.diplomaSpecialty),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'الإقرار والتعهد: أتعهد بأن كافة البيانات المدونة أعلاه صحيحة وأتحمل كافة التبعيات القانونية، وأتعهد بالتزام كافة الأنظمة واللوائح بالكلية.',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
                  ),

                  pw.Spacer(),

                  // Footer
                  pw.Divider(color: PdfColors.grey400),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('تاريخ الإرسال: ${DateTime.now().toString().split(' ')[0]}', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('تم إنشاء هذا التقرير تلقائياً عبر تطبيق الغد المشرق', style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    final outputDir = await getApplicationDocumentsDirectory();
    final file = File('${outputDir.path}/registration_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static Future<void> sendPdfToWhatsApp({
    required File pdfFile,
    required OnlineRegistrationForm form,
    required String targetPhone,
  }) async {
    final String textSummary = Uri.encodeComponent(
      'طلب تسجيل أونلاين جديد - كلية الغد المشرق:\n'
      '-----------------------------------------\n'
      'اسم الطالب: ${form.firstName} ${form.fatherName} ${form.grandfatherName} ${form.lastName}\n'
      'رقم الهاتف: ${form.studentPhone}\n'
      'التخصص المختار: ${form.bachelorSpecialty.isNotEmpty ? form.bachelorSpecialty : form.diplomaSpecialty}\n'
      'المعدل: ${form.gpaPercentage}%\n'
      'رقم الجلوس: ${form.seatingNumber}\n'
      'تم إنشاء ملف PDF بحجم ${pdfFile.lengthSync()} بايت وحفظه في الجهاز.\n'
      'يرجى تأكيد الاستلام.',
    );

    final String whatsappUrl = 'whatsapp://send?phone=$targetPhone&text=$textSummary';
    final Uri uri = Uri.parse(whatsappUrl);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      final Uri webUri = Uri.parse('https://api.whatsapp.com/send?phone=$targetPhone&text=$textSummary');
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }

  static pw.Widget _buildPdfSectionTitle(String title) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 12,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.indigo900,
        ),
      ),
    );
  }

  static pw.Widget _buildPdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.Text(
            '$label ',
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            value,
            style: const pw.TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }
}
