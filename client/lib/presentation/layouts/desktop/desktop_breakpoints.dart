class DesktopBreakpoints {
  static const double compact = 800;
  static const double medium = 1200;
  static const double expanded = 1600;

  static bool isCompact(double width) => width < medium;
  static bool isMedium(double width) => width >= medium && width < expanded;
  static bool isExpanded(double width) => width >= expanded;
}
