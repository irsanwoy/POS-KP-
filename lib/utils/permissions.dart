// 1. Buat file baru: lib/utils/permissions.dart
class UserPermissions {
  static const String KASIR = 'kasir';
  static const String PEMILIK = 'pemilik';

  // Define permissions untuk setiap role
  static Map<String, List<String>> rolePermissions = {
    KASIR: [
      'view_dashboard_basic',
      'create_transaction',
      'view_transaction_own', 
      'manage_products',
      'manage_stock',
      'manage_debt',
      'view_suppliers_basic',
    ],
    PEMILIK: [
      'view_dashboard_full',
      'view_transaction_all',
      'view_products_readonly',
      'view_debt_readonly',
      'manage_suppliers',
      'view_analytics',
      'view_reports',
      'emergency_override', // Untuk kondisi darurat
    ],
  };

  // Check apakah user punya permission tertentu
  static bool hasPermission(String userRole, String permission) {
    return rolePermissions[userRole]?.contains(permission) ?? false;
  }

  // Check apakah bisa akses screen tertentu
  static bool canAccessScreen(String userRole, String screenName) {
    switch (screenName) {
      case 'dashboard':
        return hasPermission(userRole, 'view_dashboard_basic') || 
               hasPermission(userRole, 'view_dashboard_full');
      case 'transaction':
        return hasPermission(userRole, 'create_transaction') || 
               hasPermission(userRole, 'view_transaction_all');
      case 'products':
        return hasPermission(userRole, 'manage_products') || 
               hasPermission(userRole, 'view_products_readonly');
      case 'debt':
        return hasPermission(userRole, 'manage_debt') || 
               hasPermission(userRole, 'view_debt_readonly');
      case 'suppliers':
        return hasPermission(userRole, 'manage_suppliers') || 
               hasPermission(userRole, 'view_suppliers_basic');
      case 'analytics':
        return hasPermission(userRole, 'view_analytics');
      default:
        return false;
    }
  }

  // Check apakah action bisa dilakukan
  static bool canPerformAction(String userRole, String action) {
    switch (action) {
      case 'create_product':
      case 'edit_product':
      case 'delete_product':
        return hasPermission(userRole, 'manage_products');
      case 'create_transaction':
        return hasPermission(userRole, 'create_transaction') || 
               hasPermission(userRole, 'emergency_override');
      case 'view_financial_data':
        return hasPermission(userRole, 'view_dashboard_full');
      default:
        return true; // Default allow untuk action yang tidak restricted
    }
  }
}

