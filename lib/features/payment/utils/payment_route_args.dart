/// Builds the `/payment-status/:transactionId` location, carrying the item
/// context through query parameters.
///
/// The payment reference alone is not enough to issue a ticket: events live in
/// Firestore with string ids while the API's `booking_id` column is an integer,
/// so the status screen needs the real `bookingType`/`itemId` (plus the title
/// and quantity) to attach the ticket to the signed-in user's own bookings.
String paymentStatusLocation({
  required String transactionId,
  required String bookingType,
  required String itemId,
  String? itemTitle,
  int quantity = 1,
}) {
  return Uri(
    path: '/payment-status/$transactionId',
    queryParameters: {
      'bookingType': bookingType,
      'itemId': itemId,
      if (itemTitle != null && itemTitle.trim().isNotEmpty)
        'itemTitle': itemTitle.trim(),
      'quantity': '${quantity < 1 ? 1 : quantity}',
    },
  ).toString();
}
