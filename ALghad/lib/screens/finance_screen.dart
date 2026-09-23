import 'package:flutter/material.dart';

class FinanceScreen extends StatelessWidget {
  const FinanceScreen({super.key});

  static const Color whiteBg = Colors.white;
  static const Color navyDark = Color(0xFF0B1E3D);
  static const Color cardBg = Colors.white;

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
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                  children: [
                    _buildCard(
                      context,
                      title: 'طلب كشف حساب تفصيلي',
                      onTap: () {},
                    ),
                    const SizedBox(height: 14),
                    _buildCard(
                      context,
                      title: 'سند تسديد الرسوم الدراسية',
                      onTap: () {},
                    ),
                    const SizedBox(height: 14),
                    _buildCard(
                      context,
                      title: 'تسديد رسوم',
                      onTap: () {},
                    ),
                    const SizedBox(height: 14),
                    _buildCard(
                      context,
                      title: 'تحويل رسوم',
                      onTap: () {},
                    ),
                    const SizedBox(height: 14),
                    _buildCard(
                      context,
                      title: 'سحب رسوم',
                      onTap: () {},
                    ),
                  ],
                ),
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
          const Text(
            'المالية',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: navyDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(
            color: const Color(0xFFF2F2F2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            _buildGicBadge(),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: navyDark,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGicBadge() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: navyDark,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: navyDark.withOpacity(0.25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: Image.asset(
              'assets/images/gic_shield.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Text(
                    'gic',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
