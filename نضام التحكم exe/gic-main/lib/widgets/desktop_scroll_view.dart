import 'package:flutter/material.dart';

/// ويدجت تغليف الجداول على نظام ويندوز وسطح المكتب
/// يوفر أشرطة تمرير أفقية وعمودية ظاهرة دائماً (Thumb visible)
/// لضمان عدم اقتصاص أي أعمدة أو نصوص مهما كانت أبعاد الشاشة
class DesktopTableScrollView extends StatefulWidget {
  final Widget child;
  final double? minWidth;

  const DesktopTableScrollView({
    Key? key,
    required this.child,
    this.minWidth,
  }) : super(key: key);

  @override
  State<DesktopTableScrollView> createState() => _DesktopTableScrollViewState();
}

class _DesktopTableScrollViewState extends State<DesktopTableScrollView> {
  final ScrollController _hCtrl = ScrollController();
  final ScrollController _vCtrl = ScrollController();

  @override
  void dispose() {
    _hCtrl.dispose();
    _vCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = widget.minWidth != null 
            ? (widget.minWidth! > constraints.maxWidth ? widget.minWidth! : constraints.maxWidth)
            : constraints.maxWidth;

        return Scrollbar(
          controller: _vCtrl,
          thumbVisibility: true,
          trackVisibility: true,
          child: SingleChildScrollView(
            controller: _vCtrl,
            scrollDirection: Axis.vertical,
            child: Scrollbar(
              controller: _hCtrl,
              thumbVisibility: true,
              trackVisibility: true,
              notificationPredicate: (notif) => notif.metrics.axis == Axis.horizontal,
              child: SingleChildScrollView(
                controller: _hCtrl,
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: width),
                  child: widget.child,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// ويدجت تمرير أفقي مع شريط تمرير واضح ومرئي دائماً
class DesktopHorizontalScroll extends StatefulWidget {
  final Widget child;
  final double? minWidth;

  const DesktopHorizontalScroll({
    Key? key,
    required this.child,
    this.minWidth,
  }) : super(key: key);

  @override
  State<DesktopHorizontalScroll> createState() => _DesktopHorizontalScrollState();
}

class _DesktopHorizontalScrollState extends State<DesktopHorizontalScroll> {
  final ScrollController _ctrl = ScrollController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: _ctrl,
      thumbVisibility: true,
      trackVisibility: true,
      child: SingleChildScrollView(
        controller: _ctrl,
        scrollDirection: Axis.horizontal,
        child: widget.minWidth != null
            ? ConstrainedBox(
                constraints: BoxConstraints(minWidth: widget.minWidth!),
                child: widget.child,
              )
            : widget.child,
      ),
    );
  }
}
