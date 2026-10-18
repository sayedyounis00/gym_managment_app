import 'package:csv/csv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CSV Export with Arabic Text & Commas Tests', () {
    test('prepends UTF-8 BOM so Excel opens Arabic correctly', () {
      final rows = [
        ['الاسم', 'رقم الهاتف', 'الحالة'],
        ['محمد أحمد', '01012345678', 'نشط'],
      ];

      final csvContent = Csv(addBom: true).encode(rows);

      // Verify starts with UTF-8 BOM (\uFEFF)
      expect(csvContent.startsWith('\uFEFF'), isTrue);
      expect(csvContent.contains('محمد أحمد'), isTrue);
      expect(csvContent.contains('01012345678'), isTrue);
    });

    test('escapes Arabic text containing commas and quotes properly', () {
      final rows = [
        ['الاسم', 'الملاحظات'],
        ['أحمد، محمود "علي"', 'يعاني من إصابة، يحتاج راحة'],
        ['خالد "البطل"', 'ملاحظة عادية'],
      ];

      final csvContent = Csv(addBom: true).encode(rows);

      // Should be parsed back identically
      // Strip BOM before decoding
      final withoutBom = csvContent.replaceFirst('\uFEFF', '');
      final decoded = Csv().decode(withoutBom);

      expect(decoded.length, equals(3));
      expect(decoded[1][0], equals('أحمد، محمود "علي"'));
      expect(decoded[1][1], equals('يعاني من إصابة، يحتاج راحة'));
      expect(decoded[2][0], equals('خالد "البطل"'));
      expect(decoded[2][1], equals('ملاحظة عادية'));
    });

    test('formats all 12 member export columns accurately', () {
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

      final row = [
        'سارة إبراهيم',
        '01198765432',
        '25',
        '65.0',
        '168.0',
        'أنثى',
        '23.0',
        'نشط',
        'باقة ذهبية 3 شهور',
        '2026-01-01',
        '2026-04-01',
        '0',
      ];

      final csvContent = Csv(addBom: true).encode([headers, row]);
      expect(csvContent, contains('سارة إبراهيم'));
      expect(csvContent, contains('باقة ذهبية 3 شهور'));
      expect(csvContent, contains('23.0'));
      expect(csvContent, contains('أنثى'));
    });
  });
}
