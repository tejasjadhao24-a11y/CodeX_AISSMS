import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart' show debugPrint;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/certificate_model.dart';
import '../models/ride_model.dart';

class CertificateService {
  // ── Colours ──────────────────────────────────────────────────────────────
  static const _navy     = PdfColor.fromInt(0xFF0D2149);
  static const _gold     = PdfColor.fromInt(0xFFF5A623);
  static const _goldDim  = PdfColor.fromInt(0xFFD4881A);
  static const _white    = PdfColors.white;
  static const _darkTxt  = PdfColor.fromInt(0xFF0F172A);
  static const _greyTxt  = PdfColor.fromInt(0xFF64748B);

  // Level badge text — safe unicode that all fonts render
  static String _levelLabel(CertificateLevel level) {
    switch (level.level) {
      case 1: return 'GREEN RIDER';
      case 2: return 'CAMPUS CHAMPION';
      case 3: return 'ECO WARRIOR';
      case 4: return 'CAMPUSLIFT LEGEND';
      default: return 'NEW RIDER';
    }
  }

  static String _levelStar(CertificateLevel level) {
    switch (level.level) {
      case 1: return '*';
      case 2: return '**';
      case 3: return '***';
      case 4: return '****';
      default: return '';
    }
  }

  // ── Font cache ────────────────────────────────────────────────────────────
  static pw.Font? _fontReg;
  static pw.Font? _fontBold;
  static pw.Font? _fontItal;
  static pw.Font? _fontSans;

  static Future<void> _loadFonts() async {
    if (_fontBold != null) return;
    try {
      final fonts = await Future.wait([
        PdfGoogleFonts.playfairDisplayRegular(),
        PdfGoogleFonts.playfairDisplayBold(),
        PdfGoogleFonts.playfairDisplayItalic(),
        PdfGoogleFonts.montserratRegular(),
      ]).timeout(const Duration(seconds: 3));
      _fontReg  = fonts[0];
      _fontBold = fonts[1];
      _fontItal = fonts[2];
      _fontSans = fonts[3];
    } catch (e) {
      debugPrint('PdfGoogleFonts offline/timeout, falling back to standard fonts: $e');
      _fontReg  = pw.Font.times();
      _fontBold = pw.Font.timesBold();
      _fontItal = pw.Font.timesItalic();
      _fontSans = pw.Font.helvetica();
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  Generate PDF
  // ──────────────────────────────────────────────────────────────────────────
  static Future<Uint8List> generateCertificatePdf({
    required String recipientName,
    required String collegeName,
    required int points,
    required CertificateLevel level,
    String? prn,
  }) async {
    await _loadFonts();

    final doc    = pw.Document();
    final date   = DateFormat('dd MMMM yyyy').format(DateTime.now());
    final certId = 'CL-${DateTime.now().year}-${points.toString().padLeft(5, '0')}';
    final accent = PdfColor.fromInt(0xFF000000 | level.primaryColor.toARGB32() & 0x00FFFFFF);
    final accentL= PdfColor.fromInt(0xFF000000 | level.accentColor.toARGB32() & 0x00FFFFFF);

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: pw.EdgeInsets.zero,
        build: (ctx) => _buildPage(
          ctx,
          recipientName: recipientName,
          collegeName: collegeName,
          points: points,
          level: level,
          date: date,
          certId: certId,
          prn: prn,
          accent: accent,
          accentLight: accentL,
        ),
      ),
    );

    return doc.save();
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  Page builder — clean design, elegant and professional
  // ──────────────────────────────────────────────────────────────────────────
  static pw.Widget _buildPage(
    pw.Context ctx, {
    required String recipientName,
    required String collegeName,
    required int points,
    required CertificateLevel level,
    required String date,
    required String certId,
    required String? prn,
    required PdfColor accent,
    required PdfColor accentLight,
  }) {
    final reg  = pw.TextStyle(font: _fontReg);
    final bold = pw.TextStyle(font: _fontBold);
    final ital = pw.TextStyle(font: _fontItal);
    final sans = pw.TextStyle(font: _fontSans);

    const outerMargin = 20.0;
    const innerMargin = 32.0;

    return pw.Stack(
      children: [
        // ── 1. Background ──────────────────────────────────────
        pw.Positioned.fill(
          child: pw.Container(color: const PdfColor.fromInt(0xFFFCFDF9)),
        ),

        // ── 2. Outer border (Thick Navy) ───────────────────────
        pw.Positioned(
          top: outerMargin, left: outerMargin, right: outerMargin, bottom: outerMargin,
          child: pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _navy, width: 3),
            ),
          ),
        ),
        
        // ── 3. Inner border (Thin Gold) ────────────────────────
        pw.Positioned(
          top: innerMargin, left: innerMargin, right: innerMargin, bottom: innerMargin,
          child: pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _gold, width: 1.5),
            ),
          ),
        ),

        // ── 4. Corner Ornaments ────────────────────────────────
        pw.Positioned(top: outerMargin - 4, left: outerMargin - 4, child: _cornerOrnament()),
        pw.Positioned(top: outerMargin - 4, right: outerMargin - 4, child: _cornerOrnament()),
        pw.Positioned(bottom: outerMargin - 4, left: outerMargin - 4, child: _cornerOrnament()),
        pw.Positioned(bottom: outerMargin - 4, right: outerMargin - 4, child: _cornerOrnament()),

        // ── 5. Content Column ──────────────────────────────────
        pw.Positioned.fill(
          child: pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(60, 45, 60, 35),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.SizedBox(height: 10),
                // Title
                pw.Text(
                  'CERTIFICATE',
                  style: bold.copyWith(
                    fontSize: 52, color: _gold, letterSpacing: 8,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'O F   A C H I E V E M E N T',
                  style: sans.copyWith(
                    fontSize: 12, color: _navy, letterSpacing: 4,
                  ),
                ),
                pw.SizedBox(height: 24),
                
                // Presented to
                pw.Text(
                  'PROUDLY PRESENTED TO',
                  style: sans.copyWith(fontSize: 11, color: _greyTxt, letterSpacing: 2),
                ),
                pw.SizedBox(height: 12),
                
                // Name
                pw.Text(
                  recipientName,
                  style: ital.copyWith(fontSize: 46, color: _navy),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 8),
                pw.Container(
                  width: 320, height: 1.5,
                  color: _gold,
                ),
                pw.SizedBox(height: 16),
                
                // Description
                pw.Text(
                  'For outstanding commitment to sustainable campus mobility',
                  style: reg.copyWith(fontSize: 13, color: _darkTxt),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  'on the CampusLift platform, achieving the honorable rank of',
                  style: reg.copyWith(fontSize: 13, color: _darkTxt),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 16),
                
                // Level
                pw.Text(
                  _levelLabel(level),
                  style: bold.copyWith(
                    fontSize: 20, color: accent, letterSpacing: 2,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  'with $points points earned   |   ${_levelStar(level)}',
                  style: sans.copyWith(fontSize: 10, color: _greyTxt),
                ),
                
                pw.Spacer(),
                
                // Bottom section (Signatures & Seal)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    _signature('Date', date, bold, sans, ital),
                    _goldSeal(level, accent, bold, sans),
                    _signature('Signature', 'Platform Director', bold, sans, ital),
                  ],
                ),
                pw.SizedBox(height: 10),
                
                // Footer
                pw.Text(
                  'Certificate ID: $certId   •   Valid for: $collegeName${prn != null && prn.isNotEmpty ? '   •   PRN: $prn' : ''}',
                  style: sans.copyWith(fontSize: 8, color: _greyTxt)
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Helper widgets ────────────────────────────────────────────────────────

  static pw.Widget _cornerOrnament() {
    return pw.Container(
      width: 24, height: 24,
      decoration: pw.BoxDecoration(
        color: _white,
        border: pw.Border.all(color: _navy, width: 2),
      ),
      child: pw.Center(
        child: pw.Container(
          width: 10, height: 10,
          color: _gold,
        ),
      ),
    );
  }

  static pw.Widget _signature(String label, String value, pw.TextStyle bold, pw.TextStyle sans, pw.TextStyle ital) {
    final isDate = value.contains(RegExp(r'[0-9]'));
    return pw.Container(
      width: 140,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            value, 
            style: isDate ? sans.copyWith(fontSize: 12, color: _navy) : ital.copyWith(fontSize: 16, color: _navy)
          ),
          pw.SizedBox(height: 6),
          pw.Container(width: 140, height: 1, color: _navy),
          pw.SizedBox(height: 6),
          pw.Text(
            label, 
            style: sans.copyWith(fontSize: 9, color: _greyTxt, letterSpacing: 1)
          ),
        ],
      ),
    );
  }

  static pw.Widget _goldSeal(CertificateLevel level, PdfColor accent, pw.TextStyle bold, pw.TextStyle sans) {
    return pw.Container(
      width: 110, height: 110,
      child: pw.Stack(
        alignment: pw.Alignment.center,
        children: [
          // ribbons
          pw.Positioned(
            bottom: -8, left: 24,
            child: pw.Transform.rotate(
              angle: 0.4,
              child: pw.Container(
                width: 20, height: 45, 
                color: _goldDim,
              ),
            ),
          ),
          pw.Positioned(
            bottom: -8, right: 24,
            child: pw.Transform.rotate(
              angle: -0.4,
              child: pw.Container(
                width: 20, height: 45, 
                color: _goldDim,
              ),
            ),
          ),
          // outer circle
          pw.Container(
            width: 90, height: 90,
            decoration: const pw.BoxDecoration(
              shape: pw.BoxShape.circle,
              color: _gold,
            ),
          ),
          // inner circles
          pw.Container(
            width: 78, height: 78,
            decoration: pw.BoxDecoration(
              shape: pw.BoxShape.circle,
              border: pw.Border.all(color: _white, width: 1.5),
              color: _gold,
            ),
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text('CAMPUS', style: bold.copyWith(fontSize: 9, color: _white, letterSpacing: 1.5)),
                pw.Text('LIFT', style: bold.copyWith(fontSize: 13, color: _navy, letterSpacing: 1.5)),
                pw.SizedBox(height: 2),
                pw.Container(height: 1, width: 45, color: _white),
                pw.SizedBox(height: 2),
                pw.Text('Lv.${level.level}', style: sans.copyWith(fontSize: 11, color: _white)),
              ],
            ),
          ),
        ],
      )
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  Public API
  // ──────────────────────────────────────────────────────────────────────────

  static Future<void> shareCertificate({
    required String recipientName,
    required String collegeName,
    required int points,
    required CertificateLevel level,
    String? prn,
  }) async {
    final bytes = await generateCertificatePdf(
      recipientName: recipientName,
      collegeName: collegeName,
      points: points,
      level: level,
      prn: prn,
    );
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'CampusLift_Certificate_${level.title.replaceAll(' ', '_')}.pdf',
    );
  }

  static Future<File> saveCertificateLocally({
    required String recipientName,
    required String collegeName,
    required int points,
    required CertificateLevel level,
    String? prn,
  }) async {
    final bytes = await generateCertificatePdf(
      recipientName: recipientName,
      collegeName: collegeName,
      points: points,
      level: level,
      prn: prn,
    );

    final dir = await getApplicationDocumentsDirectory();
    final name     = level.title.replaceAll(' ', '_');
    final filePath = '${dir.path}/CampusLift_${name}_Certificate.pdf';
    final file     = File(filePath);
    await file.writeAsBytes(bytes);
    debugPrint('Certificate saved: $filePath');
    return file;
  }

  static Future<void> printCertificate({
    required String recipientName,
    required String collegeName,
    required int points,
    required CertificateLevel level,
    String? prn,
  }) async {
    await Printing.layoutPdf(
      name: 'CampusLift Certificate',
      onLayout: (_) async => generateCertificatePdf(
        recipientName: recipientName,
        collegeName: collegeName,
        points: points,
        level: level,
        prn: prn,
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  Ride Receipt / Trip Summary PDF
  // ──────────────────────────────────────────────────────────────────────────

  static Future<Uint8List> generateRideSummaryPdf({
    required RideModel ride,
    required bool isDriver,
    Map<String, dynamic>? receiptData,
  }) async {
    await _loadFonts();
    final doc = pw.Document();

    final receiptId = receiptData?['receiptId'] ??
        (ride.id.length >= 8 ? ride.id.substring(0, 8).toUpperCase() : ride.id.toUpperCase());
    final date = receiptData?['date'] ??
        (ride.completedAt != null
            ? DateFormat('dd MMM yyyy, hh:mm a').format(ride.completedAt!)
            : DateFormat('dd MMM yyyy, hh:mm a').format(ride.createdAt));
    final pName = receiptData?['passengerName'] ?? ride.passengerName;
    final dName = receiptData?['riderName'] ?? ride.riderName ?? 'CampusLift Driver';
    final pts = receiptData?['pointsAwarded'] ?? ride.pointsAwarded;
    final title = isDriver ? 'CAMPUSLIFT TRIP SUMMARY' : 'CAMPUSLIFT RIDE RECEIPT';
    final themeColor = isDriver ? const PdfColor.fromInt(0xFF0D9488) : _navy;

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header Bar
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: themeColor,
                borderRadius: pw.BorderRadius.circular(12),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'CAMPUSLIFT',
                        style: pw.TextStyle(
                          font: _fontBold,
                          color: _white,
                          fontSize: 22,
                          letterSpacing: 2,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        title,
                        style: pw.TextStyle(
                          font: _fontSans,
                          color: _gold,
                          fontSize: 12,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'ID: #$receiptId',
                        style: pw.TextStyle(
                          font: _fontBold,
                          color: _white,
                          fontSize: 14,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        date,
                        style: pw.TextStyle(
                          font: _fontSans,
                          color: const PdfColor.fromInt(0xFFE2E8F0),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 24),

            // Route Section
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: const PdfColor.fromInt(0xFFE2E8F0)),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'ROUTE INFORMATION',
                    style: pw.TextStyle(
                      font: _fontBold,
                      color: _greyTxt,
                      fontSize: 10,
                      letterSpacing: 1,
                    ),
                  ),
                  pw.SizedBox(height: 12),
                  pw.Row(
                    children: [
                      pw.Text('Pickup: ', style: pw.TextStyle(font: _fontBold, fontSize: 12)),
                      pw.Text(ride.fromLocation, style: pw.TextStyle(font: _fontSans, fontSize: 12)),
                    ],
                  ),
                  pw.SizedBox(height: 8),
                  pw.Row(
                    children: [
                      pw.Text('Destination: ', style: pw.TextStyle(font: _fontBold, fontSize: 12)),
                      pw.Text(ride.toLocation, style: pw.TextStyle(font: _fontSans, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // User Info Section
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: const PdfColor.fromInt(0xFFE2E8F0)),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'PASSENGER',
                        style: pw.TextStyle(font: _fontBold, color: _greyTxt, fontSize: 10, letterSpacing: 1),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(pName, style: pw.TextStyle(font: _fontBold, fontSize: 14)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'DRIVER',
                        style: pw.TextStyle(font: _fontBold, color: _greyTxt, fontSize: 10, letterSpacing: 1),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(dName, style: pw.TextStyle(font: _fontBold, fontSize: 14)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'STATUS',
                        style: pw.TextStyle(font: _fontBold, color: _greyTxt, fontSize: 10, letterSpacing: 1),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text('COMPLETED', style: pw.TextStyle(font: _fontBold, color: const PdfColor.fromInt(0xFF16A34A), fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // Points / Financial Section
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: const PdfColor.fromInt(0xFFF8FAFC),
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: const PdfColor.fromInt(0xFFE2E8F0)),
              ),
              child: pw.Column(
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        isDriver ? 'Driver Points Earned' : 'Points Deducted',
                        style: pw.TextStyle(font: _fontSans, fontSize: 12),
                      ),
                      pw.Text(
                        isDriver ? '+$pts pts' : '$pts pts',
                        style: pw.TextStyle(
                          font: _fontBold,
                          color: isDriver ? const PdfColor.fromInt(0xFF16A34A) : _navy,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  pw.Divider(color: const PdfColor.fromInt(0xFFCBD5E1)),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        isDriver ? 'Campus Green Credits' : 'Platform Convenience Fee',
                        style: pw.TextStyle(font: _fontSans, fontSize: 12),
                      ),
                      pw.Text(
                        isDriver ? 'Awarded (Eco-Friendly)' : 'Rs. 0 (Waived)',
                        style: pw.TextStyle(font: _fontBold, color: _greyTxt, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            pw.Spacer(),

            // Footer
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    'Thank you for traveling sustainably with CampusLift!',
                    style: pw.TextStyle(font: _fontItal, color: _greyTxt, fontSize: 11),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Campus Trips Made Easy * Built for Student Communities',
                    style: pw.TextStyle(font: _fontSans, color: const PdfColor.fromInt(0xFF94A3B8), fontSize: 9),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return doc.save();
  }

  static Future<void> shareRideSummaryPdf({
    required RideModel ride,
    required bool isDriver,
    Map<String, dynamic>? receiptData,
  }) async {
    final bytes = await generateRideSummaryPdf(
      ride: ride,
      isDriver: isDriver,
      receiptData: receiptData,
    );
    final prefix = isDriver ? 'Trip_Summary' : 'Ride_Receipt';
    final idSnippet = ride.id.length >= 6 ? ride.id.substring(0, 6) : ride.id;
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'CampusLift_${prefix}_$idSnippet.pdf',
    );
  }

  static Future<File> saveRideSummaryPdf({
    required RideModel ride,
    required bool isDriver,
    Map<String, dynamic>? receiptData,
  }) async {
    final bytes = await generateRideSummaryPdf(
      ride: ride,
      isDriver: isDriver,
      receiptData: receiptData,
    );
    final dir = await getApplicationDocumentsDirectory();
    final prefix = isDriver ? 'Trip_Summary' : 'Ride_Receipt';
    final idSnippet = ride.id.length >= 6 ? ride.id.substring(0, 6) : ride.id;
    final filePath = '${dir.path}/CampusLift_${prefix}_$idSnippet.pdf';
    final file = File(filePath);
    await file.writeAsBytes(bytes);
    debugPrint('Ride summary saved: $filePath');
    return file;
  }

  static Future<void> printRideSummaryPdf({
    required RideModel ride,
    required bool isDriver,
    Map<String, dynamic>? receiptData,
  }) async {
    await Printing.layoutPdf(
      name: isDriver ? 'CampusLift Trip Summary' : 'CampusLift Ride Receipt',
      onLayout: (_) async => generateRideSummaryPdf(
        ride: ride,
        isDriver: isDriver,
        receiptData: receiptData,
      ),
    );
  }
}
