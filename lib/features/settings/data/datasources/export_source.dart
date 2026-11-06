import 'dart:io';
import 'package:csv/csv.dart';
import 'package:drift/drift.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/members_dao.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/status_chip.dart';

abstract class ExportSource {
  Future<File> exportMembersCsv({
    MemberStatusType? statusFilter,
    bool includeNotes = false,
  });

  Future<File> exportMembersPdf({
    MemberStatusType? statusFilter,
    bool includeNotes = false,
  });
}

class ExportMemberRowData {
  final Member member;
  final Subscription? subscription;
  final Package? package;
  final MemberStatusType status;
  final String notes;

  const ExportMemberRowData({
    required this.member,
    this.subscription,
    this.package,
    required this.status,
    this.notes = '',
  });

  String get genderArabic => member.gender == 'female' ? 'أنثى' : 'ذكر';

  String get bmi {
    final w = member.weightKg;
    final h = member.heightCm;
    if (w != null && h != null && h > 0) {
      final hM = h / 100.0;
      return (w / (hM * hM)).toStringAsFixed(1);
    }
    return '-';
  }

  String get statusArabic {
    switch (status) {
      case MemberStatusType.active:
        return 'نشط';
      case MemberStatusType.expiringSoon:
        return 'ينتهي قريباً';
      case MemberStatusType.expired:
        return 'منتهي';
      case MemberStatusType.paused:
        return 'موقوف';
      case MemberStatusType.hasDues:
        return 'عليه مستحقات';
    }
  }

  String get outstandingBalance {
    if (subscription == null) return '0';
    final due = subscription!.priceSnapshot ?? package?.price ?? 0.0;
    final remaining = (due - subscription!.amountPaid).clamp(0.0, double.infinity);
    return CurrencyFormatter.format(remaining);
  }

  String get startDateFormatted => subscription?.startDate != null
      ? DateFormat('yyyy-MM-dd').format(subscription!.startDate)
      : '-';

  String get endDateFormatted => subscription?.endDate != null
      ? DateFormat('yyyy-MM-dd').format(subscription!.endDate)
      : '-';
}

class ExportSourceImpl implements ExportSource {
  final AppDatabase db;
  final MembersDao membersDao;

  ExportSourceImpl({
    required this.db,
    required this.membersDao,
  });

  Future<List<ExportMemberRowData>> _fetchMemberRows({
    MemberStatusType? statusFilter,
    bool includeNotes = false,
  }) async {
    final list = await membersDao
        .watchMembersWithStatus(statusFilter: statusFilter)
        .first;

    final result = <ExportMemberRowData>[];
    for (final item in list) {
      String notesText = '';
      if (includeNotes) {
        final notes = await (db.select(db.memberNotes)
              ..where((n) => n.memberId.equals(item.member.id))
              ..orderBy([(n) => OrderingTerm.desc(n.createdAt)]))
            .get();
        if (notes.isNotEmpty) {
          notesText = notes.map((n) => n.note).join(' | ');
        }
      }

      result.add(
        ExportMemberRowData(
          member: item.member,
          subscription: item.subscription,
          package: item.package,
          status: item.status,
          notes: notesText,
        ),
      );
    }
    return result;
  }

  @override
  Future<File> exportMembersCsv({
    MemberStatusType? statusFilter,
    bool includeNotes = false,
  }) async {
    final rows = await _fetchMemberRows(
      statusFilter: statusFilter,
      includeNotes: includeNotes,
    );

    final csvData = <List<dynamic>>[];

    final headers = [
      'الاسم',
      'رقم الهاتف',
      'العمر',
      'الوزن (كغ)',
      'الطول (سم)',
      'الجنس',
      'مؤشر كتلة الجسم (BMI)',
      'الحالة',
      'الباقة الحالية',
      'تاريخ البدء',
      'تاريخ الانتهاء',
      'المبلغ المتبقي',
    ];
    if (includeNotes) {
      headers.add('الملاحظات');
    }
    csvData.add(headers);

    for (final row in rows) {
      final line = [
        row.member.name,
        row.member.phone,
        row.member.age?.toString() ?? '-',
        row.member.weightKg != null ? row.member.weightKg.toString() : '-',
        row.member.heightCm != null ? row.member.heightCm.toString() : '-',
        row.genderArabic,
        row.bmi,
        row.statusArabic,
        row.package?.name ?? '-',
        row.startDateFormatted,
        row.endDateFormatted,
        row.outstandingBalance,
      ];
      if (includeNotes) {
        line.add(row.notes);
      }
      csvData.add(line);
    }

    // Encode CSV with UTF-8 BOM so Microsoft Excel renders Arabic text properly
    final csvString = Csv(addBom: true).encode(csvData);

    final tempDir = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    final file = File(p.join(tempDir.path, 'members_export_$timestamp.csv'));
    await file.writeAsString(csvString, flush: true);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: 'تصدير بيانات المشتركين (CSV)',
      ),
    );

    return file;
  }

  @override
  Future<File> exportMembersPdf({
    MemberStatusType? statusFilter,
    bool includeNotes = false,
  }) async {
    final rows = await _fetchMemberRows(
      statusFilter: statusFilter,
      includeNotes: includeNotes,
    );

    // Load Arabic Cairo font with fallback
    pw.Font cairoRegular;
    pw.Font cairoBold;
    try {
      cairoRegular = await PdfGoogleFonts.cairoRegular();
      cairoBold = await PdfGoogleFonts.cairoBold();
    } catch (_) {
      cairoRegular = pw.Font.helvetica();
      cairoBold = pw.Font.helveticaBold();
    }

    final doc = pw.Document(
      theme: pw.ThemeData.withFont(
        base: cairoRegular,
        bold: cairoBold,
      ),
    );

    final nowFormatted = DateFormat('yyyy/MM/dd - hh:mm a').format(DateTime.now());
    final filterLabel = _formatStatusFilterLabel(statusFilter);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        textDirection: pw.TextDirection.rtl,
        header: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        AppConstants.appName,
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: const PdfColor.fromInt(0xFFF26B1D),
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'تقرير المشتركين',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: const PdfColor.fromInt(0xFF1B2130),
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        nowFormatted,
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: PdfColor.fromInt(0xFF5B6475),
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'الفلتر: $filterLabel | إجمالي: ${rows.length}',
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: PdfColor.fromInt(0xFF5B6475),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Divider(color: const PdfColor.fromInt(0xFFE3E6EC), thickness: 1),
              pw.SizedBox(height: 8),
            ],
          );
        },
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.center,
            margin: const pw.EdgeInsets.only(top: 12),
            child: pw.Text(
              'صفحة ${context.pageNumber} من ${context.pagesCount}',
              textDirection: pw.TextDirection.rtl,
              style: const pw.TextStyle(
                fontSize: 9,
                color: PdfColor.fromInt(0xFF9AA1AF),
              ),
            ),
          );
        },
        build: (pw.Context context) {
          final tableHeaders = [
            'الاسم',
            'رقم الهاتف',
            'الجنس',
            'الحالة',
            'الباقة',
            'الانتهاء',
            'المتبقي',
          ];
          if (includeNotes) {
            tableHeaders.add('الملاحظات');
          }

          final tableData = rows.map((row) {
            final line = [
              row.member.name,
              row.member.phone,
              row.genderArabic,
              row.statusArabic,
              row.package?.name ?? '-',
              row.endDateFormatted,
              row.outstandingBalance,
            ];
            if (includeNotes) {
              line.add(row.notes.isEmpty ? '-' : row.notes);
            }
            return line;
          }).toList();

          return [
            pw.TableHelper.fromTextArray(
              headers: tableHeaders,
              data: tableData,
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 9,
                color: const PdfColor.fromInt(0xFF1B2130),
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFF1F3F6), // surfaceVariant
              ),
              cellStyle: const pw.TextStyle(
                fontSize: 8.5,
                color: PdfColor.fromInt(0xFF1B2130),
              ),
              cellAlignment: pw.Alignment.center,
              headerAlignment: pw.Alignment.center,
              cellPadding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              rowDecoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(
                    color: PdfColor.fromInt(0xFFE3E6EC),
                    width: 0.5,
                  ),
                ),
              ),
            ),
          ];
        },
      ),
    );

    final tempDir = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    final file = File(p.join(tempDir.path, 'members_export_$timestamp.pdf'));
    await file.writeAsBytes(await doc.save(), flush: true);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: 'تصدير بيانات المشتركين (PDF)',
      ),
    );

    return file;
  }

  String _formatStatusFilterLabel(MemberStatusType? status) {
    if (status == null) return 'الكل';
    switch (status) {
      case MemberStatusType.active:
        return 'نشط';
      case MemberStatusType.expiringSoon:
        return 'ينتهي قريباً';
      case MemberStatusType.expired:
        return 'منتهي';
      case MemberStatusType.paused:
        return 'موقوف';
      case MemberStatusType.hasDues:
        return 'عليهم مستحقات';
    }
  }
}
