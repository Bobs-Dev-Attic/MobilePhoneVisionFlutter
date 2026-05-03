import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_settings.dart';
import '../../providers/settings_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late AppSettings _draft;
  final _openaiController = TextEditingController();
  final _anthropicController = TextEditingController();
  final _customUrlController = TextEditingController();
  final _whitelistController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _draft = context.read<SettingsProvider>().settings;
    _openaiController.text = _draft.openaiApiKey;
    _anthropicController.text = _draft.anthropicApiKey;
    _customUrlController.text = _draft.customEndpointUrl;
  }

  @override
  void dispose() {
    _openaiController.dispose();
    _anthropicController.dispose();
    _customUrlController.dispose();
    _whitelistController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final updated = _draft.copyWith(
      openaiApiKey: _openaiController.text.trim(),
      anthropicApiKey: _anthropicController.text.trim(),
      customEndpointUrl: _customUrlController.text.trim(),
    );
    await context.read<SettingsProvider>().update(updated);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved'), backgroundColor: Colors.green),
      );
      Navigator.of(context).pop();
    }
  }

  void _addWhitelistItem() {
    final text = _whitelistController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _draft = _draft.copyWith(
        detailedAnalysisWhitelist: [..._draft.detailedAnalysisWhitelist, text],
      );
      _whitelistController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.cyanAccent,
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save', style: TextStyle(color: Colors.cyanAccent)),
          ),
        ],
      ),
      backgroundColor: const Color(0xFF0D1117),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SectionHeader('Inference'),
          _buildInferenceModeSelector(),
          const SizedBox(height: 16),
          const _SectionHeader('Thresholds'),
          _buildSlider(
            'Min Confidence',
            _draft.minConfidence,
            (v) => setState(() => _draft = _draft.copyWith(minConfidence: v)),
          ),
          _buildSlider(
            'Verification Trigger',
            _draft.verificationTrigger,
            (v) => setState(() => _draft = _draft.copyWith(verificationTrigger: v)),
          ),
          _buildIntSlider(
            'Target FPS',
            _draft.targetFps.toDouble(),
            1,
            60,
            (v) => setState(() => _draft = _draft.copyWith(targetFps: v.round())),
          ),
          const SizedBox(height: 16),
          const _SectionHeader('Local Model'),
          _buildLocalModelSelector(),
          const SizedBox(height: 16),
          const _SectionHeader('Cloud Provider'),
          _buildCloudProviderSelector(),
          const SizedBox(height: 16),
          const _SectionHeader('API Keys'),
          _buildTextField(_openaiController, 'OpenAI API Key', Icons.key),
          const SizedBox(height: 8),
          _buildTextField(_anthropicController, 'Anthropic API Key', Icons.key),
          const SizedBox(height: 8),
          _buildTextField(_customUrlController, 'Custom Endpoint URL', Icons.link),
          const SizedBox(height: 16),
          const _SectionHeader('Detailed Analysis Whitelist'),
          _buildWhitelistEditor(),
          const SizedBox(height: 16),
          const _SectionHeader('Storage'),
          SwitchListTile(
            title: const Text('Save crops to Firebase Storage',
                style: TextStyle(color: Colors.white)),
            value: _draft.saveToStorage,
            activeColor: Colors.cyanAccent,
            onChanged: (v) => setState(() => _draft = _draft.copyWith(saveToStorage: v)),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildInferenceModeSelector() {
    return DropdownButtonFormField<InferenceMode>(
      value: _draft.inferenceMode,
      dropdownColor: const Color(0xFF1C2128),
      style: const TextStyle(color: Colors.white),
      decoration: const InputDecoration(
        labelText: 'Inference Mode',
        labelStyle: TextStyle(color: Colors.cyanAccent),
        border: OutlineInputBorder(),
      ),
      items: InferenceMode.values
          .map((m) => DropdownMenuItem(value: m, child: Text(m.name)))
          .toList(),
      onChanged: (v) => setState(() => _draft = _draft.copyWith(inferenceMode: v)),
    );
  }

  Widget _buildLocalModelSelector() {
    return DropdownButtonFormField<LocalModel>(
      value: _draft.localModel,
      dropdownColor: const Color(0xFF1C2128),
      style: const TextStyle(color: Colors.white),
      decoration: const InputDecoration(
        labelText: 'Local Model',
        labelStyle: TextStyle(color: Colors.cyanAccent),
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(value: LocalModel.yolov8Tiny, child: Text('YOLOv8-tiny')),
        DropdownMenuItem(value: LocalModel.mobileNetV3, child: Text('MobileNetV3')),
      ],
      onChanged: (v) => setState(() => _draft = _draft.copyWith(localModel: v)),
    );
  }

  Widget _buildCloudProviderSelector() {
    return DropdownButtonFormField<CloudProvider>(
      value: _draft.cloudProvider,
      dropdownColor: const Color(0xFF1C2128),
      style: const TextStyle(color: Colors.white),
      decoration: const InputDecoration(
        labelText: 'Cloud Provider',
        labelStyle: TextStyle(color: Colors.cyanAccent),
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(value: CloudProvider.openai, child: Text('OpenAI GPT-4o')),
        DropdownMenuItem(value: CloudProvider.anthropic, child: Text('Anthropic Claude 3.5')),
        DropdownMenuItem(value: CloudProvider.custom, child: Text('Custom Endpoint')),
      ],
      onChanged: (v) => setState(() => _draft = _draft.copyWith(cloudProvider: v)),
    );
  }

  Widget _buildSlider(String label, double value, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            '$label: ${value.toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ),
        Slider(
          value: value,
          min: 0.1,
          max: 1.0,
          divisions: 18,
          activeColor: Colors.cyanAccent,
          inactiveColor: Colors.cyanAccent.withOpacity(0.2),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildIntSlider(
      String label, double value, double min, double max, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            '$label: ${value.round()}',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: (max - min).round(),
          activeColor: Colors.cyanAccent,
          inactiveColor: Colors.cyanAccent.withOpacity(0.2),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.cyanAccent),
        prefixIcon: Icon(icon, color: Colors.cyanAccent),
        border: const OutlineInputBorder(),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.cyanAccent.withOpacity(0.4)),
        ),
      ),
      obscureText: label.contains('Key'),
    );
  }

  Widget _buildWhitelistEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: _draft.detailedAnalysisWhitelist.map((item) {
            return Chip(
              label: Text(item, style: const TextStyle(color: Colors.black)),
              backgroundColor: Colors.cyanAccent,
              deleteIconColor: Colors.black54,
              onDeleted: () {
                setState(() {
                  final list = List<String>.from(_draft.detailedAnalysisWhitelist)
                    ..remove(item);
                  _draft = _draft.copyWith(detailedAnalysisWhitelist: list);
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _whitelistController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Add label (e.g. "bicycle")',
                  hintStyle: TextStyle(color: Colors.white38),
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _addWhitelistItem(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.add_circle, color: Colors.cyanAccent),
              onPressed: _addWhitelistItem,
            ),
          ],
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Colors.cyanAccent,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}
