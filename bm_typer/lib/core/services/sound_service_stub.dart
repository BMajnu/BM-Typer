// Stub file for web audio functionality
// This file provides type definitions used by other parts of the app
// The actual implementation is in sound_service_web.dart

/// Stub class for CSS style access
class CssStyleDeclaration {
  String display = '';
}

/// Stub class that mirrors dart:html AudioElement interface
class AudioElement {
  String src = '';
  String preload = '';
  double volume = 1.0;
  double currentTime = 0;
  final CssStyleDeclaration style = CssStyleDeclaration();
  
  void remove() {}
  Future<void> play() async {}
}

/// Stub class for document body access
class DocumentBody {
  void append(dynamic element) {}
}

/// Stub class for document access
class HtmlDocument {
  DocumentBody? body;
}

/// Stub for document global
final HtmlDocument document = HtmlDocument();

/// Function to create an audio element (stub for non-web)
AudioElement createAudioElement() => AudioElement();

