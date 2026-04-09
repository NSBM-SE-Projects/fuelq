class Validators {
  Validators._();

  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your name';
    }
    if (value.trim().length < 3) {
      return 'Name must be at least 3 characters';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email';
    }
    final regex = RegExp(r'^[\w\.\-]+@[\w\.\-]+\.\w{2,}$');
    if (!regex.hasMatch(value.trim())) {
      return 'Please enter a valid email';
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your phone number';
    }
    final cleaned = value.replaceAll(RegExp(r'[\s\-]'), '');
    final regex = RegExp(r'^(\+94|0)7\d{8}$');
    if (!regex.hasMatch(cleaned)) {
      return 'Enter a valid Sri Lankan phone number';
    }
    return null;
  }

  static String? nic(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your NIC number';
    }
    final trimmed = value.trim();
    final oldNic = RegExp(r'^\d{9}[VvXx]$');
    final newNic = RegExp(r'^\d{12}$');
    if (!oldNic.hasMatch(trimmed) && !newNic.hasMatch(trimmed)) {
      return 'Enter a valid NIC (9 digits + V/X or 12 digits)';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  static String? Function(String?) confirmPassword(String password) {
    return (String? value) {
      if (value == null || value.isEmpty) {
        return 'Please confirm your password';
      }
      if (value != password) {
        return 'Passwords do not match';
      }
      return null;
    };
  }

  static String? vehicleNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter vehicle number';
    }
    final regex = RegExp(r'^[A-Z]{2,3}[\-\s]?\d{4}$');
    if (!regex.hasMatch(value.trim().toUpperCase())) {
      return 'Enter a valid plate number (e.g. CAB-1234)';
    }
    return null;
  }

  static String? chassisNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter chassis number';
    }
    if (value.trim().length < 5) {
      return 'Chassis number must be at least 5 characters';
    }
    return null;
  }
}
