import '../utility/global_function.dart';

/// Response of GET /invoice
class InvoiceListModel {
  String? status;
  String? message;
  List<InvoiceData>? data;

  InvoiceListModel({this.status, this.message, this.data});

  InvoiceListModel.fromJson(Map<String, dynamic> json) {
    status = json['status']?.toString();
    message = json['message']?.toString();
    if (json['data'] is List) {
      data = (json['data'] as List).whereType<Map<String, dynamic>>().map(InvoiceData.fromJson).toList();
    }
  }
}

class InvoiceData {
  int? id;
  int? customerId;
  String? invoiceNumber;
  String? referenceNumber;
  String? invoiceDate;
  String? invoiceDueDate;
  String? notes;
  String? createdAt;
  String? updatedAt;
  Customer? customer;
  List<InvoiceItems>? invoiceItems;

  InvoiceData({
    this.id,
    this.customerId,
    this.invoiceNumber,
    this.referenceNumber,
    this.invoiceDate,
    this.invoiceDueDate,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.customer,
    this.invoiceItems,
  });

  InvoiceData.fromJson(Map<String, dynamic> json) {
    id = _toInt(json['id']);
    customerId = _toInt(json['customer_id']);
    invoiceNumber = json['invoice_number']?.toString();
    referenceNumber = json['reference_number']?.toString();
    invoiceDate = json['invoice_date']?.toString();
    invoiceDueDate = json['invoice_due_date']?.toString();
    notes = json['notes']?.toString();
    createdAt = json['created_at']?.toString();
    updatedAt = json['updated_at']?.toString();
    customer = json['customer'] is Map<String, dynamic> ? Customer.fromJson(json['customer']) : null;
    if (json['invoice_items'] is List) {
      invoiceItems = (json['invoice_items'] as List)
          .whereType<Map<String, dynamic>>()
          .map(InvoiceItems.fromJson)
          .toList();
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'customer_id': customerId,
    'invoice_number': invoiceNumber,
    'reference_number': referenceNumber,
    'invoice_date': invoiceDate,
    'invoice_due_date': invoiceDueDate,
    'notes': notes,
    'created_at': createdAt,
    'updated_at': updatedAt,
    if (customer != null) 'customer': customer!.toJson(),
    if (invoiceItems != null) 'invoice_items': invoiceItems!.map((v) => v.toJson()).toList(),
  };

  // ---- Helpers used by the UI --------------------------------------------

  String get customerName => cleanText(customer?.name);
  DateTime? get date => parseApiDate(invoiceDate);
  DateTime? get dueDate => parseApiDate(invoiceDueDate);
  List<InvoiceItems> get items => invoiceItems ?? const [];
  double get total => items.fold(0.0, (sum, i) => sum + i.amountValue);

  /// Invoice number without the prefix/year, e.g. RLL/2026/00142 -> 00142
  String get shortNumber => (invoiceNumber ?? '').split('/').last;
}

class Customer {
  int? id;
  String? name;
  String? address;
  String? city;
  String? country;
  String? postalCode;
  String? createdAt;
  String? updatedAt;

  Customer({
    this.id,
    this.name,
    this.address,
    this.city,
    this.country,
    this.postalCode,
    this.createdAt,
    this.updatedAt,
  });

  Customer.fromJson(Map<String, dynamic> json) {
    id = _toInt(json['id']);
    name = json['name']?.toString();
    address = json['address']?.toString();
    city = json['city']?.toString();
    country = json['country']?.toString();
    postalCode = json['postal_code']?.toString();
    createdAt = json['created_at']?.toString();
    updatedAt = json['updated_at']?.toString();
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'address': address,
    'city': city,
    'country': country,
    'postal_code': postalCode,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };

  /// "14 Oak Lane, London, UK, E17 4PQ"
  String get fullAddress => [address, city, country, postalCode].map(cleanText).where((e) => e.isNotEmpty).join(', ');
}

class InvoiceItems {
  int? id;
  int? invoiceId;
  int? dateInRange;
  String? itemDate;
  String? description;
  int? quantity;
  String? price;
  String? amount;
  String? minibusSuvSedan;
  String? createdAt;
  String? updatedAt;

  InvoiceItems({
    this.id,
    this.invoiceId,
    this.dateInRange,
    this.itemDate,
    this.description,
    this.quantity,
    this.price,
    this.amount,
    this.minibusSuvSedan,
    this.createdAt,
    this.updatedAt,
  });

  InvoiceItems.fromJson(Map<String, dynamic> json) {
    id = _toInt(json['id']);
    invoiceId = _toInt(json['invoice_id']);
    dateInRange = _toInt(json['date_in_range']);
    itemDate = json['item_date']?.toString();
    description = json['description']?.toString();
    quantity = _toInt(json['quantity']);
    price = json['price']?.toString();
    amount = json['amount']?.toString();
    minibusSuvSedan = json['minibus_suv_sedan']?.toString();
    createdAt = json['created_at']?.toString();
    updatedAt = json['updated_at']?.toString();
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'invoice_id': invoiceId,
    'date_in_range': dateInRange,
    'item_date': itemDate,
    'description': description,
    'quantity': quantity,
    'price': price,
    'amount': amount,
    'minibus_suv_sedan': minibusSuvSedan,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };

  InvoiceItems copy() => InvoiceItems.fromJson(toJson());

  DateTime? get date => parseApiDate(itemDate);
  double get priceValue => parseAmount(price);
  double get amountValue => parseAmount(amount);
  String get vehicle => cleanText(minibusSuvSedan);
}

int? _toInt(dynamic v) => v is int ? v : int.tryParse(v?.toString() ?? '');
