/// File type categories for assignment submissions
class FileTypeCategory {
  final String label;
  final List<String> types;
  const FileTypeCategory(this.label, this.types);
}

const List<FileTypeCategory> kFileTypeCategories = [
  FileTypeCategory('Documents', [
    'pdf', 'doc', 'docx', 'odt', 'rtf', 'txt', 'wpd', 'pages',
  ]),
  FileTypeCategory('Spreadsheets', [
    'xls', 'xlsx', 'csv',
    // 'ods', 'numbers', 'tsv',
  ]),
  FileTypeCategory('Presentations', [
    'ppt', 'pptx',
    // 'odp', 'key',
  ]),
  FileTypeCategory('Images', [
    'jpg', 'jpeg', 'png', 'gif', 'bmp', 'svg', 'webp', 'ico', 'tiff', 'heic',
  ]),
  FileTypeCategory('Audio', [
    'mp3', 'wav', 'm4a', 'aac', 'flac', 'ogg', 'wma', 'aiff', 'opus',
  ]),
  FileTypeCategory('Video', [
    'mp4', 'avi', 'mov', 'mkv', 'flv', 'webm', 'wmv', 'mts', 'vob', 'ogv',
  ]),
  // FileTypeCategory('Code', [
  //   'py', 'js', 'java', 'cpp', 'c', 'h', 'html', 'css', 'sql', 'rs', 'go',
  //   'ts', 'tsx', 'jsx', 'php', 'rb', 'swift', 'kt', 'scala', 'sh',
  // ]),
  FileTypeCategory('Archives', [
    'zip', 'rar', '7z', 'tar', 'gz', 'bz2', 'xz', 'iso',
  ]),
  FileTypeCategory('Data', [
    'json', 'xml', 'yaml', 'yml', 'toml', 'ini', 'env', 'sql',
  ]),
  FileTypeCategory('eBooks', [
    'pdf', 'epub', 'mobi', 'azw', 'azw3',
  ]),
];
