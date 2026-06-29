import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TermsAndPrivacyScreen extends StatelessWidget {
  const TermsAndPrivacyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Aesthetic palette matching CurveType cocoa theme
    final Color scaffoldBgColor = isDark ? const Color(0xFF1A1816) : const Color(0xFFFDFCFB);
    final Color primaryTextColor = isDark ? const Color(0xFFF4EFEA) : const Color(0xFF3A3530);
    final Color secondaryTextColor = isDark ? const Color(0xFFA89E95) : const Color(0xFF3A3530).withOpacity(0.6);
    final Color accentColor = const Color(0xFFE2D1C3);
    final Color cardBgColor = isDark ? const Color(0xFF2C2621) : const Color(0xFFFFEAD9).withOpacity(0.3);
    final Color borderColor = isDark ? const Color(0xFF2C2621) : const Color(0xFFE2D1C3);

    return Scaffold(
      backgroundColor: scaffoldBgColor,
      appBar: AppBar(
        backgroundColor: scaffoldBgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: primaryTextColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Legal Center',
          style: GoogleFonts.outfit(
            color: primaryTextColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header section
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.gavel_rounded,
                      size: 48,
                      color: accentColor,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Terms of Service & Privacy Policy',
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: primaryTextColor,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Last updated: June 2026',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: secondaryTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Section 1: Terms of Service
              _buildSectionTitle('1. Terms of Service', primaryTextColor, accentColor),
              _buildCard(
                cardBgColor,
                borderColor,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildParagraph(
                      'Welcome to CurveType. By accessing or using our application, you agree to comply with and be bound by these Terms of Service. Please review them carefully.',
                      primaryTextColor,
                    ),
                    _buildSubheading('Use of the App', primaryTextColor),
                    _buildParagraph(
                      'CurveType provides a local-first kinetic typography design studio. You are granted a limited, non-exclusive, non-transferable license to use the app for personal and commercial creative projects.',
                      primaryTextColor,
                    ),
                    _buildSubheading('User Generated Content', primaryTextColor),
                    _buildParagraph(
                      'You retain full ownership and intellectual property rights of the text designs, layouts, and projects you construct inside the app. CurveType does not claim any ownership rights over your creative creations.',
                      primaryTextColor,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Section 2: Privacy Policy
              _buildSectionTitle('2. Privacy Policy', primaryTextColor, accentColor),
              _buildCard(
                cardBgColor,
                borderColor,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildParagraph(
                      'We value your privacy and security. This Privacy Policy details how we handle information associated with your account and typography workspace.',
                      primaryTextColor,
                    ),
                    _buildSubheading('Data Storage & Syncing', primaryTextColor),
                    _buildParagraph(
                      'CurveType operates as a local-first application. Your projects are stored directly on your device in a secure SQLite database cache. If you sign in, your data is synced in real-time with Google Cloud Firebase to enable strict, isolated cloud backups across your authenticated devices.',
                      primaryTextColor,
                    ),
                    _buildSubheading('Information Collection', primaryTextColor),
                    _buildParagraph(
                      'When you register using Email/Password, Google Sign-In, or Phone Authentication, we store details such as your user ID, display name, email address, or phone number solely for account identification and data syncing purposes. We do not sell or lease your personal information to third parties.',
                      primaryTextColor,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Bottom agreement confirmation
              Center(
                child: Text(
                  'Thank you for designing with CurveType.',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: secondaryTextColor,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color textColor, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(Color bgColor, Color borderColor, Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: child,
    );
  }

  Widget _buildSubheading(String text, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(top: 14.0, bottom: 6.0),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildParagraph(String text, Color textColor) {
    return Text(
      text,
      style: GoogleFonts.outfit(
        fontSize: 13,
        color: textColor.withOpacity(0.8),
        height: 1.5,
      ),
    );
  }
}
