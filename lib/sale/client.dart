
class Client {
  final int id;
  final String type;
  final String name;
  final int contactNo;
  final String state;

  Client({
    required this.id,
    required this.type,
    required this.name,
    required this.contactNo,
    required this.state,
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'] as int,
      type: json['Type'] as String? ?? 'N/A',
      name: json['Name'] as String? ?? 'N/A',
      contactNo: json['ContactNo'] is String
          ? int.tryParse(json['ContactNo']) ?? 0
          : json['ContactNo'] as int? ?? 0,
      state: json['State'] as String? ?? 'N/A',
    );
  }
}