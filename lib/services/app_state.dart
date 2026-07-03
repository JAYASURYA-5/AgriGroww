import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppState {
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;
  AppState._internal();

  final themeNotifier = ValueNotifier<String>('Light');
  final languageNotifier = ValueNotifier<String>('English');
  final geminiApiKeyNotifier = ValueNotifier<String>('');

  // Session variables
  String? currentUserId;
  Map<String, dynamic>? currentUser;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      themeNotifier.value = prefs.getString('theme') ?? 'Light';
      languageNotifier.value = prefs.getString('language') ?? 'English';
      final savedKey = prefs.getString('gemini_api_key');
      if (savedKey == null || savedKey.trim().isEmpty) {
        geminiApiKeyNotifier.value = '';
      } else {
        geminiApiKeyNotifier.value = savedKey;
      }
      
      // Load active session if saved
      currentUserId = prefs.getString('logged_in_user_id');
      if (currentUserId != null) {
        final usersJson = prefs.getString('registered_users');
        if (usersJson != null) {
          final Map<String, dynamic> users = jsonDecode(usersJson);
          if (users.containsKey(currentUserId)) {
            currentUser = Map<String, dynamic>.from(users[currentUserId]);
          } else {
            // ID invalid, reset session
            currentUserId = null;
          }
        } else {
          currentUserId = null;
        }
      }
    } catch (e) {
      debugPrint('Error initializing app state: $e');
    }
  }

  // Authenticate user
  Future<bool> login(String identifier, String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString('registered_users');
      if (usersJson == null) return false;

      final Map<String, dynamic> users = jsonDecode(usersJson);
      
      // Look for user by email or mobile
      String? foundId;
      Map<String, dynamic>? foundUser;

      for (var entry in users.entries) {
        final user = entry.value as Map<String, dynamic>;
        final email = user['email']?.toString().toLowerCase();
        final mobile = user['mobile']?.toString();
        final pass = user['password']?.toString();

        if ((email == identifier.toLowerCase() || mobile == identifier) && pass == password) {
          foundId = entry.key;
          foundUser = user;
          break;
        }
      }

      if (foundId != null && foundUser != null) {
        currentUserId = foundId;
        currentUser = foundUser;
        await prefs.setString('logged_in_user_id', foundId);
        return true;
      }
    } catch (e) {
      debugPrint('Error during login: $e');
    }
    return false;
  }

  // Register user
  Future<bool> registerUser(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString('registered_users') ?? '{}';
      final Map<String, dynamic> users = jsonDecode(usersJson);

      final email = userData['email']?.toString().toLowerCase();
      final mobile = userData['mobile']?.toString();

      // Check if user already exists
      for (var user in users.values) {
        final existingEmail = user['email']?.toString().toLowerCase();
        final existingMobile = user['mobile']?.toString();

        if (existingEmail == email || existingMobile == mobile) {
          return false; // User already registered
        }
      }

      // Use mobile number or email as key
      final id = mobile ?? email ?? DateTime.now().millisecondsSinceEpoch.toString();
      users[id] = userData;
      
      await prefs.setString('registered_users', jsonEncode(users));
      
      // Automatically log user in after registration
      currentUserId = id;
      currentUser = userData;
      await prefs.setString('logged_in_user_id', id);
      return true;
    } catch (e) {
      debugPrint('Error during registration: $e');
    }
    return false;
  }

  // Logout session
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      currentUserId = null;
      currentUser = null;
      await prefs.remove('logged_in_user_id');
    } catch (e) {
      debugPrint('Error during logout: $e');
    }
  }

  // Update current user profile details
  Future<void> updateCurrentUser(Map<String, dynamic> updatedData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString('registered_users');
      if (usersJson != null) {
        final Map<String, dynamic> users = jsonDecode(usersJson);
        if (currentUserId != null && users.containsKey(currentUserId)) {
          final existingUser = Map<String, dynamic>.from(users[currentUserId]);
          existingUser.addAll(updatedData);
          users[currentUserId!] = existingUser;
          currentUser = existingUser;
          await prefs.setString('registered_users', jsonEncode(users));
        }
      }
    } catch (e) {
      debugPrint('Error updating user profile: $e');
    }
  }

  void setTheme(String theme) {
    themeNotifier.value = theme;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('theme', theme);
    }).catchError((e) {
      debugPrint('Error saving theme: $e');
    });
  }

  void setLanguage(String lang) {
    languageNotifier.value = lang;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('language', lang);
    }).catchError((e) {
      debugPrint('Error saving language: $e');
    });
  }

  void setGeminiApiKey(String key) {
    geminiApiKeyNotifier.value = key;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('gemini_api_key', key);
    }).catchError((e) {
      debugPrint('Error saving gemini api key: $e');
    });
  }
}

class AppLocalizations {
  static final Map<String, Map<String, String>> _localizedValues = {
    'English': {
      'settings': 'Settings',
      'logout': 'Logout',
      'notifications': 'Notifications',
      'push_notifications': 'Push Notifications',
      'push_desc': 'Receive alerts on your device',
      'email_notifications': 'Email Notifications',
      'email_desc': 'Get updates via email',
      'sms_notifications': 'SMS Notifications',
      'sms_desc': 'Receive text messages',
      'privacy': 'Privacy',
      'profile_visibility': 'Profile Visibility',
      'profile_desc': 'Control who can see your profile',
      'data_sharing': 'Data Sharing',
      'data_sharing_desc': 'Allow anonymous data sharing for improvements',
      'preferences': 'Preferences',
      'language': 'Language',
      'language_desc': 'Choose your preferred language',
      'theme': 'Theme',
      'theme_desc': 'Choose your app theme',
      'units': 'Units',
      'units_desc': 'Measurement units',
      'account': 'Account',
      'change_password': 'Change Password',
      'download_data': 'Download Data',
      'delete_account': 'Delete Account',
      'support': 'Support',
      'help_center': 'Help Center',
      'contact_us': 'Contact Us',
      'about': 'About',
      'good_morning': 'Good Morning, \n',
      'live_data': 'Live Data',
      'soil_moisture': 'Soil Moisture',
      'temperature': 'Temperature',
      'humidity': 'Humidity',
      'soil_ph': 'Soil pH',
      'optimal': 'Optimal',
      'intercrop_suggestion': 'Intercrop Suggestion',
      'view_report': 'View Report',
      'quick_actions': 'Quick Actions',
      'lms': 'LMS',
      'disease_detection': 'Disease\nDetection',
      'notes': 'Notes',
      'news': 'News',
      'scheme': 'Scheme',
      'market_prices': 'Market\nPrices',
      'finance': 'Finance',
      'crop_calendar': 'Crop\nCalendar',
      'livestock': 'Livestock',
      'agrihub': 'AgriHub',
      'current_weather': 'Current Weather',
      'overcast': 'Overcast',
      'no_rain': 'No rain expected',
      'wind_speed': 'Wind Speed',
      'humidity_title': 'Humidity',
      'view_detailed_forecast': 'View Detailed Forecast',
      'intercrop_update': 'Latest update on intercrop\nsuggestions',
      'intercrop_update_desc': 'Check intercrop suggestions for\npest control.',
      'view_suggestions': 'View Suggestions',
      'soil_moisture_title': 'Soil Moisture',
      'temp_title': 'Temperature',
      'humidity_data': 'Humidity',
      'soil_ph_title': 'Soil pH',
      'cancel': 'Cancel',
      'logout_confirm': 'Are you sure you want to log out of AgriGrow?',
      'logout_success': 'Successfully logged out!',
      'password_current': 'Current Password',
      'password_new': 'New Password',
      'password_confirm': 'Confirm New Password',
      'password_update': 'Update',
      'password_success': 'Password updated successfully!',
      'password_error_empty': 'Please enter current password',
      'password_error_short': 'Password must be at least 6 characters',
      'password_error_match': 'Passwords do not match',
      'downloading_data': 'Downloading Data',
      'downloading_desc': 'Preparing your profile, livestock history and weather records for export...',
      'done': 'Done',
      'delete_warning': 'Warning: This action is permanent. All your data, farm history, scan results, and preferences will be permanently deleted.',
      'delete_permanently': 'Delete Permanently',
      'delete_success': 'Account successfully deleted.',
      'how_help': 'How can we help you today?',
      'send_msg': 'Send us a message and we will get back to you!',
      'enter_details': 'Enter details here...',
      'submit': 'Submit',
      'submit_success': 'Thank you! Your submission has been received.',
      'app_desc': 'AgriGrow empowers modern farmers with real-time weather analytics, crop health recommendations, disease diagnosis tools, and market index predictions to improve crop yields and promote sustainable agriculture.',
      'copyright': '© 2026 AgriGrow Inc. All rights reserved.',
      'version_build': 'Version 1.0.0 (Build 1)',
      'community': 'Community',
      'market': 'Market',
      'gemini_settings': 'AI Assistant Settings',
      'gemini_api_key': 'Gemini API Key',
      'gemini_api_key_desc': 'Configure Google Gemini API Key for dynamic analysis',
      'gemini_api_key_hint': 'Enter API Key (AIzaSy...)',
      'gemini_api_key_saved': 'Gemini API Key updated successfully!',
      'gemini_api_key_status_active': 'Configured (Active)',
      'gemini_api_key_status_offline': 'Not Configured (Offline Demo)',
      'gemini_api_key_help': 'Get a free Gemini API Key from Google AI Studio',
      'fertilizer_cat': 'AI ASSISTANT',
      'fertilizer_title': 'AgriBot',
      'fertilizer_desc': 'Ask AgriBot anything about crop health, fertilizer recommendations, and smart farming.',
      'fertilizer_action': 'CHAT WITH AGRIBOT',
      'market_alert_cat': 'MARKET INDEX',
      'market_alert_title': 'Market Prices',
      'market_alert_desc': 'Get real-time commodity prices, market trends, and daily price updates for your local mandi.',
      'market_alert_action': 'VIEW MARKET PRICES',
      'intercrop_cat': 'CROP ADVISORY',
      'intercrop_title': 'Intercrop Advisor',
      'intercrop_desc': 'Get smart recommendations on intercropping patterns to maximize your land use and profits.',
      'intercrop_action': 'GET RECOMMENDATIONS',
      'pest_alert_cat': 'PEST & DISEASE',
      'pest_alert_title': 'Crop Disease',
      'pest_alert_desc': 'Scan your crop to detect diseases early, diagnose pest issues, and receive instant organic treatment recommendations.',
      'pest_alert_action': 'SCAN CROPS',
    },
    'Tamil': {
      'settings': 'அமைப்புகள்',
      'logout': 'வெளியேறு',
      'notifications': 'அறிவிப்புகள்',
      'push_notifications': 'புஷ் அறிவிப்புகள்',
      'push_desc': 'உங்கள் சாதனத்தில் விழிப்பூட்டல்களைப் பெறவும்',
      'email_notifications': 'மின்னஞ்சல் அறிவிப்புகள்',
      'email_desc': 'மின்னஞ்சல் மூலம் அறிவிப்புகளைப் பெறுக',
      'sms_notifications': 'எஸ்எம்எஸ் அறிவிப்புகள்',
      'sms_desc': 'உரைச் செய்திகளைப் பெறுக',
      'privacy': 'தனியுரிமை',
      'profile_visibility': 'சுயவிவர தெரிவுநிலை',
      'profile_desc': 'உங்கள் சுயவிவரத்தை யார் பார்க்க முடியும் என்பதைக் கட்டுப்படுத்தவும்',
      'data_sharing': 'தரவு பகிர்வு',
      'data_sharing_desc': 'அநாமதேய தரவு பகிர்வை அனுமதிக்கவும்',
      'preferences': 'விருப்பத்தேர்வுகள்',
      'language': 'மொழி',
      'language_desc': 'விருப்பமான மொழியைத் தேர்ந்தெடுக்கவும்',
      'theme': 'தீம் (வடிவமைப்பு)',
      'theme_desc': 'பயன்பாட்டு தீம் தேர்ந்தெடுக்கவும்',
      'units': 'அலகுகள்',
      'units_desc': 'அளவீட்டு அலகுகள்',
      'account': 'கணக்கு',
      'change_password': 'கடவுச்சொல் மாற்று',
      'download_data': 'தரவை பதிவிறக்கு',
      'delete_account': 'கணக்கை நீக்கு',
      'support': 'ஆதரவு',
      'help_center': 'உதவி மையம்',
      'contact_us': 'எங்களைத் தொடர்பு கொள்ள',
      'about': 'பற்றி',
      'good_morning': 'காலை வணக்கம், \n',
      'live_data': 'நேரடி தரவு',
      'soil_moisture': 'மண் ஈரப்பதம்',
      'temperature': 'வெப்பநிலை',
      'humidity': 'ஈரப்பதம்',
      'soil_ph': 'மண் pH',
      'optimal': 'சரியானது',
      'intercrop_suggestion': 'ஊடுபயிர் பரிந்துரை',
      'view_report': 'அறிக்கை காண்க',
      'quick_actions': 'விரைவான செயல்கள்',
      'lms': 'எல்எம்எஸ்',
      'disease_detection': 'நோய்\nகண்டறிதல்',
      'notes': 'குறிப்புகள்',
      'news': 'செய்திகள்',
      'scheme': 'திட்டம்',
      'market_prices': 'சந்தை\nவிலைகள்',
      'finance': 'நிதி',
      'crop_calendar': 'பயிர்\nகாலண்டர்',
      'livestock': 'கால்நடைகள்',
      'agrihub': 'அக்ரிஹப்',
      'current_weather': 'தற்போதைய வானிலை',
      'overcast': 'மேகமூட்டம்',
      'no_rain': 'மழை எதிர்பார்க்கப்படவில்லை',
      'wind_speed': 'காற்றின் வேகம்',
      'humidity_title': 'ஈரப்பதம்',
      'view_detailed_forecast': 'விரிவான முன்னறிவிப்பைக் காண்க',
      'intercrop_update': 'ஊடுபயிர் பரிந்துரைகளின்\nசமீபத்திய புதுப்பிப்பு',
      'intercrop_update_desc': 'பூச்சி கட்டுப்பாட்டுக்கான ஊடுபயிர்\nபரிந்துரைகளைச் சரிபார்க்கவும்.',
      'view_suggestions': 'பரிந்துரைகளைக் காண்க',
      'soil_moisture_title': 'மண் ஈரப்பதம்',
      'temp_title': 'வெப்பநிலை',
      'humidity_data': 'ஈரப்பதம்',
      'soil_ph_title': 'மண் pH',
      'cancel': 'இரத்து செய்',
      'logout_confirm': 'அக்ரிகுரோவில் இருந்து வெளியேற விரும்புகிறீர்களா?',
      'logout_success': 'வெற்றிகரமாக வெளியேறியது!',
      'password_current': 'தற்போதைய கடவுச்சொல்',
      'password_new': 'புதிய கடவுச்சொல்',
      'password_confirm': 'புதிய கடவுச்சொல்லை உறுதிப்படுத்துக',
      'password_update': 'புதுப்பி',
      'password_success': 'கடவுச்சொல் வெற்றிகரமாக புதுப்பிக்கப்பட்டது!',
      'password_error_empty': 'தற்போதைய கடவுச்சொல்லை உள்ளிடவும்',
      'password_error_short': 'கடவுச்சொல் குறைந்தபட்சம் 6 எழுத்துகள் இருக்க வேண்டும்',
      'password_error_match': 'கடவுச்சொற்கள் பொருந்தவில்லை',
      'downloading_data': 'தரவு பதிவிறக்கம் செய்யப்படுகிறது',
      'downloading_desc': 'சுயவிவரம், கால்நடை வரலாறு மற்றும் வானிலை பதிவுகளை ஏற்றுமதி செய்ய தயார் செய்கிறது...',
      'done': 'முடிந்தது',
      'delete_warning': 'எச்சரிக்கை: இந்த நடவடிக்கை நிரந்தரமானது. உங்களது அனைத்து தரவு, பண்ணை வரலாறு, ஸ்கேன் முடிவுகள் மற்றும் விருப்பத்தேர்வுகள் நிரந்தரமாக நீக்கப்படும்.',
      'delete_permanently': 'நிரந்தரமாக நீக்கு',
      'delete_success': 'கணக்கு வெற்றிகரமாக நீக்கப்பட்டது.',
      'how_help': 'இன்று உங்களுக்கு நாம் எவ்வாறு உதவ முடியும்?',
      'send_msg': 'எங்களுக்கு ஒரு செய்தியை அனுப்புங்கள், நாங்கள் உங்களை தொடர்பு கொள்கிறோம்!',
      'enter_details': 'விவரங்களை இங்கே உள்ளிடவும்...',
      'submit': 'சமர்ப்பி',
      'submit_success': 'நன்றி! உங்கள் சமர்ப்பிப்பு பெறப்பட்டது.',
      'app_desc': 'அக்ரிகுரோ நவீன விவசாயிகளுக்கு நிகழ்நேர வானிலை பகுப்பாய்வு, பயிர் சுகாதார பரிந்துரைகள், நோய் கண்டறியும் கருவிகள் மற்றும் சந்தை விலை முன்னறிவிப்புகளை வழங்கி நிலையான விவசாயத்தை ஊக்குவிக்கிறது.',
      'copyright': '© 2026 அக்ரிகுரோ இன்க். அனைத்து உரிமைகளும் பாதுகாக்கப்பட்டவை.',
      'version_build': 'பதிப்பு 1.0.0 (பில்ட் 1)',
      'community': 'சமூகம்',
      'market': 'சந்தை',
      'gemini_settings': 'AI உதவியாளர் அமைப்புகள்',
      'gemini_api_key': 'ஜெமினி API கீ',
      'gemini_api_key_desc': 'நேரடி பகுப்பாய்விற்கு ஜெமினி API கீயை உள்ளமைக்கவும்',
      'gemini_api_key_hint': 'API கீயை உள்ளிடவும் (AIzaSy...)',
      'gemini_api_key_saved': 'ஜெமினி API கீ வெற்றிகரமாக புதுப்பிக்கப்பட்டது!',
      'gemini_api_key_status_active': 'உள்ளமைக்கப்பட்டது (செயலில் உள்ளது)',
      'gemini_api_key_status_offline': 'உள்ளமைக்கப்படவில்லை (ஆஃப்லைன் டெமோ)',
      'gemini_api_key_help': 'கூகுள் AI ஸ்டுடியோவில் இருந்து இலவச ஜெமினி API கீயை பெறவும்',
      'fertilizer_cat': 'AI உதவியாளர்',
      'fertilizer_title': 'அக்ரிபாட்',
      'fertilizer_desc': 'உரப் பரிந்துரைகள் மற்றும் பயிர் ஆரோக்கியம் பற்றி அக்ரிபாட்டிடம் கேளுங்கள்.',
      'fertilizer_action': 'அக்ரிபாட்டுடன் அரட்டையடிக்கவும்',
      'market_alert_cat': 'சந்தை குறியீடு',
      'market_alert_title': 'சந்தை விலைகள்',
      'market_alert_desc': 'உள்ளூர் மண்டிகளுக்கான நிகழ்நேர விலை நிலவரங்கள் மற்றும் தினசரி சந்தை போக்குகளைக் கண்டறியவும்.',
      'market_alert_action': 'சந்தை விலைகளைக் காண்க',
      'intercrop_cat': 'பயிர் ஆலோசனைகள்',
      'intercrop_title': 'ஊடுபயிர் ஆலோசகர்',
      'intercrop_desc': 'உங்கள் நில பயன்பாடு மற்றும் லாபத்தை அதிகரிக்க ஊடுபயிர் முறைகள் குறித்த புத்திசாலித்தனமான பரிந்துரைகளைப் பெறுங்கள்.',
      'intercrop_action': 'பரிந்துரைகளைப் பெறுக',
      'pest_alert_cat': 'பூச்சி & நோய்',
      'pest_alert_title': 'பயிர் நோய்',
      'pest_alert_desc': 'நோய்களை ஆரம்பத்திலேயே கண்டறிய உங்கள் பயிரை ஸ்கேன் செய்யவும், பூச்சிப் பிரச்சினைகளைக் கண்டறிந்து, உடனடி சிகிச்சை பரிந்துரைகளைப் பெறவும்.',
      'pest_alert_action': 'பயிர்களை ஸ்கேன் செய்',
    },
    'Hindi': {
      'settings': 'सेटिंग्स',
      'logout': 'लॉगआउट',
      'notifications': 'सूचनाएं',
      'push_notifications': 'पुश सूचनाएं',
      'push_desc': 'अपने डिवाइस पर अलर्ट प्राप्त करें',
      'email_notifications': 'ईमेल सूचनाएं',
      'email_desc': 'ईमेल के माध्यम से अपडेट प्राप्त करें',
      'sms_notifications': 'एसएमएस सूचनाएं',
      'sms_desc': 'टेक्स्ट संदेश प्राप्त करें',
      'privacy': 'गोपनीयता',
      'profile_visibility': 'प्रोफ़ाइल दृश्यता',
      'profile_desc': 'नियंत्रित करें कि आपकी प्रोफ़ाइल कौन देख सकता है',
      'data_sharing': 'डेटा साझाकरण',
      'data_sharing_desc': 'सुधारों के लिए अनाम डेटा साझाकरण की अनुमति दें',
      'preferences': 'प्राथमिकताएं',
      'language': 'भाषा',
      'language_desc': 'अपनी पसंदीदा भाषा चुनें',
      'theme': 'थीम',
      'theme_desc': 'अपना ऐप थीम चुनें',
      'units': 'इकाइयां',
      'units_desc': 'माप इकाइयां',
      'account': 'खाता',
      'change_password': 'पासवर्ड बदलें',
      'download_data': 'डेटा डाउनलोड करें',
      'delete_account': 'खाता हटाएं',
      'support': 'सहायता',
      'help_center': 'सहायता केंद्र',
      'contact_us': 'संपर्क करें',
      'about': 'ऐप के बारे में',
      'good_morning': 'शुभ प्रभात, \n',
      'live_data': 'लाइव डेटा',
      'soil_moisture': 'मिट्टी की नमी',
      'temperature': 'तापमान',
      'humidity': 'नमी',
      'soil_ph': 'मिट्टी का पीएच',
      'optimal': 'इष्टतम',
      'intercrop_suggestion': 'अंतर-फसल सुझाव',
      'view_report': 'रिपोर्ट देखें',
      'quick_actions': 'त्वरित कार्य',
      'lms': 'एलएमएस',
      'disease_detection': 'रोग का\nपता लगाना',
      'notes': 'नोट्स',
      'news': 'समाचार',
      'scheme': 'योजना',
      'market_prices': 'बाजार\nमूल्य',
      'finance': 'वित्त',
      'crop_calendar': 'फसल\nकैलेंडर',
      'livestock': 'पशुधन',
      'agrihub': 'एग्रीहब',
      'current_weather': 'वर्तमान मौसम',
      'overcast': 'बादल छाए रहना',
      'no_rain': 'बारिश की कोई उम्मीद नहीं',
      'wind_speed': 'हवा की गति',
      'humidity_title': 'नमी',
      'view_detailed_forecast': 'विस्तृत पूर्वानुमान देखें',
      'intercrop_update': 'अंतर-फसल सुझावों पर\nनवीनतम अपडेट',
      'intercrop_update_desc': 'कीट नियंत्रण के लिए अंतर-फसल सुझावों की जाँच करें।',
      'view_suggestions': 'सुझाव देखें',
      'soil_moisture_title': 'मिट्टी की नमी',
      'temp_title': 'तापमान',
      'humidity_data': 'नमी',
      'soil_ph_title': 'मिट्टी का पीएच',
      'cancel': 'रद्द करें',
      'logout_confirm': 'क्या आप वाकई एग्रीग्रो से लॉग आउट करना चाहते हैं?',
      'logout_success': 'सफलतापूर्वक लॉग आउट हो गया!',
      'password_current': 'वर्तमान पासवर्ड',
      'password_new': 'नया पासवर्ड',
      'password_confirm': 'नए पासवर्ड की पुष्टि करें',
      'password_update': 'अद्यतन करें',
      'password_success': 'पासवर्ड सफलतापूर्वक अपडेट हो गया!',
      'password_error_empty': 'कृपया वर्तमान पासवर्ड दर्ज करें',
      'password_error_short': 'पासवर्ड कम से कम 6 अक्षरों का होना चाहिए',
      'password_error_match': 'पासवर्ड मेल नहीं खाते',
      'downloading_data': 'डेटा डाउनलोड हो रहा है',
      'downloading_desc': 'निर्यात के लिए आपकी प्रोफ़ाइल, पशुधन इतिहास और मौसम रिकॉर्ड तैयार किए जा रहे हैं...',
      'done': 'पूर्ण',
      'delete_warning': 'चेतावनी: यह क्रिया स्थायी है। आपका सारा डेटा, कृषि इतिहास, स्कैन परिणाम और प्राथमिकताएं स्थायी रूप से हटा दी जाएंगी।',
      'delete_permanently': 'स्थायी रूप से हटाएं',
      'delete_success': 'खाता सफलतापूर्वक हटा दिया गया।',
      'how_help': 'आज हम आपकी क्या सहायता कर सकते हैं?',
      'send_msg': 'हमें एक संदेश भेजें और हम आपसे संपर्क करेंगे!',
      'enter_details': 'यहाँ विवरण दर्ज करें...',
      'submit': 'जमा करें',
      'submit_success': 'धन्यवाद! आपकी प्रविष्टि प्राप्त हो गई है।',
      'app_desc': 'एग्रीग्रो आधुनिक किसानों को वास्तविक समय मौसम विश्लेषण, फसल स्वास्थ्य सिफारिशें, रोग निदान उपकरण और बाजार मूल्य पूर्वानुमान प्रदान करता है जिससे फसल की पैदावार में सुधार हो सके।',
      'copyright': '© 2026 एग्रीग्रो इंक. सर्वाधिकार सुरक्षित।',
      'version_build': 'संस्करण 1.0.0 (बिल्ड 1)',
      'community': 'समुदाय',
      'market': 'बाज़ार',
      'gemini_settings': 'एआई सहायक सेटिंग्स',
      'gemini_api_key': 'जेमिनी एपीआई की',
      'gemini_api_key_desc': 'सक्रिय विश्लेषण के लिए जेमिनी एपीआई की कॉन्फ़िगर करें',
      'gemini_api_key_hint': 'एपीआई की दर्ज करें (AIzaSy...)',
      'gemini_api_key_saved': 'जेमिनी एपीआई की सफलतापूर्वक अपडेट हो गई!',
      'gemini_api_key_status_active': 'कॉन्फ़िगर किया गया (सक्रिय)',
      'gemini_api_key_status_offline': 'कॉन्फ़िगर नहीं किया गया (ऑफ़लाइन डेमो)',
      'gemini_api_key_help': 'Google AI Studio से निःशुल्क जेमिनी एपीआई की प्राप्त करें',
      'fertilizer_cat': 'एआई सहायक',
      'fertilizer_title': 'एग्रीबॉट',
      'fertilizer_desc': 'उर्वरक सिफारिशों और फसल स्वास्थ्य के बारे में एग्रीबॉट से पूछें।',
      'fertilizer_action': 'एग्रीबॉट के साथ चैट करें',
      'market_alert_cat': 'बाजार सूचकांक',
      'market_alert_title': 'बाजार मूल्य',
      'market_alert_desc': 'अपनी स्थानीय मंडियों के लिए वास्तविक समय की वस्तुओं की कीमतें और दैनिक बाजार रुझान प्राप्त करें।',
      'market_alert_action': 'बाजार मूल्य देखें',
      'intercrop_cat': 'फसल परामर्श',
      'intercrop_title': 'अंतर-फसल सलाहकार',
      'intercrop_desc': 'भूमि के उपयोग और लाभ को अधिकतम करने के लिए अंतर-फसल पैटर्न पर स्मार्ट सिफारिशें प्राप्त करें।',
      'intercrop_action': 'सिफारिशें प्राप्त करें',
      'pest_alert_cat': 'कीट और रोग',
      'pest_alert_title': 'फसल रोग',
      'pest_alert_desc': 'बीमारियों का जल्दी पता लगाने के लिए अपनी फसल को स्कैन करें, कीट समस्याओं का निदान करें, और त्वरित उपचार सिफारिशें प्राप्त करें।',
      'pest_alert_action': 'फसलों को स्कैन करें',
    },
    'Malayalam': {
      'settings': 'ക്രമീകരണങ്ങൾ',
      'logout': 'ലോഗ് ഔട്ട്',
      'notifications': 'അറിയിപ്പുകൾ',
      'push_notifications': 'പുഷ് അറിയിപ്പുകൾ',
      'push_desc': 'നിങ്ങളുടെ ഉപകരണത്തിൽ അറിയിപ്പുകൾ നേടുക',
      'email_notifications': 'ഇമെയിൽ അറിയിപ്പുകൾ',
      'email_desc': 'ഇമെയിൽ വഴി അപ്‌ഡേറ്റുകൾ നേടുക',
      'sms_notifications': 'എസ്എംഎസ് അറിയിപ്പുകൾ',
      'sms_desc': 'ടെക്സ്റ്റ് സന്ദേശങ്ങൾ സ്വീകരിക്കുക',
      'privacy': 'സ്വകാര്യത',
      'profile_visibility': 'പ്രൊഫൈൽ ദൃശ്യപരത',
      'profile_desc': 'ആർക്കൊക്കെ പ്രൊഫൈൽ കാണാമെന്ന് നിയന്ത്രിക്കുക',
      'data_sharing': 'ഡാറ്റ പങ്കിടൽ',
      'data_sharing_desc': 'മെച്ചപ്പെടുത്തലുകൾക്കായി അജ്ഞാത ഡാറ്റ പങ്കിടൽ അനുവദിക്കുക',
      'preferences': 'മുൻഗണനകൾ',
      'language': 'ഭാഷ',
      'language_desc': 'നിങ്ങൾ തിരഞ്ഞെടുക്കുന്ന ভাষা',
      'theme': 'തീം',
      'theme_desc': 'ആപ്പ് തീം തിരഞ്ഞെടുക്കുക',
      'units': 'യൂണിറ്റുകൾ',
      'units_desc': 'അളവുകൾ',
      'account': 'അക്കൗണ്ട്',
      'change_password': 'പാസ്‌വേഡ് മാറ്റുക',
      'download_data': 'ഡാറ്റ ഡൗൺലോഡ് ചെയ്യുക',
      'delete_account': 'അക്കൗണ്ട് ഇല്ലാതാക്കുക',
      'support': 'പിന്തുണ',
      'help_center': 'സഹായ കേന്ദ്രം',
      'contact_us': 'ഞങ്ങളുമായി ബന്ധപ്പെടുക',
      'about': 'വിവരങ്ങൾ',
      'good_morning': 'സുപ്രഭാതം, \n',
      'live_data': 'തത്സമയ വിവരങ്ങൾ',
      'soil_moisture': 'മണ്ണിലെ ഈർപ്പം',
      'temperature': 'താപനില',
      'humidity': 'അന്തരീക്ഷ ഈർപ്പം',
      'soil_ph': 'മണ്ണ് പിഎച്ച്',
      'optimal': 'അനുയോജ്യം',
      'intercrop_suggestion': 'ഇടവിള നിർദ്ദേശം',
      'view_report': 'റിപ്പോർട്ട് കാണുക',
      'quick_actions': 'പെട്ടെന്നുള്ള പ്രവർത്തനങ്ങൾ',
      'lms': 'എൽഎംഎസ്',
      'disease_detection': 'രോഗ\nനിർണ്ണയം',
      'notes': 'കുറിപ്പുകൾ',
      'news': 'വാർത്തകൾ',
      'scheme': 'പദ്ധതികൾ',
      'market_prices': 'വിപണി\nവിലകൾ',
      'finance': 'ധനകാര്യം',
      'crop_calendar': 'വിള\nകലണ്ടർ',
      'livestock': 'മൃഗസംരക്ഷണം',
      'agrihub': 'അഗ്രിഹബ്',
      'current_weather': 'നിലവിലെ കാലാവസ്ഥ',
      'overcast': 'മേഘാവൃതം',
      'no_rain': 'മഴ പ്രതീക്ഷിക്കുന്നില്ല',
      'wind_speed': 'കാറ്റിന്റെ വേഗത',
      'humidity_title': 'അന്തരീക്ഷ ഈർപ്പം',
      'view_detailed_forecast': 'വിശദമായ കാലാവസ്ഥാ വിവരങ്ങൾ',
      'intercrop_update': 'ഇടവിള ശുപാർശകളിൽ\nപുതിയ വിവരങ്ങൾ',
      'intercrop_update_desc': 'കീടനിയന്ത്രണത്തിനായുള്ള ഇടവിള ശുപാർശകൾ പരിശോധിക്കുക.',
      'view_suggestions': 'ശുപാർശകൾ കാണുക',
      'soil_moisture_title': 'മണ്ണിലെ ഈർപ്പം',
      'temp_title': 'താപനില',
      'humidity_data': 'അന്തരീക്ഷ ഈർപ്പം',
      'soil_ph_title': 'മണ്ണ് പിഎച്ച്',
      'cancel': 'റദ്ദാക്കുക',
      'logout_confirm': 'നിങ്ങൾ അഗ്രിഗ്രോയിൽ നിന്ന് ലോഗ് ഔട്ട് ചെയ്യാൻ ആഗ്രഹിക്കുന്നുവോ?',
      'logout_success': 'വിജയകരമായി ലോഗ് ഔട്ട് ചെയ്തു!',
      'password_current': 'നിലവിലെ പാസ്‌വേഡ്',
      'password_new': 'പുതിയ പാസ്‌വേഡ്',
      'password_confirm': 'പുതിയ പാസ്‌വേഡ് ഉറപ്പാക്കുക',
      'password_update': 'അപ്ഡേറ്റ്',
      'password_success': 'പാസ്‌വേഡ് വിജയകരമായി അപ്‌ഡേറ്റ് ചെയ്തു!',
      'password_error_empty': 'നിലവിലെ പാസ്‌വേഡ് നൽകുക',
      'password_error_short': 'പാസ്‌വേഡിന് കുറഞ്ഞത് 6 അക്ഷരങ്ങൾ ഉണ്ടായിരിക്കണം',
      'password_error_match': 'പാസ്‌വേഡുകൾ പൊരുത്തപ്പെടുന്നില്ല',
      'downloading_data': 'ഡാറ്റ ഡൗൺലോഡ് ചെയ്യുന്നു',
      'downloading_desc': 'നിങ്ങളുടെ പ്രൊഫൈൽ, മൃഗസംരക്ഷണ ചരിത്രം, കാലാവസ്ഥാ വിവരങ്ങൾ എന്നിവ മാറ്റുന്നതിന് സജ്ജമാക്കുന്നു...',
      'done': 'കഴിഞ്ഞു',
      'delete_warning': 'മുന്നറിയിപ്പ്: ഈ പ്രവർത്തനം ശാശ്വതമാണ്. നിങ്ങളുടെ എല്ലാ ഡാറ്റയും മുൻഗണനകളും ശാശ്വതമായി ഇല്ലാതാക്കപ്പെടും.',
      'delete_permanently': 'ശാശ്വതമായി ഇല്ലാതാക്കുക',
      'delete_success': 'അക്കൗണ്ട് വിജയകരമായി ഇല്ലാതാക്കി.',
      'how_help': 'ഇന്ന് ഞങ്ങൾ നിങ്ങൾക്ക് എങ്ങനെ സഹായിക്കണം?',
      'send_msg': 'ഞങ്ങൾക്ക് സന്ദേശം അയക്കൂ, ഞങ്ങൾ നിങ്ങളെ ബന്ധപ്പെടാം!',
      'enter_details': 'വിവരങ്ങൾ ഇവിടെ നൽകുക...',
      'submit': 'സമർപ്പിക്കുക',
      'submit_success': 'നന്ദി! നിങ്ങളുടെ സന്ദേശം ലഭിച്ചിരിക്കുന്നു.',
      'app_desc': 'അഗ്രിഗ്രോ ആധുനിക കർഷകരെ തത്സമയ കാലാവസ്ഥാ വിശകലനം, വിള ആരോഗ്യ നിർദ്ദേശങ്ങൾ, രോഗനിർണ്ണയ മാർഗ്ഗങ്ങൾ എന്നിവ നൽകി സുസ്ഥിര കൃഷി പ്രോത്സാഹിപ്പിക്കുന്നു.',
      'copyright': '© 2026 അഗ്രിഗ്രോ ഇങ്ക്. എല്ലാ അവകാശങ്ങളും നിക്ഷിപ്തം.',
      'version_build': 'പതിപ്പ് 1.0.0 (ബിൽഡ് 1)',
      'community': 'കൂട്ടായ്മ',
      'market': 'വിപണി',
      'gemini_settings': 'AI അസിസ്റ്റന്റ് ക്രമീകരണങ്ങൾ',
      'gemini_api_key': 'ജെമിനി API കീ',
      'gemini_api_key_desc': 'തത്സമയ വിശകലനത്തിനായി ജെമിനി API കീ കോൺഫിഗർ ചെയ്യുക',
      'gemini_api_key_hint': 'API കീ നൽകുക (AIzaSy...)',
      'gemini_api_key_saved': 'ജെമിനി API കീ വിജയകരമായി അപ്ഡേറ്റ് ചെയ്തു!',
      'gemini_api_key_status_active': 'കോൺഫിഗർ ചെയ്തു (സജീവം)',
      'gemini_api_key_status_offline': 'കോൺഫിഗർ ചെയ്തിട്ടില്ല (ഓഫ്‌ലൈൻ ഡെമോ)',
      'gemini_api_key_help': 'ഗൂഗിൾ AI സ്റ്റുഡിയോയിൽ നിന്ന് സൗജന്യ ജെമിനി API കീ നേടുക',
      'fertilizer_cat': 'AI അസിസ്റ്റന്റ്',
      'fertilizer_title': 'അഗ്രിബോട്ട്',
      'fertilizer_desc': 'വിള ആരോഗ്യത്തെയും വളപ്രയോഗത്തെയും കുറിച്ച് അഗ്രിബോട്ടിനോട് ചോദിക്കുക.',
      'fertilizer_action': 'അഗ്രിബോട്ടുമായി ചാറ്റ് ചെയ്യുക',
      'market_alert_cat': 'വിപണി സൂചിക',
      'market_alert_title': 'വിപണി വിലകൾ',
      'market_alert_desc': 'നിങ്ങളുടെ പ്രാദേശിക മണ്ടികളിലെ തത്സമയ സാധന വിലകളും ദിവസേനയുള്ള വിപണി പ്രവണതകളും അറിയുക.',
      'market_alert_action': 'വിപണി വിലകൾ കാണുക',
      'intercrop_cat': 'വിള ഉപദേശം',
      'intercrop_title': 'ഇടവിള ഉപദേശകൻ',
      'intercrop_desc': 'നിങ്ങളുടെ ഭൂമിയുടെ ഉപയോഗവും ലാഭവും വർദ്ധിപ്പിക്കുന്നതിനായി ഇടവിള രീതികളെക്കുറിച്ചുള്ള സ്മാർട്ട് ശുപാർശകൾ നേടുക.',
      'intercrop_action': 'ശുപാർശകൾ നേടുക',
      'pest_alert_cat': 'കീടങ്ങളും രോഗങ്ങളും',
      'pest_alert_title': 'വിള രോഗങ്ങൾ',
      'pest_alert_desc': 'രോഗങ്ങൾ നേരത്തെ കണ്ടെത്താൻ വിളകൾ സ്കാൻ ചെയ്യുക, കീടപ്രശ്നങ്ങൾ കണ്ടെത്തുക, തൽക്ഷണ ചികിത്സാ ശുപാർശകൾ നേടുക.',
      'pest_alert_action': 'വിളകൾ സ്കാൻ ചെയ്യുക',
    },
    'Kannada': {
      'settings': 'ಸಂಯೋಜನೆಗಳು',
      'logout': 'ಲಾಗ್ ಔಟ್',
      'notifications': 'ಸೂಚನೆಗಳು',
      'push_notifications': 'ಪುಶ್ ಸೂಚನೆಗಳು',
      'push_desc': 'ನಿಮ್ಮ ಸಾಧನದಲ್ಲಿ ಎಚ್ಚರಿಕೆಗಳನ್ನು ಸ್ವೀಕರಿಸಿ',
      'email_notifications': 'ಇಮೇಲ್ ಸೂಚನೆಗಳು',
      'email_desc': 'ಇಮೇಲ್ ಮೂಲಕ ನವೀಕರಣಗಳನ್ನು ಪಡೆಯಿರಿ',
      'sms_notifications': 'ಎಸ್ಎಂಎಸ್ ಸೂಚನೆಗಳು',
      'sms_desc': 'ಪಠ್ಯ ಸಂದೇಶಗಳನ್ನು ಸ್ವೀಕರಿಸಿ',
      'privacy': 'ಗೌಪ್ಯತೆ',
      'profile_visibility': 'ಪ್ರೊಫೈಲ್ ಗೋಚರತೆ',
      'profile_desc': 'ನಿಮ್ಮ ಪ್ರೊಫೈಲ್ ಯಾರು ನೋಡಬಹುದು ಎಂಬುದನ್ನು ನಿಯಂತ್ರಿಸಿ',
      'data_sharing': 'ಡೇಟಾ ಹಂಚಿಕೆ',
      'data_sharing_desc': 'ಸುಧಾರಣೆಗಳಿಗಾಗಿ ಅನಾಮಧೇಯ ಡೇಟಾ ಹಂಚಿಕೆಯನ್ನು ಅನುಮತಿಸಿ',
      'preferences': 'ಆದ್ಯತೆಗಳು',
      'language': 'ಭಾಷೆ',
      'language_desc': 'ನಿಮ್ಮ ಆದ್ಯತೆಯ ಭಾಷೆಯನ್ನು ಆಯ್ಕೆಮಾಡಿ',
      'theme': 'ಥೀಮ್',
      'theme_desc': 'ನಿಮ್ಮ ಆಪ್ ಥೀಮ್ ಆಯ್ಕೆಮಾಡಿ',
      'units': 'ಘಟಕಗಳು',
      'units_desc': 'ಮಾಪನ ಘಟಕಗಳು',
      'account': 'ಖಾತೆ',
      'change_password': 'ಪಾಸ್‌ವರ್ಡ್ ಬದಲಾಯಿಸಿ',
      'download_data': 'ಡೇಟಾ ಡೌನ್‌ಲೋಡ್ ಮಾಡಿ',
      'delete_account': 'ಖಾತೆ ಅಳಿಸಿ',
      'support': 'ಬೆಂಬಲ',
      'help_center': 'सहायता केंद्र',
      'contact_us': 'ನಮ್ಮನ್ನು ಸಂಪರ್ಕಿಸಿ',
      'about': 'ಬಗ್ಗೆ',
      'good_morning': 'ಶುಭ ಮುಂಜಾನೆ, \n',
      'live_data': 'ಲೈವ್ ಡೇಟಾ',
      'soil_moisture': 'ಮಣ್ಣಿನ ತೇವಾಂಶ',
      'temperature': 'ತಾಪಮಾನ',
      'humidity': 'ಆರ್ದ್ರತೆ',
      'soil_ph': 'ಮಣ್ಣಿನ ಪಿಎಚ್',
      'optimal': 'ಉತ್ತಮ',
      'intercrop_suggestion': 'ಅಂತರಬೆಳೆ ಸಲಹೆ',
      'view_report': 'ವರದಿ ನೋಡಿ',
      'quick_actions': 'ತ್ವರಿತ ಕ್ರಮಗಳು',
      'lms': 'ಎಲ್‌ಎಂಎಸ್',
      'disease_detection': 'ರೋಗ\nಪತ್ತೆಹಚ್ಚುವಿಕೆ',
      'notes': 'ಟಿಪ್ಪಣಿಗಳು',
      'news': 'ಸುದ್ದಿ',
      'scheme': 'ಯೋಜನೆ',
      'market_prices': 'ಮಾರುಕಟ್ಟೆ\nಬೆಲೆಗಳು',
      'finance': 'ಹಣಕاصು',
      'crop_calendar': 'ಬೆಳೆ\nಕ್ಯಾಲೆಂಡರ್',
      'livestock': 'ಪಶುಸಂಗೋಪನೆ',
      'agrihub': 'ಅಗ್ರಿಹಬ್',
      'current_weather': 'ಪ್ರಸ್ತುತ ಹವಾಮಾನ',
      'overcast': 'ಮೋಡ ಕವಿದ ವಾತಾವರಣ',
      'no_rain': 'ಮಳೆಯ ಮುನ್ಸೂಚನೆ ಇಲ್ಲ',
      'wind_speed': 'ಗಾಳಿಯ ವೇಗ',
      'humidity_title': 'ಆರ್ದ್ರತೆ',
      'view_detailed_forecast': 'ವಿವರವಾದ ಹವಾಮಾನ ವರದಿ',
      'intercrop_update': 'ಅಂತರಬೆಳೆ ಸಲಹೆಗಳ\nಇತ್ತೀಚಿನ ನವೀಕರಣ',
      'intercrop_update_desc': 'ಕೀಟ ನಿಯಂತ್ರಣಕ್ಕಾಗಿ ಅಂತರಬೆಳೆ ಸಲಹೆಗಳನ್ನು ಪರಿಶೀಲಿಸಿ.',
      'view_suggestions': 'ಸಲಹೆಗಳನ್ನು ನೋಡಿ',
      'soil_moisture_title': 'ಮಣ್ಣಿನ ತೇವಾಂಶ',
      'temp_title': 'ತಾಪಮಾನ',
      'humidity_data': 'ಆರ್ದ್ರತೆ',
      'soil_ph_title': 'ಮಣ್ಣಿನ ಪಿಎಚ್',
      'cancel': 'ರದ್ದುಮಾಡು',
      'logout_confirm': 'ನೀವು ಖಂಡಿತವಾಗಿಯೂ ಅಗ್ರಿ ಗ್ರೋನಿಂದ ಲಾಗ್ ಔಟ್ ಮಾಡಲು ಬಯಸುತ್ತೀರಾ?',
      'logout_success': 'ಯಶಸ್ವಿಯಾಗಿ ಲಾಗ್ ಔಟ್ ಮಾಡಲಾಗಿದೆ!',
      'password_current': 'ಪ್ರಸ್ತುತ ಪಾಸ್‌ವರ್ಡ್',
      'password_new': 'ಹೊಸ ಪಾಸ್‌ವರ್ಡ್',
      'password_confirm': 'ಹೊಸ ಪಾಸ್‌ವರ್ಡ್ ಖಚಿತಪಡಿಸಿ',
      'password_update': 'ನವೀಕರಿಸಿ',
      'password_success': 'ಪಾಸ್‌ವರ್ಡ್ ಯಶಸ್ವಿಯಾಗಿ ನವೀಕರಿಸಲಾಗಿದೆ!',
      'password_error_empty': 'ದಯವಿಟ್ಟು ಪ್ರಸ್ತುತ ಪಾಸ್‌ವರ್ಡ್ ಅನ್ನು ನಮೂದಿಸಿ',
      'password_error_short': 'ಪಾಸ್‌ವರ್ಡ್ ಕನಿಷ್ಠ 6 ಅಕ್ಷರಗಳಿರಬೇಕು',
      'password_error_match': 'ಪಾಸ್‌ವರ್ಡ್ ಹೊಂದಿಕೆಯಾಗುತ್ತಿಲ್ಲ',
      'downloading_data': 'ಡೇಟಾ ಡೌನ್‌ಲೋಡ್ ಆಗುತ್ತಿದೆ',
      'downloading_desc': 'ನಿಮ್ಮ ಪ್ರೊಫೈಲ್, ಪಶುಸಂಗೋಪನೆ ಇತಿಹಾಸ ಮತ್ತು ಹವಾಮಾನ ದಾಖಲೆಗಳನ್ನು ಸಿದ್ಧಪಡಿಸಲಾಗುತ್ತಿದೆ...',
      'done': 'ಮುಗಿದಿದೆ',
      'delete_warning': 'ಎಚ್ಚರಿಕೆ: ಈ ಕ್ರಮವು ಶಾಶ್ವತವಾಗಿದೆ. ನಿಮ್ಮ ಎಲ್ಲಾ ಡೇಟಾ ಮತ್ತು ಆದ್ಯತೆಗಳನ್ನು ಶಾಶ್ವತವಾಗಿ ಅಳಿಸಲಾಗುತ್ತದೆ.',
      'delete_permanently': 'ಶಾಶ್ವತವಾಗಿ ಅಳಿಸಿ',
      'delete_success': 'ಖಾತೆಯನ್ನು ಯಶಸ್ವಿಯಾಗಿ ಅಳಿಸಲಾಗಿದೆ.',
      'how_help': 'ಇಂದು ನಾವು ನಿಮಗೆ ಹೇಗೆ ಸಹಾಯ ಮಾಡಬಹುದು?',
      'send_msg': 'ನಮಗೆ ಸಂದೇಶ ಕಳುಹಿಸಿ ಮತ್ತು ನಾವು ನಿಮ್ಮನ್ನು ಸಂಪರ್കಿಸುತ್ತೇವೆ!',
      'enter_details': 'ವಿವರಗಳನ್ನು ಇಲ್ಲಿ ನಮೂದಿಸಿ...',
      'submit': 'ಸಲ್ಲಿಸು',
      'submit_success': 'ಧನ್ಯವಾದಗಳು! ನಿಮ್ಮ ಸಂದೇಶ ಸ್ವೀಕರಿಸಲಾಗಿದೆ.',
      'app_desc': 'ಅಗ್ರಿ ಗ್ರೋ ಆಧುನಿಕ ರೈತರಿಗೆ ನೈಜ-ಸಮಯದ ಹವಾಮಾನ ವಿಶ್ಲೇಷಣೆ, ಬೆಳೆ ಆರೋಗ್ಯ ಶಿಫಾರಸುಗಳು ಮತ್ತು ರೋಗ ಪತ್ತೆಹಚ್ಚುವಿಕೆಯನ್ನು ಒದಗಿಸಿ ಸುಸ್ಥಿರ ಕೃಷಿಯನ್ನು ಉತ್ತೇಜಿಸುತ್ತದೆ.',
      'copyright': '© 2026 ಅಗ್ರಿ ಗ್ರೋ ಇಂಕ್. ಎಲ್ಲಾ ಹಕ್ಕುಗಳನ್ನು ಕಾಯ್ದಿರಿಸಲಾಗಿದೆ.',
      'version_build': 'ಆವೃತ್ತಿ 1.0.0 (ಬಿಲ್ಡ್ 1)',
      'community': 'ಸಮುದಾಯ',
      'market': 'ಮಾರುಕಟ್ಟೆ',
      'gemini_settings': 'AI ಸಹಾಯಕ ಸೆಟ್ಟಿಂಗ್‌ಗಳು',
      'gemini_api_key': 'ಜೆಮಿನಿ API ಕೀ',
      'gemini_api_key_desc': 'ಲೈವ್ ವಿಶ್ಲೇಷಣೆಗಾಗಿ ಜೆಮಿನಿ API ಕೀಲಿಯನ್ನು ಕಾನ್ಫಿಗರ್ ಮಾಡಿ',
      'gemini_api_key_hint': 'API ಕೀಲಿಯನ್ನು ನಮೂದಿಸಿ (AIzaSy...)',
      'gemini_api_key_saved': 'ಜೆಮಿನಿ API ಕೀ ಯಶಸ್ವಿಯಾಗಿ ನವೀಕರಿಸಲಾಗಿದೆ!',
      'gemini_api_key_status_active': 'ಕಾನ್ಫಿಗರ್ ಮಾಡಲಾಗಿದೆ (ಸಕ್ರಿಯ)',
      'gemini_api_key_status_offline': 'ಕಾನ್ಫಿಗರ್ ಮಾಡಲಾಗಿಲ್ಲ (ಆಫ್‌ಲೈನ್ ಡೆಮೊ)',
      'gemini_api_key_help': 'ಗೂಗಲ್ AI ಸ್ಟುಡಿಯೋದಿಂದ ಉಚಿತ ಜೆಮಿನಿ API ಕೀಲಿಯನ್ನು ಪಡೆಯಿರಿ',
      'fertilizer_cat': 'AI ಸಹಾಯಕ',
      'fertilizer_title': 'ಅಗ್ರಿಬಾಟ್',
      'fertilizer_desc': 'ಬೆಳೆ ಆರೋಗ್ಯ ಮತ್ತು ರಸಗೊಬ್ಬರ ಶಿಫಾರಸುಗಳ ಬಗ್ಗೆ ಅಗ್ರಿಬಾಟ್ ಜೊತೆ ಚರ್ಚಿಸಿ.',
      'fertilizer_action': 'ಅಗ್ರಿಬಾಟ್ ಜೊತೆ ಚಾಟ್ ಮಾಡಿ',
      'market_alert_cat': 'ಮಾರುಕಟ್ಟೆ ಸೂಚ್ಯಂಕ',
      'market_alert_title': 'ಮಾರುಕಟ್ಟೆ ಬೆಲೆಗಳು',
      'market_alert_desc': 'ನಿಮ್ಮ ಸ್ಥಳೀಯ ಮಂಡಿಗಳ ನೈಜ-ಸಮಯದ ಸರಕು ಬೆಲೆಗಳು ಮತ್ತು ದೈನಂದಿನ ಮಾರುಕಟ್ಟೆ ಪ್ರವೃತ್ತಿಗಳನ್ನು ಪಡೆಯಿರಿ.',
      'market_alert_action': 'ಮಾರುಕಟ್ಟೆ ಬೆಲೆಗಳನ್ನು ನೋಡಿ',
      'intercrop_cat': 'ಬೆಳೆ ಸಲಹೆ',
      'intercrop_title': 'ಅಂತರಬೆಳೆ ಸಲಹೆಗಾರ',
      'intercrop_desc': 'ನಿಮ್ಮ ಭೂಮಿಯ ಬಳಕೆ ಮತ್ತು ಲಾಭವನ್ನು ಗರಿಷ್ಠಗೊಳಿಸಲು ಅಂತರಬೆಳೆ ಮಾದರಿಗಳ ಕುರಿತು ಸ್ಮಾರ್ಟ್ ಶಿಫಾರಸುಗಳನ್ನು ಪಡೆಯಿರಿ.',
      'intercrop_action': 'ಶಿಫಾರಸುಗಳನ್ನು ಪಡೆಯಿರಿ',
      'pest_alert_cat': 'ಕೀಟ ಮತ್ತು ರೋಗ',
      'pest_alert_title': 'ಬೆಳೆ ರೋಗಗಳು',
      'pest_alert_desc': 'ರೋಗಗಳನ್ನು ಮೊದಲೇ ಪತ್ತೆಹಚ್ಚಲು ನಿಮ್ಮ ಬೆಳೆಯನ್ನು ಸ್ಕ್ಯಾನ್ ಮಾಡಿ, ಕೀಟ ಸಮಸ್ಯೆಗಳನ್ನು ನಿವಾರಿಸಿ ಮತ್ತು ತ್ವರಿತ ಚಿಕಿತ್ಸಾ ಶಿಫಾರಸುಗಳನ್ನು ಪಡೆಯಿರಿ.',
      'pest_alert_action': 'ಬೆಳೆಗಳನ್ನು ಸ್ಕ್ಯಾನ್ ಮಾಡಿ',
    }
  };

  static String translate(String lang, String key) {
    return _localizedValues[lang]?[key] ?? _localizedValues['English']?[key] ?? key;
  }
}

// Extracted helpers to fetch direct configurations synchronously
extension AppStateHelper on AppState {
  String get profileVisibility {
    return 'Public';
  }
  
  String get units {
    return 'Metric';
  }
}
