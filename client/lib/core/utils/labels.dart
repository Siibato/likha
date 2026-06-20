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

String componentLabel(String value) {
  switch (value) {
    case 'ww':
      return 'Written Work';
    case 'pt':
      return 'Performance Task';
    case 'qa':
      return 'Term Assessment';
    default:
      return value;
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
