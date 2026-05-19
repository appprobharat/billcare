class StateModel {
  final String id;
  final String name;

  StateModel({required this.id, required this.name});

  factory StateModel.fromJson(Map<String, dynamic> json) {
    return StateModel(
      id: json['id']?.toString() ?? '',

      name: json['State']?.toString() ?? '',
    );
  }
}

class BankModel {
  final String id;
  final String name;
  BankModel({required this.id, required this.name});

  factory BankModel.fromJson(Map<String, dynamic> json) {
    return BankModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }
}

class EmployeeModel {
  final String id;
  final String name;
  final String contactNo;
  final String address;
  final String state;
  final String relative;
  final String? photo;

  EmployeeModel({
    required this.id,
    required this.name,
    required this.contactNo,
    required this.address,
    required this.state,
    required this.relative,
    this.photo,
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    return EmployeeModel(
      id: json['id'].toString(),
      name: json['Name'] ?? "",
      contactNo: json['ContactNo'].toString(),
      address: json['Address'] ?? "",
      state: json['State'] ?? "",
      photo: json['Photo'],
      relative: json['Relative'] ?? "",
    );
  }
}
