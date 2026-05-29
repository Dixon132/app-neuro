class UserModel {
  final int id;
  final String email;
  final String username;
  final String fullName;
  final String role;

  UserModel({
    required this.id,
    required this.email,
    required this.username,
    required this.fullName,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
      username: json['username'],
      fullName: json['full_name'],
      role: json['role'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'full_name': fullName,
      'role': role,
    };
  }
}

class AnalysisModel {
  final int id;
  final String fileName;
  final String status;
  final double? riskScore;
  final String? prediction;
  final double? confidence;
  final String? mostAnomalousChannel;
  final int? nWindowsAnalyzed;
  final int? samplingRate;
  final DateTime createdAt;

  AnalysisModel({
    required this.id,
    required this.fileName,
    required this.status,
    this.riskScore,
    this.prediction,
    this.confidence,
    this.mostAnomalousChannel,
    this.nWindowsAnalyzed,
    this.samplingRate,
    required this.createdAt,
  });

  factory AnalysisModel.fromJson(Map<String, dynamic> json) {
    return AnalysisModel(
      id: json['id'],
      fileName: json['file_name'],
      status: json['status'],
      riskScore: json['risk_score']?.toDouble(),
      prediction: json['prediction'],
      confidence: json['confidence']?.toDouble(),
      mostAnomalousChannel: json['most_anomalous_channel'],
      nWindowsAnalyzed: json['n_windows_analyzed'],
      samplingRate: json['sampling_rate'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
