import 'package:flutter/material.dart';

class SubServicePlaceholderScreen extends StatelessWidget {
  final String title;

  const SubServicePlaceholderScreen({
    super.key,
    required this.title,
  });

  static const Color whiteBg = Colors.white;
  static const Color navyDark = Color(0xFF0B1E3D);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: whiteBg,
      body: SafeArea(
        bottom: false,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            children: [
              _buildAppBar(context),
              const Divider(height: 1, color: Color(0xFFF0F0F0)),
              const Expanded(
                child: SizedBox(), // Empty blank screen body
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(8),
            child: const Padding(
              padding: EdgeInsets.all(4.0),
              child: Icon(
                Icons.arrow_forward_rounded,
                color: navyDark,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: navyDark,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
