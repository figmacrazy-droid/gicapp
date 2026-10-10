import 'package:flutter/material.dart';

class AdsView extends StatefulWidget {
  final Function(String path) onPathChanged;

  const AdsView({
    Key? key,
    required this.onPathChanged,
  }) : super(key: key);

  @override
  State<AdsView> createState() => _AdsViewState();
}

class _AdsViewState extends State<AdsView> {
  static const Color primaryNavy = Color(0xFF0E1B4D);
  static const Color calendarBg = Color(0xFF0B1736);
  static const Color accentGold = Color(0xFFC5A059);

  String activeSubTab = 'البنر الإعلاني';
  bool sendNotification = false;
  int selectedBannerIndex = 0;


  DateTime currentDate = DateTime(2026, 9, 25);
  int? selectedDay = 25;
  List<int> eventDays = [26, 30];

  final List<String> monthsNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  final List<Map<String, dynamic>> bannersData = [
    {'id': '1', 'title': 'بنر 1'},
    {'id': '2', 'title': 'بنر 2'},
    {'id': '3', 'title': 'بنر 3'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onPathChanged('الإعلانات > $activeSubTab');
    });
  }


  void _nextMonth() {
    setState(() {
      currentDate = DateTime(currentDate.year, currentDate.month + 1, 1);
      selectedDay = null;
    });
  }


  void _previousMonth() {
    setState(() {
      currentDate = DateTime(currentDate.year, currentDate.month - 1, 1);
      selectedDay = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  SizedBox(
                    width: 180,
                    child: Column(
                      children: [
                        _buildSubTabButton('البنر الإعلاني', Icons.arrow_right),
                        const SizedBox(height: 10),
                        _buildSubTabButton('التقويم السنوي', Icons.arrow_right),
                        const SizedBox(height: 10),
                        _buildSubTabButton('التخصصات', Icons.arrow_right),
                      ],
                    ),
                  ),

                  const SizedBox(width: 20),


                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E2E2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: _buildDynamicContent(),
                    ),
                  ),
                ],
              ),
            ),
          ),


          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            color: const Color(0xFFDCDCDC),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_on_outlined, size: 18, color: primaryNavy),
                const SizedBox(width: 8),
                Text(
                  'المسار: الإعلانات > $activeSubTab',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: primaryNavy,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicContent() {
    if (activeSubTab == 'البنر الإعلاني') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Row(
              children: List.generate(3, (index) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6.0),
                    child: InkWell(
                      onTap: () => setState(() => selectedBannerIndex = index),
                      child: _buildCardItem(
                        title: 'بنر ${index + 1}',
                        isSelected: selectedBannerIndex == index,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: selectedBannerIndex == index ? accentGold : Colors.grey,
                  shape: BoxShape.circle,
                ),
              );
            }),
          ),
          const SizedBox(height: 20),
          _buildBottomControls(
            addLabel: 'إضافة بنر',
            onAddPressed: () => _showUploadDialog(context),
            showAddButton: true,
            showNotificationCheckbox: true,
          ),
        ],
      );
    } else if (activeSubTab == 'التقويم السنوي') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Center(
              child: Container(
                width: 340,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: calendarBg,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: _previousMonth,
                          icon: const Icon(Icons.arrow_back_ios, color: accentGold, size: 16),
                        ),

                        InkWell(
                          onTap: () => _showYearPicker(context),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: accentGold,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${currentDate.year}',
                              style: const TextStyle(color: primaryNavy, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),

                        InkWell(
                          onTap: () => _showMonthPicker(context),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: accentGold,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              monthsNames[currentDate.month - 1],
                              style: const TextStyle(color: primaryNavy, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _nextMonth,
                          icon: const Icon(Icons.arrow_forward_ios, color: accentGold, size: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text('Sa', style: TextStyle(color: accentGold, fontWeight: FontWeight.bold)),
                        Text('Fr', style: TextStyle(color: accentGold, fontWeight: FontWeight.bold)),
                        Text('Th', style: TextStyle(color: accentGold, fontWeight: FontWeight.bold)),
                        Text('We', style: TextStyle(color: accentGold, fontWeight: FontWeight.bold)),
                        Text('Tu', style: TextStyle(color: accentGold, fontWeight: FontWeight.bold)),
                        Text('Mo', style: TextStyle(color: accentGold, fontWeight: FontWeight.bold)),
                        Text('Su', style: TextStyle(color: accentGold, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildCalendarGrid(),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildBottomControls(
            addLabel: '',
            onAddPressed: () {},
            showAddButton: false,
            showNotificationCheckbox: false,
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: GridView.builder(
              itemCount: 4,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.3,
              ),
              itemBuilder: (context, index) {
                return InkWell(
                  onTap: () => setState(() => selectedBannerIndex = index),
                  child: _buildCardItem(
                    title: 'تخصص ${index + 1}',
                    isSelected: selectedBannerIndex == index,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          _buildBottomControls(
            addLabel: 'إضافة تخصص',
            onAddPressed: () => _showAddMajorDialog(context),
            showAddButton: true,
            showNotificationCheckbox: true,
          ),
        ],
      );
    }
  }

  Widget _buildCalendarGrid() {
    final int daysInMonth = DateUtils.getDaysInMonth(currentDate.year, currentDate.month);
    final int firstWeekday = DateTime(currentDate.year, currentDate.month, 1).weekday;

    List<int> calendarDays = [];
    int startOffset = (firstWeekday % 7);
    for (int i = 0; i < startOffset; i++) {
      calendarDays.add(0);
    }
    for (int i = 1; i <= daysInMonth; i++) {
      calendarDays.add(i);
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: calendarDays.length,
      itemBuilder: (context, index) {
        final day = calendarDays[index];
        if (day == 0) {
          return const SizedBox.shrink();
        }

        final bool isSelected = (day == selectedDay);
        final bool hasEvent = eventDays.contains(day);

        return GestureDetector(
          onTap: () {
            setState(() => selectedDay = day);
            if (activeSubTab == 'التقويم السنوي') {
              _showAddEventDialog(context, day);
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? accentGold : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  '$day',
                  style: TextStyle(
                    color: isSelected ? primaryNavy : Colors.white,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
                if (hasEvent)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const Icon(
                          Icons.notifications,
                          size: 10,
                          color: accentGold,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showMonthPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('اختر الشهر', style: TextStyle(color: primaryNavy, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 250,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(12, (index) {
              return InkWell(
                onTap: () {
                  setState(() {
                    currentDate = DateTime(currentDate.year, index + 1, 1);
                    selectedDay = null;
                  });
                  Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: currentDate.month == (index + 1) ? accentGold : Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    monthsNames[index],
                    style: TextStyle(
                      color: currentDate.month == (index + 1) ? primaryNavy : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  void _showYearPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('اختر السنة', style: TextStyle(color: primaryNavy, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 250,
          height: 200,
          child: ListView.builder(
            itemCount: 11,
            itemBuilder: (context, index) {
              int year = 2020 + index;
              return ListTile(
                title: Text('$year', style: TextStyle(
                  color: currentDate.year == year ? accentGold : Colors.black,
                  fontWeight: currentDate.year == year ? FontWeight.bold : FontWeight.normal,
                )),
                onTap: () {
                  setState(() {
                    currentDate = DateTime(year, currentDate.month, 1);
                    selectedDay = null;
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls({
    required String addLabel,
    required VoidCallback onAddPressed,
    required bool showAddButton,
    required bool showNotificationCheckbox,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (showNotificationCheckbox)
          Row(
            children: [
              Checkbox(
                value: sendNotification,
                activeColor: primaryNavy,
                onChanged: (val) => setState(() => sendNotification = val ?? false),
              ),
              const Text(
                'هل تريد النشر وإيصال إشعار ؟',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Colors.black87),
              ),
            ],
          )
        else
          const SizedBox.shrink(),
        Row(
          children: [
            _buildActionButton('حذف', Icons.delete_outline, Colors.red[700]!, () {}),
            const SizedBox(width: 10),
            _buildActionButton('تعديل', Icons.edit_outlined, primaryNavy, () {}),
            if (showAddButton) ...[
              const SizedBox(width: 10),
              _buildActionButton(addLabel, Icons.add_circle_outline, accentGold, onAddPressed),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildCardItem({required String title, required bool isSelected}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isSelected ? accentGold : Colors.transparent, width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_outlined, size: 40, color: isSelected ? primaryNavy : Colors.black38),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(fontSize: 12, color: isSelected ? primaryNavy : Colors.black54, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }

  Widget _buildSubTabButton(String title, IconData icon) {
    final bool isSelected = activeSubTab == title;
    return Material(
      color: isSelected ? primaryNavy : const Color(0xFF4A5A85),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () {
          setState(() => activeSubTab = title);
          widget.onPathChanged('الإعلانات > $title');
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5)),
              Icon(icon, color: Colors.white, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: Colors.white),
      label: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 2,
      ),
    );
  }

  void _showUploadDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة بنر إعلاني جديد', style: TextStyle(color: primaryNavy, fontWeight: FontWeight.bold)),
        content: Container(
          height: 120,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[400]!),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_upload_outlined, size: 40, color: primaryNavy),
              SizedBox(height: 8),
              Text('اختر صورة للرفع', style: TextStyle(color: Colors.black54)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: accentGold),
            onPressed: () => Navigator.pop(context),
            child: const Text('رفع', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }


  void _showAddEventDialog(BuildContext context, int clickedDay) {
    bool dialogNotification = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'إضافة مناسبة ليوم $clickedDay ${monthsNames[currentDate.month - 1]} ${currentDate.year}',
            style: const TextStyle(color: primaryNavy, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const TextField(
                  decoration: InputDecoration(
                    labelText: 'اسم المناسبة',
                  ),
                ),
                const SizedBox(height: 12),
                const TextField(
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'وصف المناسبة',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Checkbox(
                      value: dialogNotification,
                      activeColor: primaryNavy,
                      onChanged: (val) {
                        setDialogState(() {
                          dialogNotification = val ?? false;
                        });
                      },
                    ),
                    const Text('إرسال إشعار للمستخدمين', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: accentGold,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                setState(() {
                  if (!eventDays.contains(clickedDay)) {
                    eventDays.add(clickedDay);
                  }
                });
                Navigator.pop(context);
              },
              child: const Text('إضافة', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddMajorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('إضافة تخصص جديد', style: TextStyle(color: primaryNavy, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const TextField(
                decoration: InputDecoration(
                  labelText: 'اسم التخصص',
                  floatingLabelBehavior: FloatingLabelBehavior.auto,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                height: 90,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[400]!),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image_outlined, size: 30, color: primaryNavy),
                    SizedBox(height: 5),
                    Text('رفع صورة التخصص', style: TextStyle(color: Colors.black54, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: accentGold,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('رفع', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}