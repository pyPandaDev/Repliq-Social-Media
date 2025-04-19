import 'package:flutter/material.dart';
import 'package:repliq/services/share_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ShareButton extends StatefulWidget {
  final String postId;
  final String? imagePath;

  const ShareButton({
    Key? key,
    required this.postId,
    this.imagePath,
  }) : super(key: key);

  @override
  State<ShareButton> createState() => _ShareButtonState();
}

class _ShareButtonState extends State<ShareButton> with SingleTickerProviderStateMixin {
  final ShareService _shareService = ShareService();
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showShareOptions(BuildContext context) {
    final String shareableLink = _shareService.generateShareableLink(widget.postId);
    final String shareText = 'Check out this post: $shareableLink';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 300),
        tween: Tween(begin: 1.0, end: 0.0),
        curve: Curves.easeOut,
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, value * 200),
            child: child,
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Share to',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildShareOption(
                    context,
                    'WhatsApp',
                    FontAwesomeIcons.whatsapp,
                    const Color(0xFF25D366),
                    () => _shareService.shareToWhatsApp(shareText, imagePath: widget.imagePath),
                  ),
                  _buildShareOption(
                    context,
                    'Instagram',
                    FontAwesomeIcons.instagram,
                    const Color(0xFFE1306C),
                    () => widget.imagePath != null 
                        ? _shareService.shareToInstagram(widget.imagePath!)
                        : null,
                  ),
                  _buildShareOption(
                    context,
                    'X',
                    FontAwesomeIcons.xTwitter,
                    Colors.white,
                    () => _shareService.shareToX(shareText),
                  ),
                  _buildShareOption(
                    context,
                    'Facebook',
                    FontAwesomeIcons.facebook,
                    const Color(0xFF1877F2),
                    () => _shareService.shareToFacebook(shareText),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildShareOption(
                context,
                'More',
                ImageIcon(
                  const AssetImage('assets/images/share.png'),
                  color: Colors.white,
                  size: 24,
                ),
                Colors.grey[600]!,
                () => _shareService.shareToAny(shareText, imagePath: widget.imagePath),
                isWide: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShareOption(
    BuildContext context,
    String label,
    dynamic icon,
    Color color,
    VoidCallback? onTap, {
    bool isWide = false,
  }) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 200),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: isWide ? 200 : 80,
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            children: [
              if (icon is IconData)
                Icon(icon, color: color, size: 24)
              else if (icon is ImageIcon)
                icon,
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        _showShareOptions(context);
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Image.asset(
          'assets/images/share.png',
          width: 21,
          height: 21,
          color: Colors.white,
        ),
      ),
    );
  }
} 