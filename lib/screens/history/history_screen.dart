import 'package:flutter/material.dart';
import '../../services/firebase_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _firebaseService = FirebaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        title: const Text('Detection History'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.cyanAccent,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _firebaseService.getDetectionHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.cyanAccent),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off, color: Colors.orange, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Firebase not configured.\nSign in to view history.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                ],
              ),
            );
          }

          final detections = snapshot.data ?? [];
          if (detections.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history, color: Colors.grey[600], size: 64),
                  const SizedBox(height: 16),
                  Text(
                    'No detections yet.',
                    style: TextStyle(color: Colors.grey[500], fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: detections.length,
            itemBuilder: (context, index) {
              return _DetectionTile(data: detections[index]);
            },
          );
        },
      ),
    );
  }
}

class _DetectionTile extends StatelessWidget {
  final Map<String, dynamic> data;

  const _DetectionTile({required this.data});

  @override
  Widget build(BuildContext context) {
    final label = data['label'] as String? ?? 'Unknown';
    final confidence = (data['confidence'] as num?)?.toDouble() ?? 0;
    final timestamp = data['timestamp'] as String? ?? '';
    final cloudMeta = data['cloudMetadata'] as Map<String, dynamic>?;
    final verified = cloudMeta?['verified'] as bool? ?? false;
    final brand = cloudMeta?['brand'] as String?;
    final model = cloudMeta?['model'] as String?;

    return Card(
      color: const Color(0xFF1C2128),
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _confidenceColor(confidence).withOpacity(0.2),
          child: Icon(
            Icons.crop_free,
            color: _confidenceColor(confidence),
          ),
        ),
        title: Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (verified) ...[
              const SizedBox(width: 6),
              const Icon(Icons.verified, color: Colors.greenAccent, size: 16),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Confidence: ${(confidence * 100).toStringAsFixed(1)}%',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
            if (brand != null || model != null)
              Text(
                [if (brand != null) brand, if (model != null) model].join(' '),
                style: const TextStyle(color: Colors.cyanAccent, fontSize: 12),
              ),
            if (timestamp.isNotEmpty)
              Text(
                _formatTimestamp(timestamp),
                style: TextStyle(color: Colors.grey[600], fontSize: 11),
              ),
          ],
        ),
        trailing: Icon(Icons.chevron_right, color: Colors.grey[600]),
      ),
    );
  }

  Color _confidenceColor(double confidence) {
    if (confidence >= 0.7) return Colors.greenAccent;
    if (confidence >= 0.5) return Colors.yellow;
    return Colors.redAccent;
  }

  String _formatTimestamp(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}
