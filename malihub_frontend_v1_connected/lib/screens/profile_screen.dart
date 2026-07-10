import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/app_text_field.dart';
import '../models/user.dart';
import '../services/user_service.dart';
import '../services/api_exception.dart';

/// Profile / account screen, reached by tapping the avatar on the Dashboard.
/// Pops with the updated AppUser (if anything changed) so the Dashboard can
/// refresh its header without an extra round trip.
class ProfileScreen extends StatefulWidget {
  final AppUser user;
  final VoidCallback onLogout;

  const ProfileScreen({super.key, required this.user, required this.onLogout});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _userService = UserService();
  late AppUser _user;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Log out'),
        content: const Text('Are you sure you want to log out of Malihub?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary))),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Log Out', style: TextStyle(color: AppColors.expense))),
        ],
      ),
    );
    if (confirmed == true) {
      widget.onLogout();
    }
  }

  Future<void> _editProfile() async {
    final firstNameController = TextEditingController(text: _user.firstName);
    final lastNameController = TextEditingController(text: _user.lastName);
    final phoneController = TextEditingController(text: _user.phoneNumber ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(label: 'First name', hint: 'First name', controller: firstNameController),
            const SizedBox(height: 12),
            AppTextField(label: 'Last name', hint: 'Last name', controller: lastNameController),
            const SizedBox(height: 12),
            AppTextField(label: 'Phone number', hint: '07xx xxx xxx', controller: phoneController, keyboardType: TextInputType.phone),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary))),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Save')),
        ],
      ),
    );

    if (saved != true) return;

    try {
      final updated = await _userService.updateMe(
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        phoneNumber: phoneController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _user = updated;
        _changed = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Couldn't reach the server.")));
    }
  }

  Future<void> _changePassword() async {
    final currentController = TextEditingController();
    final newController = TextEditingController();

    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Change password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(label: 'Current password', hint: '••••••••', controller: currentController, obscureText: true, toggleObscure: true),
            const SizedBox(height: 12),
            AppTextField(label: 'New password', hint: 'Min. 8 characters', controller: newController, obscureText: true, toggleObscure: true),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary))),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Update')),
        ],
      ),
    );

    if (submitted != true) return;
    if (newController.text.length < 8) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('New password must be at least 8 characters')));
      return;
    }

    try {
      await _userService.changePassword(
        currentPassword: currentController.text,
        newPassword: newController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated')));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Couldn't reach the server.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 20, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                    onPressed: () => Navigator.of(context).pop(_changed ? _user : null),
                  ),
                  const Text('Profile', style: AppText.sectionTitle),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18), boxShadow: AppShadows.subtle),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: const BoxDecoration(color: AppColors.primaryPale, shape: BoxShape.circle),
                          alignment: Alignment.center,
                          child: Text(_user.initials, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 18)),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_user.fullName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.textPrimary)),
                              const SizedBox(height: 2),
                              Text(_user.email, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('ACCOUNT', style: AppText.eyebrow),
                  const SizedBox(height: 8),
                  _SettingsTile(icon: Icons.person_outline_rounded, label: 'Edit profile', onTap: _editProfile),
                  _SettingsTile(icon: Icons.lock_outline_rounded, label: 'Security', onTap: _changePassword),
                  _SettingsTile(icon: Icons.notifications_none_rounded, label: 'Notification preferences', onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Coming soon')));
                  }),
                  const SizedBox(height: 20),
                  const Text('SUPPORT', style: AppText.eyebrow),
                  const SizedBox(height: 8),
                  _SettingsTile(icon: Icons.help_outline_rounded, label: 'Help & support', onTap: () {}),
                  _SettingsTile(icon: Icons.info_outline_rounded, label: 'About Malihub', onTap: () {}),
                  const SizedBox(height: 20),
                  _SettingsTile(
                    icon: Icons.logout_rounded,
                    label: 'Log out',
                    iconColor: AppColors.expense,
                    labelColor: AppColors.expense,
                    onTap: () => _confirmLogout(context),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? labelColor;

  const _SettingsTile({required this.icon, required this.label, required this.onTap, this.iconColor, this.labelColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: Icon(icon, color: iconColor ?? AppColors.textSecondary, size: 20),
        title: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: labelColor ?? AppColors.textPrimary)),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 18),
        dense: true,
      ),
    );
  }
}
