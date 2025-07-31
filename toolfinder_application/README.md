lib/
├── main.dart                    # App entry point
├── models/
│   └── detection.dart          # Detection data model
├── services/
│   └── onnx_inference.dart     # ONNX inference service
├── widgets/
│   ├── glass_button.dart       # Glassmorphism button widget
│   └── bounding_box_overlay.dart # Custom painter for bounding boxes
└── screens/
    ├── home_screen.dart        # Main screen with camera/gallery options
    ├── image_preview_screen.dart # Image preview with detect button
    └── result_screen.dart      # Results with bounding boxes