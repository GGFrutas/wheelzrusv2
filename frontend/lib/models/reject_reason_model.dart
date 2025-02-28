class RejectionReason {
  final int id;
  final String name;

  const RejectionReason({
    required this.id,
    required this.name,
  });
  
  factory RejectionReason.fromJson(Map<String, dynamic> json) {
    return RejectionReason(
      id: json['id'],
      name: json['name'] ?? 'No Name Provided'
    );
  }
  RejectionReason copyWith({String? name}) {
    return RejectionReason(
      id: id,
      name: name ?? this.name,
      
    );
  }
}