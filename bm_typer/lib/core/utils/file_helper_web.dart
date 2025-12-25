import 'dart:convert';
import 'dart:typed_data';
import 'dart:html' as html;

/// Saves a file based on the platform.
Future<String?> saveFileUniversal(Uint8List bytes, String fileName) async {
  try {
    // Create a Blob from the bytes
    final blob = html.Blob([bytes]);
    
    // Create a URL for the blob
    final url = html.Url.createObjectUrlFromBlob(blob);
    
    // Create an anchor element to trigger the download
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..style.display = 'none';
      
    // Add to body, click, remove
    html.document.body?.append(anchor);
    anchor.click();
    anchor.remove();
    
    // Revoke URL
    html.Url.revokeObjectUrl(url);
    
    return null; // No file path on web
  } catch (e) {
    print('Error saving file on web: $e');
    return null;
  }
}

/// Saves a string content (like CSV/JSON) as a file.
Future<String?> saveStringFileUniversal(String content, String fileName) async {
  try {
    final bytes = utf8.encode(content);
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..style.display = 'none';
      
    html.document.body?.append(anchor);
    anchor.click();
    anchor.remove();
    
    html.Url.revokeObjectUrl(url);
    
    return null;
  } catch (e) {
    print('Error saving string file on web: $e');
    return null;
  }
}

/// Imports user data from a local file.
Future<String?> importFileUniversal() async {
  // Web implementation would need a file picker or predefined input element
  // For this scope, we return null or implement a basic prompt if needed
  print('Web import requires user interaction via File Upload element - not implemented in auto-logic');
  return null;
}
