import 'package:flutter/material.dart';
import 'package:lari_yuk/pages/dashboard_page.dart';
import 'package:lari_yuk/pages/register_page.dart';
import 'package:lari_yuk/theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool obscureText = true;
  bool isLoading = false;

  Future<void> signInWithEmail() async {
    setState(() => isLoading = true);
    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      User? user = userCredential.user;

      if (user != null && !user.emailVerified) {
        // Email belum diverifikasi
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Email Belum Diverifikasi"),
            content: const Text("Silakan verifikasi email Anda terlebih dahulu."),
            actions: [
              TextButton(
                onPressed: () async {
                  try {
                    await user.sendEmailVerification();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Email verifikasi telah dikirim ulang")),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Gagal mengirim verifikasi: ${e.toString()}")),
                    );
                  }
                },
                child: const Text("Kirim Ulang Verifikasi"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Tutup"),
              ),
            ],
          ),
        );
        await FirebaseAuth.instance.signOut(); // Logout paksa jika belum verifikasi
      } else {
        // Sudah diverifikasi
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardPage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login gagal: ${e.message}')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      print('Error signing in with Google: $e');
      return null;
    }
  }

  Future<void> showForgotPasswordDialog() async {
    final TextEditingController forgotEmailController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Reset Password"),
        content: TextField(
          controller: forgotEmailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(hintText: "Enter your email address"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              final email = forgotEmailController.text.trim();
              if (email.isNotEmpty) {
                try {
                  await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Reset link sent to your email")),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error: ${e.toString()}")),
                  );
                }
              }
            },
            child: const Text("Send"),
          ),
        ],
      ),
    );
  }

  Widget emailInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Email Address', style: blackTextStyle.copyWith(fontSize: 12, fontWeight: medium)),
        const SizedBox(height: 8),
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xffE8E8E8)),
          ),
          child: TextFormField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            style: primaryTextStyle,
            decoration: InputDecoration.collapsed(
              hintText: 'Your Email Address',
              hintStyle: subtitleTextStyle.copyWith(fontSize: 11),
            ),
          ),
        ),
      ],
    );
  }

  Widget passwordInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Password', style: blackTextStyle.copyWith(fontSize: 12, fontWeight: medium)),
        const SizedBox(height: 8),
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xffE8E8E8)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: passwordController,
                  obscureText: obscureText,
                  style: primaryTextStyle,
                  decoration: InputDecoration.collapsed(
                    hintText: 'Enter Your Password',
                    hintStyle: subtitleTextStyle.copyWith(fontSize: 11),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                onPressed: () => setState(() => obscureText = !obscureText),
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: GestureDetector(
              onTap: showForgotPasswordDialog,
              child: Text(
                'Forgot Password',
                style: TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget submitButton() {
    return GestureDetector(
      onTap: isLoading ? null : signInWithEmail,
      child: Container(
        height: 50,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [primaryColor, thirdColor]),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : Text('Login', style: primaryTextStyle.copyWith(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
        ),
      ),
    );
  }

  Widget orDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey[300], thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text('Or Login With', style: secondaryTextStyle.copyWith(fontSize: 11, fontWeight: FontWeight.w400)),
        ),
        Expanded(child: Divider(color: Colors.grey[300], thickness: 1)),
      ],
    );
  }

  Widget googleSignInButton() {
    return GestureDetector(
      onTap: () async {
        final userCredential = await signInWithGoogle();
        if (userCredential != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DashboardPage()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Google Sign-In failed or cancelled')),
          );
        }
      },
      child: Container(
        height: 50,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xffE8E8E8)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/google.jpg', width: 24, height: 24),
            const SizedBox(width: 8),
            Text(
              'Lanjutkan dengan Google',
              style: blackTextStyle.copyWith(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor3,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          iconSize: 16,
        ),
        title: Text('Login Lari Yuk', style: primaryTextStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
        backgroundColor: backgroundColor3,
        elevation: 0,
      ),
      body: SafeArea(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
          padding: const EdgeInsets.only(top: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Welcome to Your Running Journey', style: primaryTextStyle.copyWith(fontWeight: FontWeight.w700, fontSize: 18)),
              Text('Track, Run, Succeed! 🏃‍♂️', style: thirdTextStyle.copyWith(fontWeight: FontWeight.w700, fontSize: 18)),
              Text('Happy to see you again. Please login here.', style: secondaryTextStyle.copyWith(fontWeight: FontWeight.w400, fontSize: 14)),
              const SizedBox(height: 36),
              emailInput(),
              const SizedBox(height: 20),
              passwordInput(),
              const SizedBox(height: 36),
              submitButton(),
              const SizedBox(height: 20),
              orDivider(),
              const SizedBox(height: 20),
              googleSignInButton(),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Belum punya akun?', style: secondaryTextStyle.copyWith(fontSize: 12)),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const RegisterPage()),
                      );
                    },
                    child: Text('Daftar', style: primaryTextStyle.copyWith(fontWeight: FontWeight.w600, fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
