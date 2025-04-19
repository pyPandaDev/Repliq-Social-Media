import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class ShareService {
  // Generate a shareable link for the post
  String generateShareableLink(String postId) {
    // Replace with your actual domain
    return 'https://yourdomain.com/post/$postId';
  }

  // Share to any platform using native share sheet
  Future<void> shareToAny(String text, {String? imagePath}) async {
    if (imagePath != null) {
      await Share.shareXFiles(
        [XFile(imagePath)],
        text: text,
      );
    } else {
      await Share.share(text);
    }
  }

  // Share to WhatsApp
  Future<void> shareToWhatsApp(String text, {String? imagePath}) async {
    String whatsappUrl = 'whatsapp://send?text=${Uri.encodeComponent(text)}';
    if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
      await launchUrl(Uri.parse(whatsappUrl));
    }
  }

  // Share to Instagram
  Future<void> shareToInstagram(String imagePath) async {
    String instagramUrl = 'instagram://share';
    if (await canLaunchUrl(Uri.parse(instagramUrl))) {
      await launchUrl(Uri.parse(instagramUrl));
    }
  }

  // Share to X (Twitter)
  Future<void> shareToX(String text) async {
    String twitterUrl = 'https://twitter.com/intent/tweet?text=${Uri.encodeComponent(text)}';
    if (await canLaunchUrl(Uri.parse(twitterUrl))) {
      await launchUrl(Uri.parse(twitterUrl));
    }
  }

  // Share to Facebook
  Future<void> shareToFacebook(String text) async {
    String facebookUrl = 'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(text)}';
    if (await canLaunchUrl(Uri.parse(facebookUrl))) {
      await launchUrl(Uri.parse(facebookUrl));
    }
  }
} 