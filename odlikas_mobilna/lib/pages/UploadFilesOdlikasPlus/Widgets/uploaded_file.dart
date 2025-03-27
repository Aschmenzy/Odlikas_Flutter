/// Jednostavni model za pohranu informacija o prenesenoj datoteci.
class UploadedFile {
  final String name;
  final String url;
  final String extension;
  UploadedFile({
    required this.name,
    required this.url,
    required this.extension,
  });
}
