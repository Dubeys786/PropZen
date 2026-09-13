import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/auth_service.dart';

/// Luxury Branded PropZen Splash Barrier during initial session restoration
class PropZenSplashScreen extends StatelessWidget {
  const PropZenSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0B0F19),
              Color(0xFF111827),
              Color(0xFF1E1B4B),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Glowing PropZen Emblem
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x667C3AED),
                      blurRadius: 36,
                      spreadRadius: 4,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  LucideIcons.building2,
                  color: Colors.white,
                  size: 40,
                ),
              ),

              const SizedBox(height: 28),

              // Brand Title
              Text(
                'PropZen',
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                'Intelligence-First Real Estate Platform',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF94A3B8),
                  letterSpacing: 0.5,
                ),
              ),

              const SizedBox(height: 48),

              // Spinner & Restoring Notice
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Color(0xFFA78BFA),
                ),
              ),

              const SizedBox(height: 16),

              Text(
                'Restoring secure session...',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Route Barrier: Protects against refresh flash on role-guarded routes
class AuthRouteBarrier extends StatelessWidget {
  final Widget Function(BuildContext context) builder;

  const AuthRouteBarrier({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AuthService.instance,
      builder: (context, _) {
        if (AuthService.instance.isLoading) {
          return const PropZenSplashScreen();
        }
        return builder(context);
      },
    );
  }
}

/// App Root Gate: Waits for session restoration before presenting home/dashboard
class AuthGate extends StatelessWidget {
  final Widget child;

  const AuthGate({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AuthService.instance,
      builder: (context, _) {
        if (AuthService.instance.isLoading) {
          return const PropZenSplashScreen();
        }
        return child;
      },
    );
  }
}
