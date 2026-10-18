import 'dart:io';
import 'package:fpdart/fpdart.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/database/daos/finance_dao.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/daily_total.dart';
import '../../domain/entities/finance_enums.dart';
import '../../domain/entities/finance_summary.dart';
import '../../domain/entities/ledger_entry.dart';
import '../../domain/entities/member_balance.dart';
import '../../domain/repositories/finance_repository.dart';
import '../models/finance_summary_model.dart';
import '../models/ledger_entry_model.dart';

class FinanceRepositoryImpl implements FinanceRepository {
  final FinanceDao financeDao;

  FinanceRepositoryImpl({required this.financeDao});

  @override
  Stream<FinanceSummary> watchSummary(DateTime month) {
    return financeDao
        .watchMonthlySummary(month)
        .map(FinanceSummaryModel.fromDao);
  }

  @override
  Future<Either<Failure, FinanceSummary>> getSummary(DateTime month) async {
    try {
      final summaryRow = await financeDao.getMonthlySummary(month);
      return Right(FinanceSummaryModel.fromDao(summaryRow));
    } catch (e) {
      return Left(DatabaseFailure('فشل جلب الملخص المالي: $e'));
    }
  }

  @override
  Stream<List<LedgerEntry>> watchLedger({
    DateTime? from,
    DateTime? to,
    LedgerType? filter,
  }) {
    return financeDao
        .watchLedger(from: from, to: to, typeFilter: filter?.value)
        .map((rows) => rows.map(LedgerEntryModel.fromDao).toList());
  }

  @override
  Future<Either<Failure, List<DailyTotal>>> getDailyTotals({
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      final rows = await financeDao.getDailyTotals(from: from, to: to);
      final totals = rows
          .map((r) => DailyTotal(
                date: r.date,
                revenue: r.revenue,
                expenses: r.expenses,
                net: r.net,
              ))
          .toList();
      return Right(totals);
    } catch (e) {
      return Left(DatabaseFailure('فشل جلب المجاميع اليومية: $e'));
    }
  }

  @override
  Future<Either<Failure, List<MemberBalance>>> getMembersWithBalance() async {
    try {
      final rows = await financeDao.getMembersWithBalance();
      final balances = rows
          .map((r) => MemberBalance(
                memberId: r.memberId,
                memberName: r.memberName,
                memberPhone: r.memberPhone,
                memberAvatarUrl: r.memberAvatarUrl,
                totalDue: r.totalDue,
                totalPaid: r.totalPaid,
                remaining: r.remaining,
                lastPaymentDate: r.lastPaymentDate,
                activeSubscriptionId: r.activeSubscriptionId,
                activePackageName: r.activePackageName,
              ))
          .toList();
      return Right(balances);
    } catch (e) {
      return Left(DatabaseFailure('فشل جلب أرصدة المشتركين: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> exportReportPdf(DateTime month) async {
    try {
      final start = DateTime(month.year, month.month, 1);
      final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59, 999);

      final summaryRow = await financeDao.getMonthlySummary(month);
      final rawEntries = await financeDao.getLedgerEntries(from: start, to: end);
      final entries = rawEntries.map(LedgerEntryModel.fromDao).toList();

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

      final monthName = DateFormat('MMMM yyyy', 'ar').format(month);
      final generatedAt = DateFormat('yyyy/MM/dd - hh:mm a', 'ar').format(DateTime.now());

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
                          'التقرير المالي الشهري - $monthName',
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
                          'تاريخ الإنشاء: $generatedAt',
                          style: const pw.TextStyle(
                            fontSize: 9,
                            color: PdfColor.fromInt(0xFF5B6475),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 12),
                // 3-Cell Summary
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: const PdfColor.fromInt(0xFFF7F8FA),
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: const PdfColor.fromInt(0xFFE3E6EC)),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                    children: [
                      pw.Column(
                        children: [
                          pw.Text('الإيرادات', style: const pw.TextStyle(fontSize: 11, color: PdfColor.fromInt(0xFF5B6475))),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            CurrencyFormatter.format(summaryRow.revenue),
                            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF1E9E5A)),
                          ),
                        ],
                      ),
                      pw.Column(
                        children: [
                          pw.Text('المصروفات', style: const pw.TextStyle(fontSize: 11, color: PdfColor.fromInt(0xFF5B6475))),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            CurrencyFormatter.format(summaryRow.expenses),
                            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFFD93C3C)),
                          ),
                        ],
                      ),
                      pw.Column(
                        children: [
                          pw.Text('صافي الربح (تقديري)', style: const pw.TextStyle(fontSize: 11, color: PdfColor.fromInt(0xFF5B6475))),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            CurrencyFormatter.format(summaryRow.net),
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              color: summaryRow.net >= 0 ? const PdfColor.fromInt(0xFF1E9E5A) : const PdfColor.fromInt(0xFFD93C3C),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 16),
                pw.Divider(color: const PdfColor.fromInt(0xFFE3E6EC), thickness: 1),
                pw.SizedBox(height: 8),
              ],
            );
          },
          build: (pw.Context context) {
            return [
              pw.Text(
                'سجل المعاملات (${entries.length})',
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF1B2130)),
              ),
              pw.SizedBox(height: 8),
              if (entries.isEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 32),
                  child: pw.Center(
                    child: pw.Text(
                      'لا توجد معاملات مسجلة في هذا الشهر',
                      style: const pw.TextStyle(fontSize: 12, color: PdfColor.fromInt(0xFF9AA1AF)),
                    ),
                  ),
                )
              else
                pw.TableHelper.fromTextArray(
                  context: context,
                  cellAlignment: pw.Alignment.centerRight,
                  headerAlignment: pw.Alignment.centerRight,
                  headerStyle: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: const PdfColor.fromInt(0xFF5B6475),
                  ),
                  cellStyle: const pw.TextStyle(fontSize: 9, color: PdfColor.fromInt(0xFF1B2130)),
                  headerDecoration: const pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFFF1F3F6),
                  ),
                  headers: const ['التاريخ', 'النوع', 'البيان', 'طريقة الدفع', 'المبلغ', 'الحالة'],
                  data: entries.map((e) {
                    final dateStr = DateFormat('yyyy/MM/dd').format(e.date);
                    final typeStr = e.type == LedgerType.income ? 'إيراد' : 'مصروف';
                    final methodStr = e.method?.labelArabic ?? '-';
                    final amountStr = '${e.type == LedgerType.income ? '+' : '-'}${CurrencyFormatter.format(e.amount)}';
                    final statusStr = e.isVoided ? 'ملغاة' : 'نشطة';

                    return [
                      dateStr,
                      typeStr,
                      e.title,
                      methodStr,
                      amountStr,
                      statusStr,
                    ];
                  }).toList(),
                ),
            ];
          },
          footer: (pw.Context context) {
            return pw.Container(
              alignment: pw.Alignment.center,
              margin: const pw.EdgeInsets.only(top: 12),
              child: pw.Text(
                'صفحة ${context.pageNumber} من ${context.pagesCount}',
                style: const pw.TextStyle(fontSize: 8, color: PdfColor.fromInt(0xFF9AA1AF)),
              ),
            );
          },
        ),
      );

      final dir = await getTemporaryDirectory();
      final sanitizedMonth = DateFormat('yyyy_MM').format(month);
      final file = File(p.join(dir.path, 'finance_report_$sanitizedMonth.pdf'));
      await file.writeAsBytes(await doc.save());

      return Right(file.path);
    } catch (e) {
      return Left(ExportFailure('فشل تصدير التقرير PDF: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> exportReportCsv(DateTime month) async {
    try {
      final start = DateTime(month.year, month.month, 1);
      final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59, 999);

      final rawEntries = await financeDao.getLedgerEntries(from: start, to: end);
      final entries = rawEntries.map(LedgerEntryModel.fromDao).toList();

      final List<List<dynamic>> csvData = [
        ['المعرف', 'التاريخ', 'النوع', 'البيان', 'التفاصيل', 'طريقة الدفع', 'المبلغ (ج.م)', 'ملغاة', 'سبب الإلغاء'],
      ];

      for (final e in entries) {
        csvData.add([
          e.originalId,
          DateFormat('yyyy-MM-dd HH:mm').format(e.date),
          e.type == LedgerType.income ? 'إيراد' : 'مصروف',
          e.title,
          e.subtitle ?? '',
          e.method?.labelArabic ?? '',
          e.amount,
          e.isVoided ? 'نعم' : 'لا',
          e.voidReason ?? '',
        ]);
      }

      // Add UTF-8 BOM so Excel opens Arabic correctly
      final csvBody = csvData.map((row) {
        return row.map((cell) {
          final str = cell?.toString() ?? '';
          if (str.contains(',') || str.contains('"') || str.contains('\n') || str.contains('\r')) {
            return '"${str.replaceAll('"', '""')}"';
          }
          return str;
        }).join(',');
      }).join('\r\n');
      final csvString = '\uFEFF$csvBody';

      final dir = await getTemporaryDirectory();
      final sanitizedMonth = DateFormat('yyyy_MM').format(month);
      final file = File(p.join(dir.path, 'finance_report_$sanitizedMonth.csv'));
      await file.writeAsString(csvString);

      return Right(file.path);
    } catch (e) {
      return Left(ExportFailure('فشل تصدير التقرير CSV: $e'));
    }
  }
}
