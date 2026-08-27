class AddressModel {
  final String id;
  final String label;
  final String line1;
  final String line2;
  final String city;
  final String state;
  final String pincode;
  final bool isDefault;

  const AddressModel({
    required this.id,
    required this.label,
    required this.line1,
    required this.line2,
    required this.city,
    this.state = '',
    required this.pincode,
    this.isDefault = false,
  });

  String get fullAddress {
    final parts = <String>[
      line1,
      if (line2.isNotEmpty) line2,
      city,
      if (state.isNotEmpty) state,
      pincode,
    ];
    return parts.join(', ');
  }

  AddressModel copyWith({
    String? id,
    String? label,
    String? line1,
    String? line2,
    String? city,
    String? state,
    String? pincode,
    bool? isDefault,
  }) {
    return AddressModel(
      id: id ?? this.id,
      label: label ?? this.label,
      line1: line1 ?? this.line1,
      line2: line2 ?? this.line2,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
