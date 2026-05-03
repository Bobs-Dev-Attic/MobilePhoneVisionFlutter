# TFLite Model Assets

Place your TFLite model files here before building the app.

## Required Models

### YOLOv8-tiny
- File: `yolov8n.tflite`
- Download: https://github.com/ultralytics/ultralytics
- Convert: `yolo export model=yolov8n.pt format=tflite`

### MobileNetV3
- File: `mobilenet_v3.tflite`
- Download: https://tfhub.dev/google/imagenet/mobilenet_v3_small_100_224/classification/5
- Convert to TFLite using TensorFlow Lite Converter

## Label Files

Place corresponding label files in `assets/labels/`:
- `coco_labels.txt` - 80 COCO class labels for YOLOv8
- `imagenet_labels.txt` - 1000 ImageNet labels for MobileNetV3

## Input Specifications

| Model         | Input Size | Format    | Normalization |
|---------------|-----------|-----------|---------------|
| YOLOv8-tiny   | 640×640   | RGB float | [0, 1]        |
| MobileNetV3   | 224×224   | RGB float | [-1, 1]       |

## Integration

Uncomment and update the TFLite loading code in:
`lib/services/local_detection_service.dart`
