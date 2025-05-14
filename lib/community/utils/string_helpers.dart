// lib/community/utils/string_helpers.dart

class StringHelpers {
  // Get shortened preview of text with ellipsis
  static String getPreview(String? text, int maxLength) {
    if (text == null || text.isEmpty) {
      return '';
    }

    if (text.length <= maxLength) {
      return text;
    }

    return '${text.substring(0, maxLength)}...';
  }

  // Get initials from a name
  static String getInitials(String name) {
    if (name.isEmpty) return '';

    final nameParts = name.split(' ');

    if (nameParts.length == 1) {
      return nameParts[0].isNotEmpty ? nameParts[0][0].toUpperCase() : '';
    }

    // Get first letter of first and last parts
    final firstInitial = nameParts[0].isNotEmpty ? nameParts[0][0] : '';
    final lastInitial = nameParts.last.isNotEmpty ? nameParts.last[0] : '';

    return (firstInitial + lastInitial).toUpperCase();
  }

  // Determine if a text contains a hashtag
  static List<String> extractHashtags(String text) {
    final RegExp hashtagRegExp = RegExp(r'#(\w+)');
    final matches = hashtagRegExp.allMatches(text);

    return matches.map((match) => '#${match.group(1)}').toList();
  }

  // Format numbers for UI display (e.g. 1000 -> 1K)
  static String formatCount(int count) {
    if (count < 1000) {
      return count.toString();
    } else if (count < 10000) {
      final decimal = (count / 1000).toStringAsFixed(1);
      return '${decimal}K';
    } else if (count < 1000000) {
      final rounded = (count / 1000).floor();
      return '${rounded}K';
    } else {
      final decimal = (count / 1000000).toStringAsFixed(1);
      return '${decimal}M';
    }
  }

  // Check if a string is a valid URL
  static bool isValidUrl(String? url) {
    if (url == null || url.isEmpty) return false;

    final urlRegExp = RegExp(
        r'^(http|https)://'
        r'([a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,6}'
        r'(/[a-zA-Z0-9\.\?\=\&\%\-\_\+]*)*$'
    );

    return urlRegExp.hasMatch(url);
  }

  // Generate a slug from a title for URLs
  static String generateSlug(String title) {
    // Convert to lowercase
    var slug = title.toLowerCase();

    // Replace non-alphanumeric characters with dashes
    slug = slug.replaceAll(RegExp(r'[^a-z0-9]+'), '-');

    // Remove leading and trailing dashes
    slug = slug.replaceAll(RegExp(r'^-+|-+$'), '');

    return slug;
  }
}