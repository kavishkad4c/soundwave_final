 import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/device_service.dart';
import 'settings_screen.dart';
import 'data_demo_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final DeviceService _deviceService = DeviceService();
  final ImagePicker _picker = ImagePicker();
  final _supabase = Supabase.instance.client;
  File? _profileImage;
  int _batteryLevel = 100;
  String _connectionStatus = 'Checking...';

  User? get _currentUser => _supabase.auth.currentUser;

  Future<void> _signOut() async {
    await _deviceService.vibrateMedium();
    await _supabase.auth.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeDeviceInfo();
    _listenToConnectivity();
    _listenToBattery();
  }

  Future<void> _initializeDeviceInfo() async {
    final connectivity = await _deviceService.checkConnectivity();
    final batteryLevel = await _deviceService.getBatteryLevel();
    
    if (mounted) {
      setState(() {
        _connectionStatus = _deviceService.getConnectionType(connectivity);
        _batteryLevel = batteryLevel;
      });
    }
  }

  void _listenToConnectivity() {
    _deviceService.connectivityStream.listen((result) {
      if (mounted) {
        setState(() {
          _connectionStatus = _deviceService.getConnectionType(result);
        });
      }
    });
  }

  void _listenToBattery() {
    _deviceService.batteryStateStream.listen((state) async {
      final level = await _deviceService.getBatteryLevel();
      if (mounted) {
        setState(() {
          _batteryLevel = level;
        });
      }
    });
  }

  Future<void> _pickImageFromCamera() async {
    await _deviceService.vibrateLight();
    
    // Ask for camera permission
    final status = await Permission.camera.request();
    
    if (status.isGranted) {
      try {
        final XFile? image = await _picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 512,
          maxHeight: 512,
          imageQuality: 85,
        );
        
        if (image != null) {
          await _deviceService.vibrateSuccess();
          setState(() {
            _profileImage = File(image.path);
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile picture updated!'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      } catch (e) {
        await _deviceService.vibrateError();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      await _deviceService.vibrateError();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Camera permission denied'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    await _deviceService.vibrateLight();
    
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      
      if (image != null) {
        await _deviceService.vibrateSuccess();
        setState(() {
          _profileImage = File(image.path);
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile picture updated!'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      await _deviceService.vibrateError();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImageSourceDialog() async {
    await _deviceService.vibrateLight();
    
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromCamera();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromGallery();
                },
              ),
              if (_profileImage != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Remove Photo', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    _deviceService.vibrateLight();
                    setState(() {
                      _profileImage = null;
                    });
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Device info banner
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _connectionStatus.contains('WiFi') 
                              ? Icons.wifi 
                              : _connectionStatus.contains('Mobile') 
                                  ? Icons.signal_cellular_alt 
                                  : Icons.wifi_off,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _connectionStatus,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(
                          _batteryLevel > 20 
                              ? Icons.battery_std 
                              : Icons.battery_alert,
                          size: 20,
                          color: _batteryLevel <= 20 ? Colors.red : null,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$_batteryLevel%',
                          style: TextStyle(
                            fontSize: 12,
                            color: _batteryLevel <= 20 ? Colors.red : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Low battery warning (only shown when the battery is low)
            if (_batteryLevel <= 20)
              Card(
                color: Colors.orange.shade100,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.battery_alert,
                        color: Colors.orange.shade900,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Low Battery Warning!',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.orange.shade900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Your battery is at $_batteryLevel%. Consider charging your device before making purchases.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (_batteryLevel <= 20) const SizedBox(height: 12),

            // Profile header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        GestureDetector(
                          onTap: _showImageSourceDialog,
                          child: Tooltip(
                            message: 'Change profile picture',
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.blue,
                              backgroundImage: _profileImage != null 
                                  ? FileImage(_profileImage!) 
                                  : null,
                              child: _profileImage == null
                                  ? const Icon(Icons.person, size: 50, color: Colors.white)
                                  : null,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _showImageSourceDialog,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                size: 20,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap to change photo',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _currentUser?.userMetadata?['full_name'] ?? 'User',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currentUser?.email ?? 'user@email.com',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildProfileStat('12', 'Orders'),
                        _buildProfileStat('5', 'Wishlist'),
                        _buildProfileStat('2', 'Coupons'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Menu items
            Card(
              child: Column(
                children: [
                  _buildMenuTile(
                    context,
                    Icons.shopping_bag,
                    'My Orders',
                    Icons.arrow_forward_ios,
                    () async {
                      await _deviceService.vibrateLight();
                    },
                  ),
                  _buildMenuTile(
                    context,
                    Icons.favorite,
                    'My Wishlist',
                    Icons.arrow_forward_ios,
                    () async {
                      await _deviceService.vibrateLight();
                    },
                  ),
                  _buildMenuTile(
                    context,
                    Icons.location_on,
                    'Shipping Address',
                    Icons.arrow_forward_ios,
                    () async {
                      await _deviceService.vibrateLight();
                    },
                  ),
                  _buildMenuTile(
                    context,
                    Icons.payment,
                    'Payment Methods',
                    Icons.arrow_forward_ios,
                    () async {
                      await _deviceService.vibrateLight();
                    },
                  ),
                  _buildMenuTile(
                    context,
                    Icons.rate_review,
                    'Leave Feedback',
                    Icons.arrow_forward_ios,
                    () async {
                      await _deviceService.vibrateMedium();
                      _showFeedbackDialog();
                    },
                  ),
                  _buildMenuTile(
                    context,
                    Icons.data_usage,
                    'Data Source Demo',
                    Icons.arrow_forward_ios,
                    () async {
                      await _deviceService.vibrateLight();
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const DataDemoScreen()),
                      );
                    },
                  ),
                  _buildMenuTile(
                    context,
                    Icons.settings,
                    'Settings',
                    Icons.arrow_forward_ios,
                    () async {
                      await _deviceService.vibrateLight();
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SettingsScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Haptic test buttons
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.vibration,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Haptic Feedback Test',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Test different vibration patterns:',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () async {
                            await _deviceService.vibrateLight();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Light vibration ✓'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          icon: const Icon(Icons.touch_app, size: 16),
                          label: const Text('Light'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () async {
                            await _deviceService.vibrateMedium();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Medium vibration ✓'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          icon: const Icon(Icons.vibration, size: 16),
                          label: const Text('Medium'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () async {
                            await _deviceService.vibrateSuccess();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Success pattern ✓✓'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          icon: const Icon(Icons.check_circle, size: 16),
                          label: const Text('Success'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Log out button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _signOut,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Logout'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFeedbackDialog() async {
    await _deviceService.vibrateLight();
    final TextEditingController feedbackController = TextEditingController();
    int rating = 0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.rate_review, color: Colors.blue),
              SizedBox(width: 8),
              Text('Leave Feedback'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Rate your experience:'),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 32,
                      ),
                      onPressed: () async {
                        await _deviceService.vibrateLight();
                        setState(() {
                          rating = index + 1;
                        });
                      },
                    );
                  }),
                ),
                const SizedBox(height: 16),
                const Text('Your feedback:'),
                const SizedBox(height: 8),
                TextField(
                  controller: feedbackController,
                  decoration: const InputDecoration(
                    hintText: 'Tell us about your experience...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 4,
                  onTap: () async {
                    await _deviceService.vibrateLight();
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await _deviceService.vibrateLight();
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (rating > 0) {
                  await _deviceService.vibrateSuccess();
                  Navigator.pop(context);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Thank you for your $rating-star feedback! ⭐'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } else {
                  await _deviceService.vibrateError();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select a rating'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildMenuTile(BuildContext context, IconData leadingIcon, String title,
      IconData trailingIcon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(leadingIcon),
      title: Text(title),
      trailing: Icon(trailingIcon, size: 16),
      onTap: onTap,
    );
  }
}
