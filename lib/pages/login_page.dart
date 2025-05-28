import 'package:flutter/material.dart';
import 'package:lari_yuk/theme.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Widget Input Email

    Widget emailInput() {
      return Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Email Address',
              style: blackTextStyle.copyWith(fontSize: 12, fontWeight: medium),
            ),
            SizedBox(height: 8.0),
            Container(
              height: 50,
              padding: EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Color(0xffE8E8E8)),
              ),
              child: Center(
                child: Row(
                  children: [
                    SizedBox(width: 4),
                    Expanded(
                      child: TextFormField(
                        style: primaryTextStyle,
                        decoration: InputDecoration.collapsed(
                          hintText: 'Your Email Address',
                          hintStyle: subtitleTextStyle.copyWith(fontSize: 11.0),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Widget Password
    Widget passwordInput() {
      bool obscureText = true;
      return Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Password',
              style: blackTextStyle.copyWith(fontSize: 12, fontWeight: medium),
            ),
            SizedBox(height: 8.0),
            Container(
              height: 50,
              padding: EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Color(0xffE8E8E8)),
              ),
              child: Center(
                child: Row(
                  children: [
                    SizedBox(width: 4),
                    Expanded(
                      child: StatefulBuilder(
                        builder: (context, setState) {
                          return TextFormField(
                            style: primaryTextStyle,
                            obscureText: obscureText,
                            decoration: InputDecoration.collapsed(
                              hintText: 'Enter Your Password',
                              hintStyle: subtitleTextStyle.copyWith(
                                fontSize: 11.0,
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    IconButton(
                      icon: Icon(
                        obscureText ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                        size: 20,
                      ),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),

            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: GestureDetector(
                  onTap: () {},
                  child: Text(
                    'Forgot Password',
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    Widget submitButton() {
      return GestureDetector(
        onTap: () {
          // Add your login logic here
        },
        child: Container(
          height: 50,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, thirdColor],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Text(
              'Login',
              style: primaryTextStyle.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12.0,
              ),
            ),
          ),
        ),
      );
    }

    Widget orDivider() {
      return Row(
        children: [
          Expanded(child: Divider(color: Colors.grey[300], thickness: 1)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              'Or Login With',
              style: secondaryTextStyle.copyWith(
                fontSize: 11.0,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey[300], thickness: 1)),
        ],
      );
    }

    Widget googleSignInButton() {
      return GestureDetector(
        onTap: () {},
        child: Container(
          height: 50,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Color(0xffE8E8E8)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.network(
                'https://upload.wikimedia.org/wikipedia/commons/5/53/Google_%22G%22_Logo.svg',
                height: 24,
                width: 24,
              ),
              SizedBox(width: 8.0),
              Text(
                'Lanjutkan dengan Google',
                style: blackTextStyle.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor3,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {},
          icon: Icon(Icons.arrow_back_ios_new_rounded),
          iconSize: 16.0,
        ),
        title: Text(
          'Login Lari Yuk',
          style: primaryTextStyle.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 16.0,
          ),
        ),
        centerTitle: true,
        backgroundColor: backgroundColor3,
      ),
      body: SafeArea(
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 28.0, vertical: 12.0),
          padding: EdgeInsets.only(top: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                child: Text(
                  'Welcome to Your Running Journey',
                  style: primaryTextStyle.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 18.0,
                  ),
                ),
              ),
              Container(
                child: Text(
                  'Track, Run, Succeed! 🏃‍♂️',
                  style: thirdTextStyle.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 18.0,
                  ),
                ),
              ),
              Text(
                'Happy, To See You Again, Please login here',
                style: secondaryTextStyle.copyWith(
                  fontWeight: FontWeight.w400,
                  fontSize: 12.0,
                ),
              ),
              SizedBox(height: 32.0),
              emailInput(),
              SizedBox(height: 24.0),
              passwordInput(),

              SizedBox(height: 36.0),
              submitButton(),

              SizedBox(height: 24.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 4.0,
                children: [
                  Text(
                    'Dont Have Any Account ?',
                    style: secondaryTextStyle.copyWith(
                      fontSize: 11.0,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  GestureDetector(
                    child: Text(
                      'Register Now',
                      style: thirdTextStyle.copyWith(
                        fontWeight: FontWeight.w500,
                        fontSize: 11.0,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 24.0),
              orDivider(), 
              SizedBox(height: 16.0),
              googleSignInButton(),
            ],
          ),
        ),
      ),
    );
  }
}
