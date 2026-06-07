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
      'NotoSansGujarati-Regular.ttf': 'ગુજરાતી',
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

  test('English labels and multilingual names render together', () async {
    final fallbackFonts = <pw.Font>[];
    for (final file in [
      'NotoSansDevanagari-Regular.ttf',
      'NotoSansTamil-Regular.ttf',
      'NotoSansTelugu-Regular.ttf',
      'NotoSansMalayalam-Regular.ttf',
      'NotoSansKannada-Regular.ttf',
      'NotoSansGurmukhi-Regular.ttf',
      'NotoSansBengali-Regular.ttf',
      'NotoSansOriya-Regular.ttf',
      'NotoSansGujarati-Regular.ttf',
    ]) {
      fallbackFonts.add(
        pw.Font.ttf(await rootBundle.load('assets/fonts/$file')),
      );
    }
    final document = pw.Document()
      ..addPage(
        pw.Page(
          theme: pw.ThemeData.withFont(
            base: pw.Font.helvetica(),
            bold: pw.Font.helveticaBold(),
            fontFallback: fallbackFonts,
          ),
          build: (_) => pw.Text(
            'CRIC SCORE PRO | Batting | Bowling | हिंदी | தமிழ் | ગુજરાતી',
          ),
        ),
      );

    expect((await document.save()).length, greaterThan(1000));
  });
}
