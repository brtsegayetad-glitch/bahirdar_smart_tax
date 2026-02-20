import 'dart:html' as html;

void downloadWebFile(List<int> bytes, String fileName) {
  final blob = html.Blob([bytes], 'text/csv;charset=utf-8');
  final url = html.Url.createObjectUrlFromBlob(blob);

  // 'final anchor =' የሚለውን በማጥፋት በቀጥታ እንዲህ ይጻፋል
  html.AnchorElement(href: url)
    ..setAttribute("download", fileName)
    ..click(); // ይህ መስመር ነው ዳውንሎድ የሚያደርገው

  html.Url.revokeObjectUrl(url);
}
