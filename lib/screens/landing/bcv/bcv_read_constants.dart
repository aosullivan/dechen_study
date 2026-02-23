/// Layout and UI constants for BcvReadScreen and its sub-widgets.
abstract final class BcvReadConstants {
  BcvReadConstants._();

  static const double laptopBreakpoint = 900;

  /// On narrow screens (e.g. phone), nav panels are capped at this fraction of viewport height
  /// so the reader pane gets at least (1 - this) of the space (e.g. 50% reader minimum).
  static const double mobileMaxNavFraction = 0.5;

  /// Min height for mobile nav segment bar (touch target).
  static const double mobileNavBarHeight = 48.0;

  /// Max height for one expanded nav pane on mobile.
  static const double mobilePanelMaxHeight = 280.0;
  static const double rightPanelsMinWidth = 200;
  static const double rightPanelsMaxWidth = 500;
  static const double panelMinHeight = 60;

  /// Line height for panel list rows. Tied to [panelFontSize] for readability.
  static const double panelLineHeight = 24.0;
  static const double panelPaddingH = 12.0;
  static const double panelPaddingV = 6.0;

  static const double sectionSliderLineHeight = 24.0;
  static const int sectionSliderVisibleLines = 10;
  static const double sectionSliderTopLevelGap = 10.0;
  static const double sectionSliderCooperatingMainGap = 6.0;
  static const double sectionSliderTopLevelDividerThickness = 1.0;

  /// Minimum readable font size for nav panels (chapters, section list, breadcrumb).
  /// Keeps navigation accessible; reader pane keeps its own size so you can see enough text.
  static const double panelFontSize = 14.0;

  /// Section list uses same size as panel for consistency.
  static const double sectionListFontSize = 14.0;
  static const double sectionListLineHeight = 24.0;

  static const int maxSectionOverlayMeasureRetries = 5;
  static const double sectionSliderIndentPerLevel = 12.0;
  static const double breadcrumbIndentPerLevel = 16.0;
}
