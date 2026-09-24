/// Every message the user can see, kept in one place so wording stays
/// consistent and is easy to change or translate later.
class AppMessages {
  AppMessages._();

  // Network
  static const String noInternet = "You're offline. Check your internet connection and try again.";
  static const String timeout = "The server is taking too long to respond. Please try again.";
  static const String serverError = "Something went wrong on our side. Please try again in a moment.";
  static const String unknownError = "Something went wrong. Please try again.";
  static const String badResponse = "We received an unexpected response from the server.";

  // Loading
  static const String loadingInvoices = "Loading invoices…";
  static const String creatingInvoice = "Creating your invoice…";
  static const String updatingInvoice = "Saving your changes…";
  static const String loadingInvoice = "Opening invoice…";
  static const String preparingPdf = "Preparing PDF…";
  static const String savingSetting = "Saving…";

  // Success
  static const String invoiceCreated = "Invoice created";
  static const String invoiceUpdated = "Invoice updated successfully";
  static const String invoiceNoUpdated = "Invoice number updated";
  static const String pdfSaved = "PDF saved to your device";
  static const String copied = "Invoice number copied";
  static const String themeChanged = "Appearance updated";

  // Validation — customer
  static const String enterCustomerName = "Add the customer name to continue.";
  // Validation — details
  static const String selectInvoiceDate = "Pick the invoice date.";
  static const String selectDueDate = "Pick the due date.";
  static const String dueBeforeInvoice = "The due date can't be before the invoice date.";
  static const String invoiceNoMissing = "Invoice number isn't ready yet. Pull down on Home to refresh.";
  // Validation — trips
  static const String addOneTrip = "Add at least one trip to continue.";
  static const String selectTripDate = "Pick the trip date.";
  static const String enterDescription = "Describe the trip, e.g. Airport transfer – Heathrow.";
  static const String selectVehicle = "Choose the vehicle type.";
  static const String enterQuantity = "Quantity must be at least 1.";
  static const String enterPrice = "Enter a price greater than £0.";
  static const String enterValidPrice = "Enter a valid price, e.g. 120 or 120.50.";
  // Validation — settings
  static const String enterInvoiceNo = "Enter the next invoice number.";
  static const String invoiceNoSame = "That's already the current invoice number.";

  // Confirmations
  static const String discardTitle = "Discard this invoice?";
  static const String discardBody = "The details you've entered will be lost.";
  static const String discardEditTitle = "Discard your changes?";
  static const String discardEditBody = "Your edits to this invoice haven't been saved.";
  static const String removeTripTitle = "Remove this trip?";
  static const String removeTripBody = "It will be taken off the invoice.";
  static const String tripRemoved = "Trip removed";
  static const String tripAdded = "Trip added";
  static const String tripUpdated = "Trip updated";

  // Empty states
  static const String noInvoicesTitle = "No invoices yet";
  static const String noInvoicesBody = "Tap + to create your first invoice. It'll show up here.";
  static const String noResultsTitle = "No invoices found";
  static const String noResultsBody = "Try a different customer name or invoice number.";
  static const String loadErrorTitle = "Couldn't load invoices";

  // Misc
  static const String invoiceNoAutoIncreaseWarning =
      "Invoice saved, but the next invoice number couldn't be updated. Check it in Settings.";
  static const String cannotOpenPdf = "Couldn't open the PDF. The file was saved to your device.";
}
