// Web-specific implementation for audio functionality
// This file is conditionally imported on web platforms

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// AudioElement type alias for web platform
typedef AudioElement = html.AudioElement;

/// Creates an audio element for web platform
html.AudioElement createAudioElement() => html.AudioElement();

/// Get the document for web platform
html.HtmlDocument get document => html.document;

