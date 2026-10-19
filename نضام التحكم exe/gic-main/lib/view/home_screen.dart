import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gic/models/admin_user.dart';
import 'package:gic/services/auth_service.dart';
import 'package:gic/services/permission_service.dart';
import 'package:gic/view/academic_tree.dart';
import 'package:gic/view/accounts_management_view.dart';
import 'package:gic/view/advertisements.dart';
import 'package:gic/view/analysis.dart';
import 'package:gic/view/audit_logs_view.dart';
import 'package:gic/view/employees_management_view.dart';
import 'package:gic/view/login_screen.dart';
import 'package:gic/view/notifications_management_view.dart';
import 'package:gic/view/queries.dart';
import 'package:gic/view/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'كلية الغد الدولية - لوحة التحكم',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto',
      ),
      home: AuthService.isLoggedIn ? const HomeScreen() : const LoginScreen(),
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
  static const Color accentGold = Color(0xFFC5A059);

  String activeTab = 'الخدمات';
  String currentDynamicPath = 'الرئيسية';

  bool showTreeView = false;
  bool isCollapsed = false;

  @override
  void initState() {
    super.initState();
    // التحقق الصارم من تسجيل الدخول - إذا لم يكن مسجلاً يعاد إلى شاشة الدخول فوراً
    if (AuthService.currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      });
      return;
    }

    _selectInitialTab();
  }

  void _selectInitialTab() {
    final user = AuthService.currentUser;
    if (user != null && !user.isSuperAdmin) {
      // تحديد أول قسم متاح للموظف
      if (PermissionService.canAccessModule('services')) {
        activeTab = 'الخدمات';
      } else if (PermissionService.canAccessModule('academic_tree')) {
        activeTab = 'الهيكل الأكاديمي';
        showTreeView = true;
      } else if (PermissionService.canAccessModule('notifications')) {
        activeTab = 'الإشعارات';
      } else if (PermissionService.canAccessModule('accounts')) {
        activeTab = 'الحسابات';
      } else if (PermissionService.canAccessModule('advertisements')) {
        activeTab = 'الاعلانات';
      } else if (PermissionService.canAccessModule('analysis')) {
        activeTab = 'التحليل';
      }
    }
  }

  void _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تسجيل الخروج', style: TextStyle(fontWeight: FontWeight.bold, color: primaryNavy)),
          content: const Text('هل ترغب في تسجيل الخروج من لوحة التحكم؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('تسجيل خروج', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (confirm == true) {
      await AuthService.logout();
      try {
        const MethodChannel('gic/window').invokeMethod('shrinkToLogin');
      } catch (_) {}
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  void _openChangePasswordDialog() {
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    bool isSaving = false;
    String? errorText;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: const Row(
              children: [
                Icon(Icons.lock_reset, color: primaryNavy, size: 26),
                SizedBox(width: 10),
                Text('تغيير كلمة المرور الخاصة بك', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryNavy)),
              ],
            ),
            content: SizedBox(
              width: 380,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'أدخل كلمة المرور الجديدة لحسابك:',
                    style: TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: newPassCtrl,
                    obscureText: true,
                    textDirection: TextDirection.ltr,
                    decoration: const InputDecoration(
                      labelText: 'كلمة المرور الجديدة *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock_outline),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmPassCtrl,
                    obscureText: true,
                    textDirection: TextDirection.ltr,
                    decoration: const InputDecoration(
                      labelText: 'تأكيد كلمة المرور الجديدة *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                      isDense: true,
                    ),
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 10),
                    Text(errorText!, style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء'),
              ),
              ElevatedButton.icon(
                onPressed: isSaving
                    ? null
                    : () async {
                        final p1 = newPassCtrl.text.trim();
                        final p2 = confirmPassCtrl.text.trim();
                        if (p1.isEmpty) {
                          setDialogState(() => errorText = 'يرجى إدخال كلمة المرور الجديدة');
                          return;
                        }
                        if (p1 != p2) {
                          setDialogState(() => errorText = 'كلمتا المرور غير متطابقتين');
                          return;
                        }

                        setDialogState(() {
                          isSaving = true;
                          errorText = null;
                        });

                        try {
                          await AuthService.changeCurrentAdminPassword(p1);
                          Navigator.pop(ctx);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('تم تغيير كلمة المرور بنجاح!', textDirection: TextDirection.rtl),
                                backgroundColor: Colors.green,
                              ),
                            );
                            setState(() {});
                          }
                        } catch (e) {
                          setDialogState(() {
                            isSaving = false;
                            errorText = e.toString().replaceAll('Exception:', '').trim();
                          });
                        }
                      },
                icon: isSaving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save, size: 18, color: Colors.white),
                label: const Text('حفظ التغيير', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: primaryNavy),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    if (user == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF070B19),
        body: Center(child: CircularProgressIndicator(color: accentGold)),
      );
    }
    final isSuper = user.isSuperAdmin;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          children: [
            // القائمة الجانبية (Sidebar)
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: isCollapsed ? 70 : 230,
              color: primaryNavy,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),

                  // زر الطي والتوسيع
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

                  // الشعار
                  Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: isCollapsed ? 45 : 85,
                      height: isCollapsed ? 45 : 80,
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
                  const SizedBox(height: 10),

                  // كارت بيانات المستخدم الحالي
                  if (!isCollapsed)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white.withOpacity(0.12)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: isSuper ? accentGold : Colors.white,
                            child: Icon(
                              isSuper ? Icons.shield : Icons.person,
                              size: 18,
                              color: isSuper ? Colors.white : primaryNavy,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user?.fullName ?? 'المدير العام',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isSuper ? 'مدير عام للنظام 👑' : 'موظف محدد الصلاحيات',
                                  style: TextStyle(
                                    color: isSuper ? accentGold : Colors.white70,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 6),

                  // قائمة التبويبات المفلترة ديناميكياً حسب صلاحيات المستخدم
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        const Divider(color: dividerColor, height: 1),

                        // 1. الخدمات
                        if (PermissionService.canAccessModule('services')) ...[
                          _buildNavItem('الخدمات', Icons.diamond_outlined),
                          const Divider(color: dividerColor, height: 1),
                        ],

                        // 2. الهيكل والشجرة الأكاديمية
                        if (PermissionService.canAccessModule('academic_tree')) ...[
                          InkWell(
                            onTap: () {
                              setState(() {
                                showTreeView = true;
                                activeTab = 'الهيكل الأكاديمي';
                                currentDynamicPath = 'الهيكل الأكاديمي والشجرة';
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              color: showTreeView ? Colors.white.withOpacity(0.12) : Colors.transparent,
                              child: Row(
                                mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.spaceBetween,
                                children: [
                                  if (!isCollapsed)
                                    const Flexible(
                                      child: Text(
                                        'الهيكل الأكاديمي',
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  Icon(Icons.account_tree_outlined, color: showTreeView ? topGold : Colors.white, size: 20),
                                ],
                              ),
                            ),
                          ),
                          const Divider(color: dividerColor, height: 1),
                        ],

                        // 3. الحسابات
                        if (PermissionService.canAccessModule('accounts')) ...[
                          _buildNavItem('الحسابات', Icons.people_outline),
                          const Divider(color: dividerColor, height: 1),
                        ],

                        // 4. الإشعارات
                        if (PermissionService.canAccessModule('notifications')) ...[
                          _buildNavItem('الإشعارات', Icons.notifications_active_outlined),
                          const Divider(color: dividerColor, height: 1),
                        ],

                        // 5. الإعلانات
                        if (PermissionService.canAccessModule('advertisements')) ...[
                          _buildNavItem('الاعلانات', Icons.tv),
                          const Divider(color: dividerColor, height: 1),
                        ],

                        // 6. التحليل
                        if (PermissionService.canAccessModule('analysis')) ...[
                          _buildNavItem('التحليل', Icons.insert_photo_outlined),
                          const Divider(color: dividerColor, height: 1),
                        ],

                        // 7. أقسام المدير العام الحصرية (Super Admin Only)
                        if (isSuper) ...[
                          const SizedBox(height: 10),
                          if (!isCollapsed)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              child: Text(
                                'إدارة النظام والرقابة',
                                style: TextStyle(color: accentGold.withOpacity(0.9), fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          _buildNavItem('الموظفين والصلاحيات', Icons.manage_accounts, badgeColor: accentGold),
                          const Divider(color: dividerColor, height: 1),
                          _buildNavItem('سجل الرقابة', Icons.history_edu_outlined, badgeColor: accentGold),
                          const Divider(color: dividerColor, height: 1),
                        ],
                      ],
                    ),
                  ),

                  // زر تسجيل الخروج السفلي
                  InkWell(
                    onTap: _handleLogout,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      color: Colors.red.shade900.withOpacity(0.3),
                      child: Row(
                        mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.spaceBetween,
                        children: [
                          if (!isCollapsed)
                            const Text(
                              'تسجيل الخروج',
                              style: TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          const Icon(Icons.logout, color: Colors.redAccent, size: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // المحتوى الرئيسي
            Expanded(
              child: Column(
                children: [
                  // الشريط العلوي (Navy Bar)
                  Container(
                    height: 36,
                    color: primaryNavy,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'المسار: $currentDynamicPath',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.person_pin, size: 16, color: accentGold),
                            const SizedBox(width: 6),
                            Text(
                              'مرحباً: ${user?.fullName ?? "المدير"} (${isSuper ? "المدير العام" : "موظف"})',
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 14),
                            InkWell(
                              onTap: _openChangePasswordDialog,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: accentGold.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: accentGold, width: 0.8),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.key, size: 12, color: accentGold),
                                    SizedBox(width: 5),
                                    Text(
                                      'تغيير كلمة المرور',
                                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // الشريط الذهبي
                  Container(
                    height: 6,
                    color: topGold,
                  ),

                  // مساحة العرض الرئيسية
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

  Widget _buildNavItem(String title, IconData iconData, {Color? badgeColor}) {
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
        color: isSelected ? Colors.white.withOpacity(0.12) : Colors.transparent,
        child: Row(
          mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.spaceBetween,
          children: [
            if (!isCollapsed)
              Flexible(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: badgeColor ?? Colors.white,
                    fontSize: 13.5,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            Icon(
              iconData,
              color: badgeColor ?? Colors.white,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    // 1. الشجرة الأكاديمية
    if (showTreeView) {
      return AcademicTreeView(
        onNodeAction: (action, node) {
          setState(() {
            currentDynamicPath = 'الشجرة الأكاديمية > ${node.title} ($action)';
          });
        },
      );
    }

    // 2. الخدمات والطلبات
    if (activeTab == 'الخدمات') {
      return ServicesView(
        onServiceTap: (path) {
          setState(() {
            currentDynamicPath = path;
          });
        },
      );
    }

    // 3. الإعلانات
    else if (activeTab == 'الاعلانات') {
      return AdsView(
        onPathChanged: (path) {
          setState(() {
            currentDynamicPath = path;
          });
        },
      );
    }

    // 4. الإشعارات
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

    // 5. التحليل والإحصائيات
    else if (activeTab == 'التحليل') {
      return const AnalysisView();
    }

    // 6. الحسابات ودليل الجامعة
    else if (activeTab == 'الحسابات') {
      return AccountsManagementView(
        onPathChanged: (path) {
          setState(() {
            currentDynamicPath = path;
          });
        },
      );
    }

    // 7. إدارة الموظفين والصلاحيات (للمدير العام)
    else if (activeTab == 'الموظفين والصلاحيات') {
      return EmployeesManagementView(
        onPathChanged: (path) {
          setState(() {
            currentDynamicPath = path;
          });
        },
      );
    }

    // 8. سجل الرقابة وتتبع العمليات (للمدير العام)
    else if (activeTab == 'سجل الرقابة') {
      return AuditLogsView(
        onPathChanged: (path) {
          setState(() {
            currentDynamicPath = path;
          });
        },
      );
    }

    // شاشة افتراضية
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
      ],
    );
  }
}