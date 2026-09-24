import 'package:flutter_test/flutter_test.dart';
import 'package:rll/models/invoice_list_model.dart';
import 'package:rll/widgets/pdf_generate_widget.dart';

InvoiceData _sample() => InvoiceData.fromJson({
  'id': 141,
  'invoice_number': 'RLL/2026/00141',
  'reference_number': null,
  'invoice_date': '2026-09-22',
  'invoice_due_date': '2026-10-06',
  'notes': 'Thank you for travelling with Rainbow Line.',
  'customer': {'id': 7, 'name': 'Greenfield Primary School', 'city': 'London', 'postal_code': 'E17 4PQ'},
  'invoice_items': [
    {
      'item_date': '2026-09-21',
      'description': 'School trip – Chessington',
      'quantity': 2,
      'price': '280.00',
      'amount': '560.00',
      'minibus_suv_sedan': 'Minibus',
    },
    {
      'item_date': '2026-09-21',
      'description': 'Extra waiting time',
      'quantity': '2',
      'price': '40',
      'amount': '80',
      'minibus_suv_sedan': 'Minibus',
    },
  ],
});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('parses API invoice and works out the total', () {
    final invoice = _sample();
    expect(invoice.customerName, 'Greenfield Primary School');
    expect(invoice.items.length, 2);
    expect(invoice.items[1].quantity, 2);
    expect(invoice.total, 640);
    expect(invoice.shortNumber, '00141');
    expect(invoice.customer!.fullAddress, 'London, E17 4PQ');
  });

  test('builds the invoice PDF', () async {
    final bytes = await PdfInvoiceApi.generate(_sample());
    expect(bytes.length, greaterThan(1000));
    expect(FileHandleApi.fileName(_sample()), 'RLL202600141.pdf');
  });
}
