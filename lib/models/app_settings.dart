enum InferenceMode { localOnly, cloudOnly, hybrid }
enum CloudProvider { openai, anthropic, custom }
enum LocalModel { yolov8Tiny, mobileNetV3 }

class AppSettings {
  final InferenceMode inferenceMode;
  final double minConfidence;
  final double verificationTrigger;
  final int targetFps;
  final LocalModel localModel;
  final CloudProvider cloudProvider;
  final String openaiApiKey;
  final String anthropicApiKey;
  final String customEndpointUrl;
  final List<String> detailedAnalysisWhitelist;
  final bool saveToStorage;

  const AppSettings({
    this.inferenceMode = InferenceMode.hybrid,
    this.minConfidence = 0.5,
    this.verificationTrigger = 0.7,
    this.targetFps = 30,
    this.localModel = LocalModel.yolov8Tiny,
    this.cloudProvider = CloudProvider.openai,
    this.openaiApiKey = '',
    this.anthropicApiKey = '',
    this.customEndpointUrl = '',
    this.detailedAnalysisWhitelist = const ['cell phone', 'laptop', 'car', 'person'],
    this.saveToStorage = false,
  });

  AppSettings copyWith({
    InferenceMode? inferenceMode,
    double? minConfidence,
    double? verificationTrigger,
    int? targetFps,
    LocalModel? localModel,
    CloudProvider? cloudProvider,
    String? openaiApiKey,
    String? anthropicApiKey,
    String? customEndpointUrl,
    List<String>? detailedAnalysisWhitelist,
    bool? saveToStorage,
  }) {
    return AppSettings(
      inferenceMode: inferenceMode ?? this.inferenceMode,
      minConfidence: minConfidence ?? this.minConfidence,
      verificationTrigger: verificationTrigger ?? this.verificationTrigger,
      targetFps: targetFps ?? this.targetFps,
      localModel: localModel ?? this.localModel,
      cloudProvider: cloudProvider ?? this.cloudProvider,
      openaiApiKey: openaiApiKey ?? this.openaiApiKey,
      anthropicApiKey: anthropicApiKey ?? this.anthropicApiKey,
      customEndpointUrl: customEndpointUrl ?? this.customEndpointUrl,
      detailedAnalysisWhitelist: detailedAnalysisWhitelist ?? this.detailedAnalysisWhitelist,
      saveToStorage: saveToStorage ?? this.saveToStorage,
    );
  }

  Map<String, dynamic> toJson() => {
    'inferenceMode': inferenceMode.index,
    'minConfidence': minConfidence,
    'verificationTrigger': verificationTrigger,
    'targetFps': targetFps,
    'localModel': localModel.index,
    'cloudProvider': cloudProvider.index,
    'openaiApiKey': openaiApiKey,
    'anthropicApiKey': anthropicApiKey,
    'customEndpointUrl': customEndpointUrl,
    'detailedAnalysisWhitelist': detailedAnalysisWhitelist,
    'saveToStorage': saveToStorage,
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
    inferenceMode: InferenceMode.values[json['inferenceMode'] as int? ?? 2],
    minConfidence: (json['minConfidence'] as num?)?.toDouble() ?? 0.5,
    verificationTrigger: (json['verificationTrigger'] as num?)?.toDouble() ?? 0.7,
    targetFps: json['targetFps'] as int? ?? 30,
    localModel: LocalModel.values[json['localModel'] as int? ?? 0],
    cloudProvider: CloudProvider.values[json['cloudProvider'] as int? ?? 0],
    openaiApiKey: json['openaiApiKey'] as String? ?? '',
    anthropicApiKey: json['anthropicApiKey'] as String? ?? '',
    customEndpointUrl: json['customEndpointUrl'] as String? ?? '',
    detailedAnalysisWhitelist: (json['detailedAnalysisWhitelist'] as List<dynamic>?)
        ?.cast<String>() ?? const ['cell phone', 'laptop', 'car', 'person'],
    saveToStorage: json['saveToStorage'] as bool? ?? false,
  );
}
