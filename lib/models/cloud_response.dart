class CloudResponse {
  final bool verified;
  final String? brand;
  final String? model;
  final String? condition;
  final String? description;
  final double? confidence;

  const CloudResponse({
    required this.verified,
    this.brand,
    this.model,
    this.condition,
    this.description,
    this.confidence,
  });

  factory CloudResponse.fromJson(Map<String, dynamic> json) {
    return CloudResponse(
      verified: json['verified'] as bool? ?? false,
      brand: json['brand'] as String?,
      model: json['model'] as String?,
      condition: json['condition'] as String?,
      description: json['description'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
    'verified': verified,
    if (brand != null) 'brand': brand,
    if (model != null) 'model': model,
    if (condition != null) 'condition': condition,
    if (description != null) 'description': description,
    if (confidence != null) 'confidence': confidence,
  };
}
