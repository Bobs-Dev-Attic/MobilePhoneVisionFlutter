import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../core/inference_manager.dart';
import '../../providers/detection_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/cloud_detection_service.dart';
import '../../services/firebase_service.dart';
import '../../services/local_detection_service.dart';
import '../../services/network_monitor.dart';
import '../history/history_screen.dart';
import '../settings/settings_screen.dart';
import 'bounding_box_painter.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _cameraInitialized = false;
  InferenceManager? _inferenceManager;
  // ignore: unused_field
  final _firebaseService = FirebaseService();

  int _frameCount = 0;
  double _fps = 0;
  DateTime _lastFpsUpdate = DateTime.now();
  bool _fallbackShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _inferenceManager?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera(_cameras.isNotEmpty ? _cameras.first : null);
    }
  }

  Future<void> _initialize() async {
    final settings = context.read<SettingsProvider>().settings;
    _inferenceManager = InferenceManager(
      settings: settings,
      localService: LocalDetectionService(model: settings.localModel),
      cloudService: CloudDetectionService(settings: settings),
      networkMonitor: NetworkMonitor(),
    );
    _inferenceManager!.addListener(_onInferenceUpdate);

    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        await _initCamera(_cameras.first);
      }
    } catch (e) {
      debugPrint('[CameraScreen] Camera init error: $e');
    }
  }

  Future<void> _initCamera(CameraDescription? camera) async {
    if (camera == null) return;
    _cameraController = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await _cameraController!.initialize();
      if (mounted) setState(() => _cameraInitialized = true);
      _cameraController!.startImageStream(_onCameraFrame);
    } catch (e) {
      debugPrint('[CameraScreen] Camera controller error: $e');
    }
  }

  void _onCameraFrame(CameraImage image) {
    _frameCount++;
    final now = DateTime.now();
    final elapsed = now.difference(_lastFpsUpdate).inMilliseconds;
    if (elapsed >= 1000) {
      setState(() {
        _fps = _frameCount * 1000.0 / elapsed;
        _frameCount = 0;
        _lastFpsUpdate = now;
      });
    }

    final bytes = _convertCameraImage(image);
    _inferenceManager?.processFrame(
      bytes,
      width: image.width,
      height: image.height,
    );
  }

  Uint8List _convertCameraImage(CameraImage image) {
    if (image.format.group == ImageFormatGroup.jpeg) {
      return image.planes[0].bytes;
    }
    // For YUV420 or other formats, return the first plane as fallback
    return image.planes[0].bytes;
  }

  void _onInferenceUpdate() {
    if (_inferenceManager == null) return;
    context.read<DetectionProvider>().updateFromManager(_inferenceManager!);

    if (_inferenceManager!.isCloudFallback && !_fallbackShown) {
      _fallbackShown = true;
      Fluttertoast.showToast(
        msg: '⚠ Cloud unavailable – local mode only',
        backgroundColor: Colors.orange,
        textColor: Colors.white,
        gravity: ToastGravity.TOP,
      );
    }
    if (!_inferenceManager!.isCloudFallback) {
      _fallbackShown = false;
    }
  }

  void _navigateToSettings() async {
    final settingsProvider = context.read<SettingsProvider>();
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
    _inferenceManager?.updateSettings(settingsProvider.settings);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_cameraInitialized && _cameraController != null)
            _buildCameraPreview()
          else
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.cyanAccent),
                  SizedBox(height: 16),
                  Text('Initializing camera…', style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          _buildStatusBar(),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    return Consumer<DetectionProvider>(
      builder: (context, detectionProvider, _) {
        return Stack(
          fit: StackFit.expand,
          children: [
            CameraPreview(_cameraController!),
            if (detectionProvider.detections.isNotEmpty)
              CustomPaint(
                painter: BoundingBoxPainter(
                  detections: detectionProvider.detections,
                  imageSize: Size(
                    _cameraController!.value.previewSize?.height ?? 640,
                    _cameraController!.value.previewSize?.width ?? 480,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildStatusBar() {
    return Consumer<DetectionProvider>(
      builder: (context, detectionProvider, _) {
        final modeLabel = _inferenceManager?.settings.inferenceMode.name ?? '—';
        final fallback = detectionProvider.isCloudFallback;
        final state = detectionProvider.inferenceState;

        return Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            color: Colors.black54,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  _StatusChip(label: 'Mode', value: modeLabel, color: Colors.cyanAccent),
                  const SizedBox(width: 8),
                  _StatusChip(label: 'FPS', value: _fps.toStringAsFixed(1), color: Colors.greenAccent),
                  const SizedBox(width: 8),
                  if (fallback)
                    const _StatusChip(label: '⚠', value: 'Local Only', color: Colors.orange)
                  else
                    _StatusChip(
                      label: '●',
                      value: state.name,
                      color: state == InferenceState.cloudInference
                          ? Colors.purpleAccent
                          : Colors.cyanAccent,
                    ),
                  const Spacer(),
                  _StatusChip(
                    label: 'Dropped',
                    value: '${_inferenceManager?.droppedFrames ?? 0}',
                    color: Colors.redAccent,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButtons() {
    return Positioned(
      bottom: 32,
      left: 0,
      right: 0,
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _ActionButton(
              icon: Icons.settings,
              label: 'Settings',
              onTap: _navigateToSettings,
            ),
            _ActionButton(
              icon: Icons.history,
              label: 'History',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HistoryScreen()),
              ),
            ),
            _ActionButton(
              icon: Icons.refresh,
              label: 'Reset',
              onTap: () {
                _inferenceManager?.reset();
                context.read<DetectionProvider>().clear();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatusChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        border: Border.all(color: color.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.cyanAccent.withOpacity(0.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.cyanAccent, size: 24),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.cyanAccent, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
