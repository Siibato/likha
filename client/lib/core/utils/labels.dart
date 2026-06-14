String submissionTypeFromBools(bool allowsText, bool allowsFile) {
  if (allowsText && allowsFile) {
    return 'Text or File';
  } else if (allowsText) {
    return 'Text Only';
  } else if (allowsFile) {
    return 'File Only';
  } else {
    return 'Unknown';
  }
}

String questionTypeLabel(String type) {
  switch (type) {
    case 'multiple_choice':
      return 'Multiple Choice';
    case 'identification':
      return 'Identification';
    case 'enumeration':
      return 'Enumeration';
    case 'essay':
      return 'Essay';
    default:
      return type;
  }
}
