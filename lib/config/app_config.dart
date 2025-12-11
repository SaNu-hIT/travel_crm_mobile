class AppConfig {
  // API Configuration
  static const String apiBaseUrl = 'https://travellmsproduction.vercel.app'; // Local backend with CORS enabled (dev mode)
  // For production: 'https://travellmsproduction.vercel.app'
  static const int apiTimeout = 30; // seconds
  
  // App Information
  static const String appName = 'Travel LMS';
  static const String appVersion = '1.0.0';
  
  // Environment
  static const bool isDevelopment = true;
  
  // API Endpoints
  static const String loginEndpoint = '/api/auth/login';
  static const String meEndpoint = '/api/auth/me';
  static const String leadsEndpoint = '/api/leads';
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 50;
}
