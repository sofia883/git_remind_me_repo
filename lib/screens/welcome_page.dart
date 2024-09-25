import 'package:flutter/material.dart';
import 'package:remind_me/main.dart';
import 'package:remind_me/screens/home_page.dart';

class WelcomePage extends StatefulWidget {
  @override
  _WelcomePageState createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _fadeInAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _fadeInAnimation = CurvedAnimation(
      parent: _controller!,
      curve: Curves.easeIn,
    );

    _controller?.forward();

    // Navigate to MainScreen after the animation completes
    Future.delayed(Duration(seconds: 5), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => MainScreen()), // Navigate to HomePage
      );
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          Image.asset(
            'assets/images/wel (5).jpg', // Replace with your image path
            fit: BoxFit.cover,
          ),
          // Gradient overlay (orange to white)

          // Positioned text at the top left
          Center(
            child: FadeTransition(
              opacity: _fadeInAnimation!,
              child: RichText(
                textAlign: TextAlign.left,
                text: TextSpan(
                  text: 'Welcome to ',
                  style: TextStyle(
                    fontSize: 22,
                    // fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 10.0,
                        color: Colors.black,
                        offset: Offset(0, 0),
                      ),
                    ],
                  ),
                  children: <TextSpan>[
                    TextSpan(
                      text: 'Remind',
                      style: TextStyle(color: Colors.orange, fontSize: 25),
                    ),
                    TextSpan(
                      text: ' Me',
                      style: TextStyle(color: Colors.orange, fontSize: 25),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Arrow icon at the bottom right
        ],
      ),
    );
  }
}
