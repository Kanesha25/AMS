import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../models/accident_model.dart';
import '../../models/customer_model.dart';
import '../../models/inspector_profile.dart';
import '../../models/spare_part_model.dart';
import '../home/home_screen.dart';

class EstimationReportScreen extends StatelessWidget {
  final AccidentModel accident;
  final CustomerModel customer;
  final InspectorProfile? inspectorProfile;
  final List<SparePart> estimationParts;

  EstimationReportScreen({
    super.key,
    required this.accident,
    required this.customer,
    required this.estimationParts,
    this.inspectorProfile,
  });

  int get _totalAvgCost => estimationParts.fold(
      0, (sum, part) => sum + ((part.minPrice + part.maxPrice) ~/ 2));

  int _getAveragePrice(SparePart part) =>
      (part.minPrice + part.maxPrice) ~/ 2;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Estimation Report',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('lib/screens/assets/images/bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          color: Colors.white.withOpacity(0.9),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: _buildReportCard(context),
                  ),
                ),
                SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton.icon(
                    onPressed: () => _generatePdf(context),
                    icon: Icon(Icons.download, color: Colors.white),
                    label: Text(
                      'Download report as PDF',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF029CDB),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Pop all routes until we reach the home screen
                      // Navigator.of(context).popUntil((route) => route.isFirst);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => HomeScreen()),
                      );
                    },
                    icon: Icon(Icons.home, color: Colors.white),
                    label: Text(
                      'Return To Home',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF18D161),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReportCard(BuildContext context) {
    final inspectorName =
        inspectorProfile?.fullName.isNotEmpty == true ? inspectorProfile!.fullName : 'Inspector';
    final inspectorPhone =
        inspectorProfile?.phoneNumber.isNotEmpty == true ? inspectorProfile!.phoneNumber : '-';
    final insuranceCompany =
        inspectorProfile?.insuranceCompany.isNotEmpty == true ? inspectorProfile!.insuranceCompany : '-';
    final regNumber =
        inspectorProfile?.registrationNumber.isNotEmpty == true ? inspectorProfile!.registrationNumber : '-';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Text(
                    'Accident Management System',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Estimation Report',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            _buildInfoRow('Vehicle Number', accident.vehicleNumber,
                rightLabel: 'Ins. Company', rightValue: insuranceCompany),
            _buildInfoRow('Model', accident.vehicleModel,
                rightLabel: 'Inspector', rightValue: inspectorName),
            _buildInfoRow('Customer', customer.fullName,
                rightLabel: 'Reg. Number', rightValue: regNumber),
            _buildInfoRow('Phone Number', customer.phoneNumber,
                rightLabel: 'Phone Number', rightValue: inspectorPhone),
            _buildInfoRow(
              'Date & Time',
              _formatDateTime(accident.timestamp),
            ),
            SizedBox(height: 20),
            Table(
              border: TableBorder.all(color: Colors.black, width: 1),
              columnWidths: const {
                0: FixedColumnWidth(40),
                1: FlexColumnWidth(2.5),
                2: FixedColumnWidth(60),
                3: FlexColumnWidth(1.2),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey[200]),
                  children: const [
                    _TableCell('No'),
                    _TableCell('Spare Parts'),
                    _TableCell('Qty'),
                    _TableCell('Cost'),
                  ],
                ),
                ...List.generate(estimationParts.length, (index) {
                  final part = estimationParts[index];
                  return TableRow(
                    children: [
                      _TableCell('${index + 1}'),
                      _TableCell(part.name),
                      const _TableCell('1'),
                      _TableCell(
                        'LKR ${_formatCurrency(_getAveragePrice(part))}',
                      ),
                    ],
                  );
                }),
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey[100]),
                  children: [
                    const _TableCell(''),
                    const _TableCell('Total'),
                    const _TableCell(''),
                    _TableCell(
                      'LKR ${_formatCurrency(_totalAvgCost)}',
                      isBold: true,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value,
      {String? rightLabel, String? rightValue}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Expanded(
            child: _InfoTile(label: label, value: value),
          ),
          if (rightLabel != null)
            Expanded(
              child: _InfoTile(
                label: rightLabel,
                value: rightValue ?? '-',
                alignRight: true,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _generatePdf(BuildContext context) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'Accident Management System',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Estimation Report',
                        style: pw.TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),
                _buildPdfInfoRow('Vehicle Number', accident.vehicleNumber,
                    'Ins. Company', inspectorProfile?.insuranceCompany ?? '-'),
                _buildPdfInfoRow('Model', accident.vehicleModel, 'Inspector',
                    inspectorProfile?.fullName ?? 'Inspector'),
                _buildPdfInfoRow('Customer', customer.fullName, 'Reg. Number',
                    inspectorProfile?.registrationNumber ?? '-'),
                _buildPdfInfoRow('Phone Number', customer.phoneNumber,
                    'Phone Number', inspectorProfile?.phoneNumber ?? '-'),
                _buildPdfInfoRow(
                  'Date & Time',
                  _formatDateTime(accident.timestamp),
                  null,
                  null,
                ),
                pw.SizedBox(height: 20),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.black),
                  columnWidths: const {
                    0: pw.FixedColumnWidth(40),
                    1: pw.FlexColumnWidth(2.5),
                    2: pw.FixedColumnWidth(60),
                    3: pw.FlexColumnWidth(1.2),
                  },
                  children: [
                    pw.TableRow(
                      decoration:
                          pw.BoxDecoration(color: PdfColors.grey300),
                      children: [
                        _pdfCell('No', isBold: true),
                        _pdfCell('Spare Parts', isBold: true),
                        _pdfCell('Qty', isBold: true),
                        _pdfCell('Cost', isBold: true),
                      ],
                    ),
                    ...List.generate(estimationParts.length, (index) {
                      final part = estimationParts[index];
                      return pw.TableRow(
                        children: [
                          _pdfCell('${index + 1}'),
                          _pdfCell(part.name),
                          _pdfCell('1'),
                          _pdfCell(
                            'LKR ${_formatCurrency((part.minPrice + part.maxPrice) ~/ 2)}',
                          ),
                        ],
                      );
                    }),
                    pw.TableRow(
                      decoration:
                          pw.BoxDecoration(color: PdfColors.grey200),
                      children: [
                        _pdfCell(''),
                        _pdfCell('Total', isBold: true),
                        _pdfCell(''),
                        _pdfCell(
                          'LKR ${_formatCurrency(_totalAvgCost)}',
                          isBold: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  static pw.Widget _pdfCell(String text, {bool isBold = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 11,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static pw.Widget _buildPdfInfoRow(
    String leftLabel,
    String leftValue,
    String? rightLabel,
    String? rightValue,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(
            child: pw.Text(
              '$leftLabel: $leftValue',
              style: const pw.TextStyle(fontSize: 12),
            ),
          ),
          if (rightLabel != null && rightValue != null)
            pw.Expanded(
              child: pw.Text(
                '$rightLabel: $rightValue',
                textAlign: pw.TextAlign.right,
                style: const pw.TextStyle(fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  static String _formatDateTime(DateTime dateTime) {
    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final period = dateTime.hour >= 12 ? 'pm' : 'am';
    return '${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year} '
        '${hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} $period';
  }

  static String _formatCurrency(num value) {
    final str = value.toStringAsFixed(0);
    final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return str.replaceAllMapped(reg, (match) => '${match[1]},');
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final bool alignRight;

  const _InfoTile({
    required this.label,
    required this.value,
    this.alignRight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: 2),
        Text(
          value.isEmpty ? '-' : value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _TableCell extends StatelessWidget {
  final String text;
  final bool isBold;

  const _TableCell(this.text, {this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
        ),
      ),
    );
  }
}

