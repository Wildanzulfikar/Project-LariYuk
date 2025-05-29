import 'package:flutter/material.dart';
import 'package:lari_yuk/theme.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor3, 
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

            
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: primaryColor),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  Expanded(
                    child: Text(
                      'Register Lari Yukk',
                      textAlign: TextAlign.center,
                      style: primaryTextStyle.copyWith(
                        fontSize: 20,
                        fontWeight: bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  style: primaryTextStyle.copyWith(fontSize: 23),
                  children: [
                    TextSpan(
                      text: 'Sign up now for the best running ',
                      style: primaryTextStyle.copyWith(
                        fontWeight: bold,
                      ),
                    ),
                    TextSpan(
                      text: 'experience!',
                      style: thirdTextStyle.copyWith(
                        fontWeight: bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Track progress, set goals, and stay motivated.',
                style: secondaryTextStyle.copyWith(fontSize: 12),
              ),
              const SizedBox(height: 24),
              const SizedBox(height: 24),

              // Email Field
              Text(
                'Email Address',
                style: primaryTextStyle.copyWith(
                  fontSize: 16,
                  fontWeight: bold,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Enter Your Email Address',
                  hintStyle: secondaryTextStyle,
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: secondaryColor, width: 1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Password Field
              Text(
                'Password',
                style: primaryTextStyle.copyWith(
                  fontSize: 16,
                  fontWeight: bold,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Enter Your Password',
                  hintStyle: secondaryTextStyle,
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: secondaryColor, width: 1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Confirm Password Field
              Text(
                'Confirm Password',
                style: primaryTextStyle.copyWith(
                  fontSize: 16,
                  fontWeight: bold,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Enter Your Password',
                  hintStyle: secondaryTextStyle,
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: secondaryColor, width: 1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Register Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [thirdColor, primaryColor],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Register',
                        style: primaryTextStyle.copyWith(
                          fontSize: 18,
                          fontWeight: bold,
                          color: backgroundColor3,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Login Option
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already Have An Account?',
                    style: secondaryTextStyle,
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/login');
                    },
                    child: Text(
                      'Login',
                      style: thirdTextStyle.copyWith(fontWeight: bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Social Login Divider
              Row(
                children: [
                  const Expanded(child: Divider(thickness: 1)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      'Or Login With',
                      style: secondaryTextStyle,
                    ),
                  ),
                  const Expanded(child: Divider(thickness: 1)),
                ],
              ),
              const SizedBox(height: 16),
              // Google Login Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    side: BorderSide(color: secondaryColor),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('assets/google.jpg', height: 24, width: 24),
                      const SizedBox(width: 8),
                      Text(
                        'Lanjutkan dengan Google',
                        style: primaryTextStyle,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
