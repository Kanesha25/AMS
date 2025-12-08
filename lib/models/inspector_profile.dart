class InspectorProfile {
  final String fullName;
  final String phoneNumber;
  final String insuranceCompany;
  final String registrationNumber;

  InspectorProfile({
    required this.fullName,
    required this.phoneNumber,
    required this.insuranceCompany,
    required this.registrationNumber,
  });

  factory InspectorProfile.fromMap(
    Map<String, dynamic> data, {
    String fallbackName = '',
    String fallbackPhone = '',
  }) {
    final firstName = data['firstName'] ?? data['name'] ?? '';
    final lastName = data['lastName'] ?? '';
    final fullName = (firstName.toString().trim().isEmpty &&
            lastName.toString().trim().isEmpty)
        ? fallbackName
        : '$firstName $lastName'.trim();

    return InspectorProfile(
      fullName: fullName.isEmpty ? 'Inspector' : fullName,
      phoneNumber: (data['phoneNumber'] ?? fallbackPhone ?? '') as String? ?? '',
      insuranceCompany: (data['insuranceCompany'] ?? '') as String? ?? '',
      registrationNumber: (data['regNumber'] ?? '') as String? ?? '',
    );
  }
}

