import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class BottomCredits extends StatelessWidget {
  final String locale;
  final bool dark;

  const BottomCredits({
    super.key,
    required this.locale,
    this.dark = false,
  });

  Future<void> _launch(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final textColor = dark ? Colors.white70 : Colors.black54;
    final iconColor = dark ? Colors.white60 : Colors.black45;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            locale == 'id'
                ? 'Dibuat oleh: Ir. Riovan Styx Roring'
                : 'Created by: Ir. Riovan Styx Roring',
            style: TextStyle(
              fontSize: 11,
              color: textColor,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _SocialButton(
                icon: _tiktokIcon(iconColor),
                label: 'TikTok',
                color: iconColor,
                onTap: () => _launch('https://www.tiktok.com/@ir.riovansroring'),
              ),
              const SizedBox(width: 20),
              _SocialButton(
                icon: Icons.camera_alt_outlined,
                label: 'Instagram',
                color: iconColor,
                onTap: () => _launch('https://www.instagram.com/ir.riovansroring/'),
              ),
              const SizedBox(width: 20),
              _SocialButton(
                icon: Icons.play_circle_outline,
                label: 'YouTube',
                color: iconColor,
                onTap: () => _launch('https://youtube.com/@ir.riovanroring'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tiktokIcon(Color color) {
    return Icon(Icons.music_note_outlined, color: color, size: 18);
  }
}

class _SocialButton extends StatelessWidget {
  final dynamic icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SocialButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon is IconData
              ? Icon(icon as IconData, color: color, size: 18)
              : icon as Widget,
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 9, color: color),
          ),
        ],
      ),
    );
  }
}
