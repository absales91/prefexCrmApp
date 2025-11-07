/// App-wide constants for API configuration and project settings

class AppConstants {
  /// 🌐 Base API URL for your Perfex CRM installation
  /// Example: https://crm.yourcompany.com or https://yourdomain.com/perfex
  static const String baseUrl = "https://crm.msmesoftwares.com";

  /// 🧭 Perfex API endpoint (append to baseUrl)
  static const String apiBase = "$baseUrl/perfex_mobile_app_api";

  /// 🔑 Perfex API Access Token
  /// Go to Perfex → Setup → API → Generate API Key
  // static const String apiToken = "YOUR_PERFEX_API_KEY";

  /// 🕒 Request timeout duration (optional)
  // static const Duration requestTimeout = Duration(seconds: 30);

  /// Common headers for all HTTP calls
  // static Map<String, String> get headers => {
  //   "Authorization": "Bearer $apiToken",
  //   "Content-Type": "application/json",
  // };
}
