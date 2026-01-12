//? Helper class for avatar data
class AvatarData {
  final double left;      //* Percentage of screen width (0.0 to 1.0)
  final double top;       //* Percentage of screen height (0.0 to 1.0)
  final double size;      //* Size in pixels
  final String imageUrl;
  final String brandName; //* For fallback display

  AvatarData({
    required this.left,
    required this.top,
    required this.size,
    required this.imageUrl,
    required this.brandName,
  });
}