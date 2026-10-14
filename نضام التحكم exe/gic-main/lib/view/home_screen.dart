import 'package:flutter/material.dart';
import 'package:gic/view/services.dart';
import 'package:gic/view/academic_tree.dart';
import 'package:gic/view/advertisements.dart';
import 'package:gic/view/queries.dart';
import 'package:gic/view/notifications_management_view.dart';
import 'package:gic/view/analysis.dart';
import 'package:gic/view/accounts_management_view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'كلية الغد الدولية',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto',
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color primaryNavy = Color(0xFF0E1B4D);
  static const Color topGold = Color(0xFFD4C116);
  static const Color dividerColor = Color(0xFF1B2E6B);

  String activeTab = 'الخدمات';
  String currentDynamicPath = 'الرئيسية';

  bool showTreeView = false;
  bool isCollapsed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          children: [

            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: isCollapsed ? 70 : 200,
              color: primaryNavy,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),


                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: Icon(
                        isCollapsed ? Icons.chevron_left : Icons.chevron_right,
                        color: Colors.white,
                        size: 24,
                      ),
                      onPressed: () {
                        setState(() {
                          isCollapsed = !isCollapsed;
                        });
                      },
                    ),
                  ),


                  Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: isCollapsed ? 45 : 90,
                      height: isCollapsed ? 45 : 85,
                      child: Image.asset(
                        'image/logo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                'gic',
                                style: TextStyle(
                                  fontSize: isCollapsed ? 12 : 18,
                                  fontWeight: FontWeight.bold,
                                  color: primaryNavy,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 5),


                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Align(
                      alignment: isCollapsed ? Alignment.center : Alignment.centerLeft,
                      child: IconButton(
                        icon: Icon(
                          Icons.menu,
                          color: showTreeView ? topGold : Colors.white,
                          size: 22,
                        ),
                        onPressed: () {
                          setState(() {
                            showTreeView = true;
                            currentDynamicPath = 'الهيكل الأكاديمي والشجرة';
                          });
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 5),


                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        const Divider(color: dividerColor, height: 1),
                        _buildNavItem('الخدمات', Icons.diamond_outlined),
                        const Divider(color: dividerColor, height: 1),
                        _buildNavItem('الحسابات', Icons.people_outline),
                        const Divider(color: dividerColor, height: 1),
                        _buildNavItem('الإشعارات', Icons.notifications_active_outlined),
                        const Divider(color: dividerColor, height: 1),
                        _buildNavItem('الاعلانات', Icons.tv),
                        const Divider(color: dividerColor, height: 1),
                        _buildNavItem('التحليل', Icons.insert_photo_outlined),
                        const Divider(color: dividerColor, height: 1),
                      ],
                    ),
                  ),
                ],
              ),
            ),


            Expanded(
              child: Column(
                children: [

                  Container(
                    height: 32,
                    color: primaryNavy,
                  ),


                  Container(
                    height: 25,
                    color: topGold,
                  ),


                  Expanded(
                    child: Container(
                      color: const Color(0xFFEBEBEB),
                      width: double.infinity,
                      child: _buildMainContent(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(String title, IconData iconData) {
    final bool isSelected = activeTab == title && !showTreeView;
    return InkWell(
      onTap: () {
        setState(() {
          activeTab = title;
          showTreeView = false;
          currentDynamicPath = title;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: isSelected ? Colors.white.withOpacity(0.08) : Colors.transparent,
        child: Row(
          mainAxisAlignment: isCollapsed
              ? MainAxisAlignment.center
              : MainAxisAlignment.spaceBetween,
          children: [
            if (!isCollapsed)
              Flexible(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            Icon(
              iconData,
              color: Colors.white,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {

    if (showTreeView) {
      return AcademicTreeView(
        onNodeAction: (action, node) {
          setState(() {
            currentDynamicPath = 'الشجرة الأكاديمية > ${node.title} ($action)';
          });
        },
      );
    }


    if (activeTab == 'الخدمات') {
      return ServicesView(
        onServiceTap: (path) {
          setState(() {
            currentDynamicPath = path;
          });
        },
      );
    }


    else if (activeTab == 'الاعلانات') {
      return AdsView(
        onPathChanged: (path) {
          setState(() {
            currentDynamicPath = path;
          });
        },
      );
    }


    else if (activeTab == 'الإشعارات' || activeTab == 'الاستعلامات') {
      return NotificationsManagementView(
        onPathChanged: (path) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && currentDynamicPath != path) {
              setState(() {
                currentDynamicPath = path;
              });
            }
          });
        },
      );
    }
    
    else if (activeTab == 'التحليل') {
      return const AnalysisView();
    }

    else if (activeTab == 'الحسابات') {
      return AccountsManagementView(
        onPathChanged: (path) {
          setState(() {
            currentDynamicPath = path;
          });
        },
      );
    }

    else {
      return Column(
        children: [
          Expanded(
            child: Center(
              child: Text(
                'أهلاً بك! تم تسجيل الدخول بنجاح.\nقسم: [$activeTab]',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  height: 1.5,
                ),
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
                  'المسار: $currentDynamicPath',
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
      );
    }
  }
}