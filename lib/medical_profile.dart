import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'language_service.dart'; // 1. استيراد كلاس اللغة عشان نقدر نترجم الشاشة

class MedicalProfilePage extends StatefulWidget {
  const MedicalProfilePage({super.key});
  @override
  State<MedicalProfilePage> createState() => _MedicalProfilePageState();
}

class _MedicalProfilePageState extends State<MedicalProfilePage> {
  final _nameCtrl = TextEditingController();
  final _bloodCtrl = TextEditingController();
  final _medsCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _idNumCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameCtrl.text = prefs.getString('name') ?? '';
      _bloodCtrl.text = prefs.getString('blood') ?? '';
      _medsCtrl.text = prefs.getString('meds') ?? '';
      _phoneCtrl.text = prefs.getString('phone') ?? '';
      _addressCtrl.text = prefs.getString('address') ?? '';
      _idNumCtrl.text = prefs.getString('idNum') ?? '';
      _notesCtrl.text = prefs.getString('notes') ?? '';
    });
  }

  _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('name', _nameCtrl.text);
    await prefs.setString('blood', _bloodCtrl.text);
    await prefs.setString('meds', _medsCtrl.text);
    await prefs.setString('phone', _phoneCtrl.text);
    await prefs.setString('address', _addressCtrl.text);
    await prefs.setString('idNum', _idNumCtrl.text);
    await prefs.setString('notes', _notesCtrl.text);

    if (!mounted) return;

    // 2. هنا استبدلنا رسالة النجاح لتظهر بلغة الحاج المختارة
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          LanguageService.translate('save_success'),
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      // 3. جعل اتجاه الشاشة يمين-شمال للعربي والأوردو، وشمال-يمين لباقي اللغات
      textDirection: (LanguageService.currentLang == 'ar' ||
              LanguageService.currentLang == 'ur')
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          // 4. ترجمة عنوان الشاشة
          title: Text(
            LanguageService.translate('med_title'),
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.black87,
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.redAccent,
                child: Icon(Icons.medical_services_rounded,
                    size: 60, color: Colors.white),
              ),
            ),
            const SizedBox(height: 25),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // 5. ترجمة جميع حقول النصوص داخل بطاقة الملف الطبي
                    _buildModernTextField(
                        _nameCtrl,
                        LanguageService.translate('med_name'),
                        Icons.person_outline),
                    _buildModernTextField(
                        _bloodCtrl,
                        LanguageService.translate('med_blood'),
                        Icons.bloodtype_outlined),
                    _buildModernTextField(
                        _idNumCtrl,
                        LanguageService.translate('med_id'),
                        Icons.badge_outlined),
                    _buildModernTextField(
                        _addressCtrl,
                        LanguageService.translate('med_address'),
                        Icons.home_outlined),
                    _buildModernTextField(
                        _phoneCtrl,
                        LanguageService.translate('med_phone'),
                        Icons.phone_in_talk_outlined),
                    _buildModernTextField(
                        _medsCtrl,
                        LanguageService.translate('med_chronic'),
                        Icons.monitor_heart_outlined),
                    _buildModernTextField(
                        _notesCtrl,
                        LanguageService.translate('med_notes'),
                        Icons.note_alt_outlined,
                        maxLines: 3),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              height: 55,
              child: ElevatedButton(
                onPressed: _saveData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                ),
                // 6. ترجمة نص زر الحفظ
                child: Text(
                  LanguageService.translate('save_btn'),
                  style: const TextStyle(
                      fontSize: 18, color: Colors.white, fontFamily: 'Cairo'),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildModernTextField(
      TextEditingController ctrl, String label, IconData icon,
      {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontFamily: 'Cairo'),
          prefixIcon: Icon(icon, color: Colors.redAccent),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey[100],
        ),
      ),
    );
  }
}
