part of 'app_pages.dart';

abstract class Routes {
  Routes._();
  static const splash = _Paths.splash;
  static const main = _Paths.main;
  static const invoiceForm = _Paths.invoiceForm;
  static const invoicePreview = _Paths.invoicePreview;
}

abstract class _Paths {
  _Paths._();
  static const splash = '/Splash';
  static const main = '/Main';
  static const invoiceForm = '/InvoiceForm';
  static const invoicePreview = '/InvoicePreview';
}
