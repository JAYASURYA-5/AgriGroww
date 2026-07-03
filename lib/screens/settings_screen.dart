import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/app_state.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Toggle states
  bool _pushNotifications = true;
  bool _emailNotifications = false;
  bool _smsNotifications = true;
  bool _dataSharing = false;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  // Load individual notification preferences
  Future<void> _loadNotificationSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _pushNotifications = prefs.getBool('push_notifications') ?? true;
        _emailNotifications = prefs.getBool('email_notifications') ?? false;
        _smsNotifications = prefs.getBool('sms_notifications') ?? true;
        _dataSharing = prefs.getBool('data_sharing') ?? false;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading notifications settings: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Save setting helpers
  Future<void> _saveBoolSetting(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } catch (e) {
      debugPrint('Error saving setting $key: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF22C55E)),
          ),
        ),
      );
    }

    // Wrap settings in ValueListenableBuilders so they immediately adapt to language & theme updates
    return ValueListenableBuilder<String>(
      valueListenable: AppState().languageNotifier,
      builder: (context, lang, child) {
        return ValueListenableBuilder<String>(
          valueListenable: AppState().themeNotifier,
          builder: (context, theme, child) {
            final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
            final cardBg = Theme.of(context).cardColor;
            final dividerCol = Theme.of(context).dividerColor;
            final textCol = Theme.of(context).colorScheme.onSurface;

            return Scaffold(
              backgroundColor: scaffoldBg,
              appBar: AppBar(
                backgroundColor: cardBg,
                elevation: 0.5,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back, color: textCol),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                title: Text(
                  AppLocalizations.translate(lang, 'settings'),
                  style: TextStyle(
                    color: textCol,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                centerTitle: true,
                actions: [
                  TextButton(
                    onPressed: () => _showLogoutDialog(lang),
                    child: Text(
                      AppLocalizations.translate(lang, 'logout'),
                      style: const TextStyle(
                        color: Color(0xFFEA580C),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Notifications Group
                    _buildSectionHeader(AppLocalizations.translate(lang, 'notifications'), textCol),
                    const SizedBox(height: 8),
                    _buildGroupCard(cardBg, dividerCol, [
                      _buildSwitchRow(
                        icon: Icons.notifications_none_outlined,
                        title: AppLocalizations.translate(lang, 'push_notifications'),
                        subtitle: AppLocalizations.translate(lang, 'push_desc'),
                        value: _pushNotifications,
                        textCol: textCol,
                        onChanged: (val) {
                          setState(() => _pushNotifications = val);
                          _saveBoolSetting('push_notifications', val);
                        },
                      ),
                      Divider(height: 1, color: dividerCol),
                      _buildSwitchRow(
                        icon: Icons.mail_outline,
                        title: AppLocalizations.translate(lang, 'email_notifications'),
                        subtitle: AppLocalizations.translate(lang, 'email_desc'),
                        value: _emailNotifications,
                        textCol: textCol,
                        onChanged: (val) {
                          setState(() => _emailNotifications = val);
                          _saveBoolSetting('email_notifications', val);
                        },
                      ),
                      Divider(height: 1, color: dividerCol),
                      _buildSwitchRow(
                        icon: Icons.chat_bubble_outline_outlined,
                        title: AppLocalizations.translate(lang, 'sms_notifications'),
                        subtitle: AppLocalizations.translate(lang, 'sms_desc'),
                        value: _smsNotifications,
                        textCol: textCol,
                        onChanged: (val) {
                          setState(() => _smsNotifications = val);
                          _saveBoolSetting('sms_notifications', val);
                        },
                      ),
                    ]),

                    const SizedBox(height: 24),

                    // Privacy Group
                    _buildSectionHeader(AppLocalizations.translate(lang, 'privacy'), textCol),
                    const SizedBox(height: 8),
                    _buildGroupCard(cardBg, dividerCol, [
                      _buildDropdownRow(
                        icon: Icons.visibility_outlined,
                        title: AppLocalizations.translate(lang, 'profile_visibility'),
                        subtitle: AppLocalizations.translate(lang, 'profile_desc'),
                        selectedValue: AppState().profileVisibility,
                        items: const ['Public', 'Private', 'Friends'],
                        textCol: textCol,
                        cardBg: cardBg,
                        dividerCol: dividerCol,
                        onChanged: (val) async {
                          if (val != null) {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setString('profile_visibility', val);
                            setState(() {}); // Rebuild local drop-down
                          }
                        },
                      ),
                      Divider(height: 1, color: dividerCol),
                      _buildSwitchRow(
                        icon: Icons.share_outlined,
                        title: AppLocalizations.translate(lang, 'data_sharing'),
                        subtitle: AppLocalizations.translate(lang, 'data_sharing_desc'),
                        value: _dataSharing,
                        textCol: textCol,
                        onChanged: (val) {
                          setState(() => _dataSharing = val);
                          _saveBoolSetting('data_sharing', val);
                        },
                      ),
                    ]),

                    const SizedBox(height: 24),

                    // Preferences Group
                    _buildSectionHeader(AppLocalizations.translate(lang, 'preferences'), textCol),
                    const SizedBox(height: 8),
                    _buildGroupCard(cardBg, dividerCol, [
                      _buildDropdownRow(
                        icon: Icons.language_outlined,
                        title: AppLocalizations.translate(lang, 'language'),
                        subtitle: AppLocalizations.translate(lang, 'language_desc'),
                        selectedValue: lang,
                        items: const ['English', 'Tamil', 'Hindi', 'Malayalam', 'Kannada'],
                        textCol: textCol,
                        cardBg: cardBg,
                        dividerCol: dividerCol,
                        onChanged: (val) {
                          if (val != null) {
                            AppState().setLanguage(val);
                          }
                        },
                      ),
                      Divider(height: 1, color: dividerCol),
                      _buildDropdownRow(
                        icon: Icons.palette_outlined,
                        title: AppLocalizations.translate(lang, 'theme'),
                        subtitle: AppLocalizations.translate(lang, 'theme_desc'),
                        selectedValue: theme,
                        items: const ['Light', 'Dark', 'System'],
                        textCol: textCol,
                        cardBg: cardBg,
                        dividerCol: dividerCol,
                        onChanged: (val) {
                          if (val != null) {
                            AppState().setTheme(val);
                          }
                        },
                      ),
                      Divider(height: 1, color: dividerCol),
                      _buildDropdownRow(
                        icon: Icons.straighten_outlined,
                        title: AppLocalizations.translate(lang, 'units'),
                        subtitle: AppLocalizations.translate(lang, 'units_desc'),
                        selectedValue: AppState().units,
                        items: const ['Metric', 'Imperial'],
                        textCol: textCol,
                        cardBg: cardBg,
                        dividerCol: dividerCol,
                        onChanged: (val) async {
                          if (val != null) {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setString('units', val);
                            setState(() {}); // Rebuild local dropdown
                          }
                        },
                      ),
                    ]),

                    const SizedBox(height: 24),

                    // AI Settings Group
                    _buildSectionHeader(AppLocalizations.translate(lang, 'gemini_settings'), textCol),
                    const SizedBox(height: 8),
                    ValueListenableBuilder<String>(
                      valueListenable: AppState().geminiApiKeyNotifier,
                      builder: (context, apiKey, child) {
                        final isConfigured = apiKey.trim().isNotEmpty;
                        final statusText = isConfigured
                            ? AppLocalizations.translate(lang, 'gemini_api_key_status_active')
                            : AppLocalizations.translate(lang, 'gemini_api_key_status_offline');
                        return _buildGroupCard(cardBg, dividerCol, [
                          _buildActionRow(
                            icon: Icons.psychology_alt_outlined,
                            title: '${AppLocalizations.translate(lang, 'gemini_api_key')} ($statusText)',
                            isRed: false,
                            textCol: textCol,
                            onTap: () => _showGeminiApiKeyDialog(lang),
                          ),
                        ]);
                      },
                    ),

                    const SizedBox(height: 24),

                    // Account Group
                    _buildSectionHeader(AppLocalizations.translate(lang, 'account'), textCol),
                    const SizedBox(height: 8),
                    _buildGroupCard(cardBg, dividerCol, [
                      _buildActionRow(
                        icon: Icons.password_outlined,
                        title: AppLocalizations.translate(lang, 'change_password'),
                        isRed: false,
                        textCol: textCol,
                        onTap: () => _showChangePasswordDialog(lang),
                      ),
                      Divider(height: 1, color: dividerCol),
                      _buildActionRow(
                        icon: Icons.download_outlined,
                        title: AppLocalizations.translate(lang, 'download_data'),
                        isRed: false,
                        textCol: textCol,
                        onTap: () => _showDownloadDataDialog(lang),
                      ),
                      Divider(height: 1, color: dividerCol),
                      _buildActionRow(
                        icon: Icons.delete_outline,
                        title: AppLocalizations.translate(lang, 'delete_account'),
                        isRed: true,
                        textCol: textCol,
                        onTap: () => _showDeleteAccountDialog(lang),
                      ),
                    ]),

                    const SizedBox(height: 24),

                    // Support Group
                    _buildSectionHeader(AppLocalizations.translate(lang, 'support'), textCol),
                    const SizedBox(height: 8),
                    _buildGroupCard(cardBg, dividerCol, [
                      _buildActionRow(
                        icon: Icons.help_outline_outlined,
                        title: AppLocalizations.translate(lang, 'help_center'),
                        isRed: false,
                        textCol: textCol,
                        onTap: () => _showSupportModal(
                          lang,
                          AppLocalizations.translate(lang, 'help_center'),
                          AppLocalizations.translate(lang, 'how_help'),
                        ),
                      ),
                      Divider(height: 1, color: dividerCol),
                      _buildActionRow(
                        icon: Icons.chat_bubble_outline,
                        title: AppLocalizations.translate(lang, 'contact_us'),
                        isRed: false,
                        textCol: textCol,
                        onTap: () => _showSupportModal(
                          lang,
                          AppLocalizations.translate(lang, 'contact_us'),
                          AppLocalizations.translate(lang, 'send_msg'),
                        ),
                      ),
                      Divider(height: 1, color: dividerCol),
                      _buildActionRow(
                        icon: Icons.info_outline,
                        title: AppLocalizations.translate(lang, 'about'),
                        isRed: false,
                        textCol: textCol,
                        onTap: () => _showAboutModal(lang),
                      ),
                    ]),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Helper getters for other settings stored on SharedPreferences but loaded instantly
  static String get _profileVisibilityHelper {
    try {
      // Stub getter for sync build read. In actual AppState we can fetch it, let's look:
      return AppState().themeNotifier.value; // placeholder, replaced by direct async getter
    } catch (_) {
      return 'Public';
    }
  }

  // Header UI for groups
  Widget _buildSectionHeader(String title, Color textCol) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: textCol,
        ),
      ),
    );
  }

  // Card container that groups settings options together
  Widget _buildGroupCard(Color cardBg, Color dividerCol, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: dividerCol.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }

  // Standard switch row (Push, Email, SMS, Data sharing)
  Widget _buildSwitchRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Color textCol,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF22C55E),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textCol,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: textCol.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch.adaptive(
            value: value,
            activeColor: Colors.white,
            activeTrackColor: const Color(0xFF22C55E),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: const Color(0xFFE5E7EB),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  // Row for options that have dropdown configurations underneath
  Widget _buildDropdownRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required String selectedValue,
    required List<String> items,
    required Color textCol,
    required Color cardBg,
    required Color dividerCol,
    required ValueChanged<String?> onChanged,
  }) {
    // Make sure selectedValue is in items. If not, default to first item
    final value = items.contains(selectedValue) ? selectedValue : items.first;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF22C55E),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textCol,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: textCol.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: dividerCol, width: 1.2),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                icon: Icon(Icons.keyboard_arrow_down, color: textCol.withOpacity(0.6)),
                style: TextStyle(
                  color: textCol,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                dropdownColor: cardBg,
                borderRadius: BorderRadius.circular(10),
                onChanged: onChanged,
                items: items.map<DropdownMenuItem<String>>((String val) {
                  return DropdownMenuItem<String>(
                    value: val,
                    child: Text(val),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Row for actions (Account / Support options)
  Widget _buildActionRow({
    required IconData icon,
    required String title,
    required bool isRed,
    required Color textCol,
    required VoidCallback onTap,
  }) {
    final containerColor = isRed ? const Color(0xFFFEE2E2) : const Color(0xFFFFEDD5);
    final iconColor = isRed ? const Color(0xFFEF4444) : const Color(0xFFF97316);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: containerColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: textCol,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: textCol.withOpacity(0.4),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // --- Modal Dialogs & Sheets (Localized & Styled) ---

  void _showGeminiApiKeyDialog(String lang) {
    final controller = TextEditingController(text: AppState().geminiApiKeyNotifier.value);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final textCol = Theme.of(context).colorScheme.onSurface;
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.psychology_alt, color: Color(0xFF22C55E)),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.translate(lang, 'gemini_api_key'),
                style: TextStyle(fontWeight: FontWeight.bold, color: textCol),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppLocalizations.translate(lang, 'gemini_api_key_desc'),
                style: TextStyle(color: textCol.withOpacity(0.7), fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                style: TextStyle(color: textCol, fontSize: 14),
                decoration: InputDecoration(
                  labelText: AppLocalizations.translate(lang, 'gemini_api_key'),
                  labelStyle: TextStyle(color: textCol.withOpacity(0.6)),
                  hintText: AppLocalizations.translate(lang, 'gemini_api_key_hint'),
                  hintStyle: TextStyle(color: textCol.withOpacity(0.4)),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).dividerColor)),
                  focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF22C55E))),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () => controller.clear(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final url = Uri.parse('https://ai.google.dev/');
                  try {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  } catch (_) {}
                },
                child: Text(
                  AppLocalizations.translate(lang, 'gemini_api_key_help'),
                  style: const TextStyle(
                    color: Color(0xFF3B82F6),
                    decoration: TextDecoration.underline,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppLocalizations.translate(lang, 'cancel'), style: const TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                final key = controller.text.trim();
                AppState().setGeminiApiKey(key);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.translate(lang, 'gemini_api_key_saved')),
                    backgroundColor: const Color(0xFF22C55E),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF22C55E),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                AppLocalizations.translate(lang, 'password_update'),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showLogoutDialog(String lang) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            AppLocalizations.translate(lang, 'logout'),
            style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
          ),
          content: Text(AppLocalizations.translate(lang, 'logout_confirm')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppLocalizations.translate(lang, 'cancel'), style: const TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await AppState().logout();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppLocalizations.translate(lang, 'logout_success')),
                      backgroundColor: Colors.black,
                    ),
                  );
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEA580C),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                AppLocalizations.translate(lang, 'logout'),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showChangePasswordDialog(String lang) {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        final textCol = Theme.of(context).colorScheme.onSurface;
        
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            AppLocalizations.translate(lang, 'change_password'),
            style: TextStyle(fontWeight: FontWeight.bold, color: textCol),
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: oldPasswordController,
                    obscureText: true,
                    style: TextStyle(color: textCol),
                    decoration: InputDecoration(
                      labelText: AppLocalizations.translate(lang, 'password_current'),
                      labelStyle: TextStyle(color: textCol.withOpacity(0.7)),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).dividerColor)),
                      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF22C55E))),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return AppLocalizations.translate(lang, 'password_error_empty');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: newPasswordController,
                    obscureText: true,
                    style: TextStyle(color: textCol),
                    decoration: InputDecoration(
                      labelText: AppLocalizations.translate(lang, 'password_new'),
                      labelStyle: TextStyle(color: textCol.withOpacity(0.7)),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).dividerColor)),
                      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF22C55E))),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (val) {
                      if (val == null || val.length < 6) {
                        return AppLocalizations.translate(lang, 'password_error_short');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: confirmPasswordController,
                    obscureText: true,
                    style: TextStyle(color: textCol),
                    decoration: InputDecoration(
                      labelText: AppLocalizations.translate(lang, 'password_confirm'),
                      labelStyle: TextStyle(color: textCol.withOpacity(0.7)),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).dividerColor)),
                      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF22C55E))),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (val) {
                      if (val != newPasswordController.text) {
                        return AppLocalizations.translate(lang, 'password_error_match');
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppLocalizations.translate(lang, 'cancel'), style: const TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppLocalizations.translate(lang, 'password_success')),
                      backgroundColor: const Color(0xFF22C55E),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF22C55E),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                AppLocalizations.translate(lang, 'password_update'),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDownloadDataDialog(String lang) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final textCol = Theme.of(context).colorScheme.onSurface;
        
        return StatefulBuilder(
          builder: (context, setDialogState) {
            double progress = 0.0;
            Future.delayed(const Duration(milliseconds: 300), () {
              if (progress < 1.0) {
                setDialogState(() {
                  progress += 0.2;
                  if (progress > 1.0) progress = 1.0;
                });
              }
            });

            return AlertDialog(
              backgroundColor: Theme.of(context).cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                AppLocalizations.translate(lang, 'downloading_data'),
                style: TextStyle(fontWeight: FontWeight.bold, color: textCol),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(AppLocalizations.translate(lang, 'downloading_desc')),
                  const SizedBox(height: 20),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Theme.of(context).dividerColor.withOpacity(0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF22C55E)),
                  ),
                  const SizedBox(height: 8),
                  Text('${(progress * 100).toInt()}% completed', style: TextStyle(fontWeight: FontWeight.bold, color: textCol)),
                ],
              ),
              actions: [
                if (progress >= 1.0)
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF22C55E),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(AppLocalizations.translate(lang, 'done'), style: const TextStyle(color: Colors.white)),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteAccountDialog(String lang) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            AppLocalizations.translate(lang, 'delete_account'),
            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFEF4444)),
          ),
          content: Text(AppLocalizations.translate(lang, 'delete_warning')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppLocalizations.translate(lang, 'cancel'), style: const TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                await AppState().logout();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppLocalizations.translate(lang, 'delete_success')),
                      backgroundColor: const Color(0xFFEF4444),
                    ),
                  );
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                AppLocalizations.translate(lang, 'delete_permanently'),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSupportModal(String lang, String title, String prompt) {
    final textController = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        final textCol = Theme.of(context).colorScheme.onSurface;
        
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textCol),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: textCol),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(prompt, style: TextStyle(color: textCol.withOpacity(0.6))),
              const SizedBox(height: 16),
              TextField(
                controller: textController,
                maxLines: 4,
                style: TextStyle(color: textCol),
                decoration: InputDecoration(
                  hintText: AppLocalizations.translate(lang, 'enter_details'),
                  hintStyle: TextStyle(color: textCol.withOpacity(0.4)),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).dividerColor)),
                  focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF22C55E))),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppLocalizations.translate(lang, 'submit_success')),
                      backgroundColor: const Color(0xFF22C55E),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22C55E),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  AppLocalizations.translate(lang, 'submit'),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAboutModal(String lang) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        final textCol = Theme.of(context).colorScheme.onSurface;
        
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.eco,
                  color: Color(0xFF22C55E),
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'AgriGrow App',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textCol),
              ),
              const SizedBox(height: 4),
              Text(
                AppLocalizations.translate(lang, 'version_build'),
                style: TextStyle(color: textCol.withOpacity(0.5), fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 20),
              Divider(color: Theme.of(context).dividerColor),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.translate(lang, 'app_desc'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: textCol.withOpacity(0.8), height: 1.5),
              ),
              const SizedBox(height: 24),
              Text(
                AppLocalizations.translate(lang, 'copyright'),
                style: TextStyle(fontSize: 12, color: textCol.withOpacity(0.4)),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}


