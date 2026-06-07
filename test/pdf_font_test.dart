import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bundled script fonts render localized PDF text', () async {
    final samples = {
      'NotoSansDevanagari-Regular.ttf': 'हिन्दी',
      'NotoSansTamil-Regular.ttf': 'தமிழ்',
      'NotoSansTelugu-Regular.ttf': 'తెలుగు',
      'NotoSansMalayalam-Regular.ttf': 'മലയാളം',
      'NotoSansKannada-Regular.ttf': 'ಕನ್ನಡ',
      'NotoSansGurmukhi-Regular.ttf': 'ਪੰਜਾਬੀ',
      'NotoSansBengali-Regular.ttf': 'বাংলা অসমীয়া',
      'NotoSansOriya-Regular.ttf': 'ଓଡ଼ିଆ',
    };
    for (final entry in samples.entries) {
      final font = pw.Font.ttf(
        await rootBundle.load('assets/fonts/${entry.key}'),
      );
      final document = pw.Document()
        ..addPage(
          pw.Page(
            theme: pw.ThemeData.withFont(base: font, bold: font),
            build: (_) => pw.Text(entry.value),
          ),
        );
      expect((await document.save()).isNotEmpty, isTrue);
    }
  });
}
