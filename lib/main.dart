import 'package:flutter/material.dart';
import 'package:flutter_zoom_meeting_sdk/flutter_zoom_meeting_sdk.dart';
import 'package:flutter_zoom_meeting_sdk/enums/status_zoom_error.dart';
import 'package:flutter_zoom_meeting_sdk/models/zoom_meeting_sdk_request.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget { 
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final FlutterZoomMeetingSdk _zoomSdk = FlutterZoomMeetingSdk();
  
  // State variables
  bool _isInitialized = false;
  bool _isAuthenticated = false;
  bool _isJoining = false;
  String _status = "Initializing...";

  //extra added for the double click issue of the authentcate button
  bool _authListenerAttached = false;
  //for password visiblity
  bool _isPasswordVisible = false;

  
  // Controllers for user input
  final TextEditingController _meetingIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  String _cleanMeetingId(String rawId) {
    if (rawId.isEmpty) return "";
    
    // Remove all non-digit characters (spaces, dashes, dots, parentheses, etc.)
    return rawId.replaceAll(RegExp(r'[^\d]'), '');
  }
  @override
  void initState() {
    super.initState();
    
    // Initialize SDK once when widget loads
    _initializeSdk();
  }

  Future<void> _initializeSdk() async {
    try {
      setState(() {
        _status = "Initializing Zoom SDK...";
      });
      
      // 1️⃣ Initialize SDK
      await _zoomSdk.initZoom();
      
      setState(() {
        _isInitialized = true;
        _status = "SDK initialized. Ready to authenticate.";
      });
      
      await _authenticate();

    } catch (e) {
      setState(() {
        _status = "Failed to initialize SDK: $e";
      });
    }
  }

  Future<void> _authenticate() async {
    if (!_isInitialized || _isAuthenticated) return;

    setState(() {
      _status = "Authenticating...";
    });

    try {
      // Attach listener ONLY ONCE
      if (!_authListenerAttached) {
        _authListenerAttached = true;

        _zoomSdk.onAuthenticationReturn.listen((event) {
          if (event.params?.statusEnum == StatusZoomError.success) {
            setState(() {
              _isAuthenticated = true;
              _status = "Authentication successful!";
            });
          } else {
            setState(() {
              _status =
                  "Authentication failed (${event.params?.statusEnum})";
            });
          }
        });
      }

      // Now authenticate
      await _zoomSdk.authZoom(
        jwtToken:
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcHBLZXkiOiJ3WVMyQkNDQlNyS3Rxckp1QmltcGciLCJpYXQiOjE3Njc2NTc2MDAsImV4cCI6MTc2ODI2MjM5OSwidG9rZW5FeHAiOjE3NjgyNjIzOTl9.FNIl3FXfRdzJiHMlXFF2HZgPI4jhiWRNysB5jrry_5U",
      );
    } catch (e) {
      setState(() {
        _status = "Auth error: $e";
      });
    }
  }


  Future<void> _joinMeeting() async {
    if (!_isAuthenticated) {
      setState(() {
        _status = "Please authenticate first";
      });
      return;
    }
    
    String rawId = _meetingIdController.text;
    String cleanId = _cleanMeetingId(rawId);

    if (cleanId.isEmpty) {
      setState(() {
        _status = "Please enter valid Meeting ID";
      });
      return;
    }
    
    setState(() {
      _isJoining = true;
      _status = "Joining meeting...";
    });
    
    try {
      // 4️⃣ Join meeting
      await _zoomSdk.joinMeeting(
        ZoomMeetingSdkRequest(
          meetingNumber: cleanId,
          password: _passwordController.text,
          displayName: _nameController.text.isNotEmpty 
              ? _nameController.text 
              : "Guest",
        ),
      );
      
      setState(() {
        _status = "Joining meeting now...";
      });
      
    } catch (e) {
      setState(() {
        _isJoining = false;
        _status = "Failed to join: $e";
      });
    }
  }

  @override
  void dispose() {
    // Cleanup
    _zoomSdk.unInitZoom();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text("Zoom Meeting"),
          backgroundColor: Colors.blue,
        ),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Status Display
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(
                        _isAuthenticated ? Icons.check_circle : 
                        _isInitialized ? Icons.settings : Icons.error,
                        color: _isAuthenticated ? Colors.green : 
                               _isInitialized ? Colors.blue : Colors.red,
                        size: 40,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _status,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Authentication Button (only if initialized but not authenticated)
              // if (_isInitialized && !_isAuthenticated)
              //   ElevatedButton(
              //     onPressed: _authenticate,
              //     style: ElevatedButton.styleFrom(
              //       backgroundColor: Colors.green,
              //       padding: const EdgeInsets.symmetric(vertical: 15),
              //     ),
              //     child: const Text(
              //       "Authenticate Zoom",
              //       style: TextStyle(fontSize: 16),
              //     ),
              //   ),
              
              // const SizedBox(height: 20),
              
              // Meeting Input Form (only if authenticated)
              if (_isAuthenticated) ...[
                TextField(
                  controller: _meetingIdController,
                  decoration: const InputDecoration(
                    labelText: "Meeting ID",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.numbers),
                  ),
                  keyboardType: TextInputType.number,
                ),
                
                const SizedBox(height: 15),

                TextField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible, // 👈 toggle
                  decoration: InputDecoration(
                    labelText: "Meeting Passcode (Optional)",
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                ),

                
                const SizedBox(height: 15),
                
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: "Your Name",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Join Button
                ElevatedButton(
                  onPressed: _isJoining ? null : _joinMeeting,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: _isJoining
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: Colors.white),
                            SizedBox(width: 10),
                            Text("Joining..."),
                          ],
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.video_call),
                            SizedBox(width: 10),
                            Text("Join Meeting"),
                          ],
                        ),
                ),
              ],
              
              // Instructions
              const SizedBox(height: 20),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Instructions:",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text("1. Wait for SDK to initialize"),
                      // Text("2. Click 'Authenticate Zoom'"),
                      Text("2. Enter meeting details"),
                      Text("3. Click 'Join Meeting'"),
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