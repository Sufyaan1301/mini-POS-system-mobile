/// SQLite table and column names centralized to avoid magic strings.
class DbConstants {
  DbConstants._();

  // Tables
  static const String tableCashiers = 'cashiers';
  static const String tableCategories = 'categories';
  static const String tableProducts = 'products';
  static const String tableAddons = 'addons';
  static const String tableTransactions = 'transactions';
  static const String tableTransactionItems = 'transaction_items';
  static const String tableTransactionItemAddons = 'transaction_item_addons';
  static const String tableHeldOrders = 'held_orders';

  // Common columns
  static const String colId = 'id';
  static const String colName = 'name';
  static const String colPrice = 'price';
  static const String colStock = 'stock';
  static const String colIsDeleted = 'is_deleted';
  static const String colCreatedAt = 'created_at';
  static const String colUpdatedAt = 'updated_at';

  // Cashiers
  static const String colUsername = 'username';
  static const String colPasswordHash = 'password_hash';

  // Products
  static const String colCategoryId = 'category_id';
  static const String colImagePath = 'image_path';

  // Transactions
  static const String colInvoiceNumber = 'invoice_number';
  static const String colCashierId = 'cashier_id';
  static const String colCashierNameSnapshot = 'cashier_name_snapshot';
  static const String colSubtotal = 'subtotal';
  static const String colDiscountType = 'discount_type';
  static const String colDiscountValue = 'discount_value';
  static const String colDiscountAmount = 'discount_amount';
  static const String colTotal = 'total';
  static const String colCashReceived = 'cash_received';
  static const String colChangeAmount = 'change_amount';

  // Transaction Items (with historical snapshot columns)
  static const String colTransactionId = 'transaction_id';
  static const String colProductId = 'product_id';
  static const String colProductNameSnapshot = 'product_name_snapshot';
  static const String colUnitPriceSnapshot = 'unit_price_snapshot';
  static const String colQuantity = 'quantity';
  static const String colItemSubtotal = 'item_subtotal';

  // Transaction Item Add-ons (with historical snapshot columns)
  static const String colTransactionItemId = 'transaction_item_id';
  static const String colAddonId = 'addon_id';
  static const String colAddonNameSnapshot = 'addon_name_snapshot';
  static const String colAddonPriceSnapshot = 'addon_price_snapshot';

  // Held Orders (Hold / Save Bill bonus)
  static const String colLabel = 'label';
  static const String colCartJson = 'cart_json';
}
