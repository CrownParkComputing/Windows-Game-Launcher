// Helper method to get the media type for a section
String _getSectionMediaType(String sectionKey) {
  switch (sectionKey) {
    case 'left':
      return widget.settingsProvider.selectedLeftImage;
    case 'right':
      return widget.settingsProvider.selectedRightImage;
    case 'top':
      return widget.settingsProvider.selectedTopImage;
    case 'bottom':
      return widget.settingsProvider.selectedBottomImage;
    case 'main':
      return widget.settingsProvider.selectedMainImage;
    case 'top_left':
      return widget.settingsProvider.selectedTopLeftImage;
    case 'top_center':
      return widget.settingsProvider.selectedTopCenterImage;
    case 'top_right':
      return widget.settingsProvider.selectedTopRightImage;
    default:
      return 'logo';
  }
}

// Debug method to print current media types
void _debugPrintMediaTypes() {
  // Removed print statements
}

@override
void initState() {
  super.initState();
  _layoutManager = LayoutManager(settingsProvider: widget.settingsProvider);
} 