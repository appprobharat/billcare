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


class ClientModel {
  final String id;
  final String clientName;
  final String contactNo;
  final String gstin;
  final String type;
  final String address;
  final String state;
  final String? clientPhotoUrl; 

  ClientModel({
    required this.id,
    required this.clientName,
    required this.contactNo,
    required this.gstin,
    required this.type,
    required this.state,
    this.clientPhotoUrl,
    required this.address,
  });

  factory ClientModel.fromJson(Map<String, dynamic> json) {
  
    String? imageUrl = json['Photo']?.toString() ?? json['Photo']?.toString();
    if (imageUrl == 'null') {
      imageUrl = null;
    }

    return ClientModel(
      id: json['id']?.toString() ?? '',
      clientName: json['Name']?.toString() ?? '',
      contactNo: json['ContactNo']?.toString() ?? '',
      gstin: json['GSTIN']?.toString() ?? '',
      type: json['Type']?.toString() ?? 'Party', 
      state: json['State']?.toString() ?? '',
      address: json['Address']?.toString() ?? '',
      clientPhotoUrl: imageUrl,
    );
  }
}