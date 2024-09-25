import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.orange[300]!, Colors.orange[700]!],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(Icons.arrow_back, color: Colors.white),
                    Icon(Icons.more_vert, color: Colors.white),
                  ],
                ),
              ),
              CircleAvatar(
                radius: 50,
                backgroundImage: AssetImage('assets/profile_image.jpg'),
              ),
              SizedBox(height: 16),
              Text(
                'Joshua Doherty',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              Text(
                'Mobile Developer',
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_on, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text('Kyabram, VIC', style: TextStyle(color: Colors.white)),
                ],
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatColumn('Profile views', '3,457'),
                  _buildStatColumn('Followers', '1,234'),
                  _buildStatColumn('Following', '234'),
                ],
              ),
              SizedBox(height: 24),
              Text(
                'Where else to find me',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildSocialIcon(Icons.facebook),
                  SizedBox(width: 16),
                  _buildSocialIcon(Icons.flutter_dash),
                  SizedBox(width: 16),
                  _buildSocialIcon(Icons.link),
                      
                ],
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {},
                    child: Text('FOLLOW'),
                    style: ElevatedButton.styleFrom(
                        iconColor: Colors.white, shadowColor: Colors.orange),
                  ),
                  ElevatedButton(
                    onPressed: () {},
                    child: Text('MESSAGE'),
                    style: ElevatedButton.styleFrom(
                        iconColor: Colors.white, shadowColor: Colors.orange),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        Text(label, style: TextStyle(color: Colors.white70)),
      ],
    );
  }

  Widget _buildSocialIcon(IconData icon) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
      ),
      child: Icon(icon, color: Colors.orange),
    );
  }
}
