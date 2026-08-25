class AppConfig {
  /// The customer store API base. This app is **white-label per tenant** — set
  /// this to the store's own domain before building the tenant's APK, e.g.
  /// `https://theirshop.com/api/v1/store`. All branding/products come from it.
  ///
  /// Dev tips:
  ///   Android emulator → http://10.0.2.2:8131/api/v1/store  (+ send X-Store-Id)
  ///   Real device      → https://theirshop.com/api/v1/store
  static const String apiBaseUrl = 'https://erp.sahin.cloud/api/v1/store';

  /// Optional: when the base URL host can't resolve the store (e.g. shared dev
  /// host), send this company id via the X-Store-Id header. Leave blank in prod.
  static const String storeId = '';

  static const String appName = 'Online Store';
}
