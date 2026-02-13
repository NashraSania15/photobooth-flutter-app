import 'package:flutter/material.dart';
import 'camera_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});
//ChoiceChip
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  int stripCount = 3;
  int countdown = 3;

  late AnimationController _controller;
  late Animation<double> fadeAnimation;
  late Animation<double> scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    fadeAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    scaleAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: fadeAnimation,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF1A1A2E),
                Color(0xFF16213E),
                Color(0xFF0F3460),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: ScaleTransition(
              scale: scaleAnimation,
              child: Card(
                color: Colors.white,
                elevation: 15,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 40, vertical: 50),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [

                      const Icon(
                        Icons.camera_alt_rounded,
                        size: 60,
                        color: Colors.deepPurple,
                      ),

                      const SizedBox(height: 15),

                      const Text(
                        "PhotoBooth",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),

                      const SizedBox(height: 40),

                      const Text(
                        "Select Strip Count",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Wrap(
                        spacing: 12,
                        children: [2, 3, 4].map((count) {
                          return ChoiceChip(
                            label: Text(
                              "$count",
                              style: TextStyle(
                                color: stripCount == count ? Colors.white : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            selected: stripCount == count,
                            selectedColor: Colors.deepPurple,
                            backgroundColor: Colors.grey.shade200,
                            labelStyle: TextStyle(
                              color: stripCount == count
                                  ? Colors.white
                                  : Colors.black,
                            ),
                            onSelected: (_) {
                              setState(() => stripCount = count);
                            },
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 35),

                      const Text(
                        "Select Countdown",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Wrap(
                        spacing: 12,
                        children: [3, 5].map((time) {
                          return ChoiceChip(
                            label: Text("${time}s"),
                            selected: countdown == time,
                            selectedColor: Colors.deepPurple,
                            backgroundColor: Colors.grey.shade200,
                            labelStyle: TextStyle(
                              color: countdown == time
                                  ? Colors.white
                                  : Colors.black,
                            ),
                            onSelected: (_) {
                              setState(() => countdown = time);
                            },
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 45),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            padding: const EdgeInsets.symmetric(
                                vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(15),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CameraScreen(
                                  stripCount: stripCount,
                                  countdown: countdown,
                                ),
                              ),
                            );
                          },
                          child: const Text(
                            "Start Booth",
                            style: TextStyle(
                              fontSize: 16,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
