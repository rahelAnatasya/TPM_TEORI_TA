import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/session_manager.dart';
import '../services/transaction_service.dart';
import '../models/transaction.dart';
import '../services/currency_service.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  final VoidCallback? onProfileUpdated;

  const ProfilePage({super.key, this.onProfileUpdated});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  User? _currentUser;
  final SessionManager _sessionManager = SessionManager();
  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();

  // Transaction related variables
  List<Transaction> _transactions = [];
  bool _isLoadingTransactions = false;
  bool _isLoadingUser = false;
  double _totalSpending = 0.0;
  int _transactionCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  // Combine both data loading methods to avoid race conditions
  Future<void> _initializeData() async {
    setState(() {
      _isLoadingUser = true;
      _isLoadingTransactions = true;
    });

    try {
      await _loadUserData();
      await _loadTransactionHistory();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _loadUserData() async {
    try {
      String? userEmail = await _sessionManager.getEmail();
      if (userEmail != null) {
        final user = await _authService.getUserByEmail(userEmail);
        if (mounted) {
          setState(() {
            _currentUser = user;
            _isLoadingUser = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoadingUser = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingUser = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat data pengguna: ${e.toString()}'),
          ),
        );
      }
    }
  }

  Future<void> _loadTransactionHistory() async {
    if (!mounted) return;

    setState(() {
      _isLoadingTransactions = true;
    });

    try {
      String? userEmail = await _sessionManager.getEmail();
      if (userEmail != null) {
        final transactions = await TransactionService.getTransactionsByUser(
          userEmail,
        );
        final total = await TransactionService.getTotalSpendingByUser(
          userEmail,
        );
        final count = await TransactionService.getTransactionCountByUser(
          userEmail,
        );

        if (mounted) {
          setState(() {
            _transactions = transactions.cast<Transaction>();
            _totalSpending = total;
            _transactionCount = count;
            _isLoadingTransactions = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoadingTransactions = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingTransactions = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat riwayat transaksi: ${e.toString()}'),
          ),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      // Show dialog to choose between camera and gallery
      final ImageSource? source = await showDialog<ImageSource>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Pilih Sumber Foto'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: Colors.blue),
                  title: const Text('Kamera'),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: Colors.green),
                  title: const Text('Galeri'),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
            ],
          );
        },
      );

      if (source != null) {
        final XFile? image = await _picker.pickImage(
          source: source,
          imageQuality: 80, // Compress image quality
          maxWidth: 800, // Limit image width
          maxHeight: 800, // Limit image height
        );

        if (image != null && _currentUser != null) {
          // Update user profile picture path
          final updatedUser = User(
            id: _currentUser!.id,
            username: _currentUser!.username,
            email: _currentUser!.email,
            password: _currentUser!.password,
            profilePicturePath: image.path,
          );

          await _authService.updateUser(updatedUser);
          if (mounted) {
            setState(() {
              _currentUser = updatedUser;
            });

            // Call the callback to update parent widget
            widget.onProfileUpdated?.call();

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Foto profil berhasil diperbarui')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui foto profil: ${e.toString()}'),
          ),
        );
      }
    }
  }

  void _logout() async {
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await _sessionManager.clearUserSession();
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
            (Route<dynamic> route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error during logout: ${e.toString()}')),
          );
        }
      }
    }
  }

  ImageProvider? _getProfileImage() {
    try {
      if (_currentUser?.profilePicturePath != null &&
          _currentUser!.profilePicturePath!.isNotEmpty) {
        final file = File(_currentUser!.profilePicturePath!);
        if (file.existsSync()) {
          return FileImage(file);
        }
      }
    } catch (e) {
      print('Error loading profile image: $e');
    }
    return const NetworkImage('https://via.placeholder.com/150');
  }

  Future<void> _editProfile() async {
    if (_currentUser == null) return;

    final usernameController = TextEditingController(
      text: _currentUser!.username,
    );
    final emailController = TextEditingController(text: _currentUser!.email);
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    bool changePassword = false;

    bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Profil'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Checkbox(
                          value: changePassword,
                          onChanged: (value) {
                            setDialogState(() {
                              changePassword = value ?? false;
                              if (!changePassword) {
                                oldPasswordController.clear();
                                newPasswordController.clear();
                                confirmPasswordController.clear();
                              }
                            });
                          },
                        ),
                        const Text('Ubah Password'),
                      ],
                    ),
                    if (changePassword) ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: oldPasswordController,
                        decoration: const InputDecoration(
                          labelText: 'Password Lama',
                          border: OutlineInputBorder(),
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: newPasswordController,
                        decoration: const InputDecoration(
                          labelText: 'Password Baru',
                          border: OutlineInputBorder(),
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: confirmPasswordController,
                        decoration: const InputDecoration(
                          labelText: 'Konfirmasi Password Baru',
                          border: OutlineInputBorder(),
                        ),
                        obscureText: true,
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true) {
      // Store controller values before any async operations
      final newUsername = usernameController.text.trim();
      final newEmail = emailController.text.trim();
      final oldPassword = oldPasswordController.text;
      final newPassword = newPasswordController.text;
      final confirmPassword = confirmPasswordController.text;

      try {
        // Validation
        if (newUsername.isEmpty) {
          throw Exception('Username tidak boleh kosong');
        }
        if (newEmail.isEmpty) {
          throw Exception('Email tidak boleh kosong');
        }
        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(newEmail)) {
          throw Exception('Format email tidak valid');
        }

        if (changePassword) {
          if (oldPassword.isEmpty ||
              newPassword.isEmpty ||
              confirmPassword.isEmpty) {
            throw Exception('Semua field password harus diisi');
          }
          if (newPassword != confirmPassword) {
            throw Exception('Konfirmasi password tidak sesuai');
          }
          if (newPassword.length < 6) {
            throw Exception('Password baru minimal 6 karakter');
          }

          // Verify old password
          bool isOldPasswordValid = await _authService.verifyPassword(
            _currentUser!.id!,
            oldPassword,
          );
          if (!isOldPasswordValid) {
            throw Exception('Password lama tidak benar');
          }
        }

        // Check if username or email changed and if they're available
        if (newUsername != _currentUser!.username) {
          // Check if new username is taken by another user
          try {
            final existingUser = await _authService.getUserByEmail(newUsername);
            if (existingUser != null && existingUser.id != _currentUser!.id) {
              throw Exception('Username sudah digunakan');
            }
          } catch (e) {
            // If getUserByEmail throws an error, it means the username doesn't exist, which is good
          }
        }

        if (newEmail != _currentUser!.email) {
          // Check if new email is taken by another user
          final existingUser = await _authService.getUserByEmail(newEmail);
          if (existingUser != null && existingUser.id != _currentUser!.id) {
            throw Exception('Email sudah digunakan');
          }
        }

        // Update user data
        final updatedUser = User(
          id: _currentUser!.id,
          username: newUsername,
          email: newEmail,
          password: _currentUser!.password, // Keep the old password for now
          profilePicturePath: _currentUser!.profilePicturePath,
        );

        await _authService.updateUser(updatedUser);

        // Update password if requested
        if (changePassword) {
          await _authService.updatePassword(_currentUser!.id!, newPassword);
        }

        // Update session email if email changed
        if (newEmail != _currentUser!.email) {
          await _sessionManager.saveUserSession(
            isLoggedIn: true,
            email: newEmail,
          );
        }

        if (mounted) {
          setState(() {
            _currentUser = updatedUser;
          });

          // Call the callback to update parent widget
          widget.onProfileUpdated?.call();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profil berhasil diperbarui')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal memperbarui profil: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

    // Dispose controllers
    usernameController.dispose();
    emailController.dispose();
    oldPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          _isLoadingUser
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _initializeData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Header
                      Card(
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: _pickImage,
                                child: Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 40,
                                      backgroundImage: _getProfileImage(),
                                      child:
                                          _currentUser?.profilePicturePath ==
                                                      null ||
                                                  _currentUser!
                                                      .profilePicturePath!
                                                      .isEmpty
                                              ? const Icon(
                                                Icons.person,
                                                size: 40,
                                              )
                                              : null,
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.blue,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 2,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.camera_alt,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            _currentUser?.username ??
                                                'Loading...',
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          onPressed:
                                              _currentUser != null
                                                  ? _editProfile
                                                  : null,
                                          icon: const Icon(Icons.edit),
                                          tooltip: 'Edit Profil',
                                          iconSize: 20,
                                        ),
                                      ],
                                    ),
                                    Text(
                                      _currentUser?.email ?? 'Loading...',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ElevatedButton(
                                      onPressed: _logout,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('Logout'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Transaction Statistics
                      Card(
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.analytics,
                                    color: Colors.green[700],
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Statistik Pembelian',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      children: [
                                        Text(
                                          '$_transactionCount',
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                          ),
                                        ),
                                        const Text('Total Transaksi'),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      children: [
                                        Text(
                                          CurrencyService.formatCurrency(
                                            _totalSpending,
                                            'IDR',
                                          ),
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.orange,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const Text('Total Pengeluaran'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Transaction History Header
                      Row(
                        children: [
                          Icon(Icons.history, color: Colors.blue[700]),
                          const SizedBox(width: 8),
                          Text(
                            'Riwayat Transaksi',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: _loadTransactionHistory,
                            tooltip: 'Refresh',
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Transaction List
                      if (_isLoadingTransactions)
                        const Center(child: CircularProgressIndicator())
                      else if (_transactions.isEmpty)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.shopping_cart_outlined,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Belum ada transaksi',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Mulai berbelanja untuk melihat riwayat transaksi',
                                  style: TextStyle(color: Colors.grey[500]),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _transactions.length,
                          itemBuilder: (context, index) {
                            final transaction = _transactions[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.green[100],
                                  backgroundImage:
                                      transaction.plantImageUrl != null &&
                                              transaction
                                                  .plantImageUrl!
                                                  .isNotEmpty
                                          ? NetworkImage(
                                            transaction.plantImageUrl!,
                                          )
                                          : null,
                                  child:
                                      transaction.plantImageUrl == null ||
                                              transaction.plantImageUrl!.isEmpty
                                          ? Icon(
                                            Icons.local_florist,
                                            color: Colors.green[700],
                                          )
                                          : null,
                                ),
                                title: Text(
                                  transaction.plantName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Jumlah: ${transaction.quantity}'),
                                    Text(
                                      'Harga satuan: ${CurrencyService.formatCurrency(transaction.price, transaction.currency)}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      'Tanggal: ${DateFormat('dd MMM yyyy, HH:mm').format(transaction.transactionDate)}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      CurrencyService.formatCurrency(
                                        transaction.totalAmount,
                                        transaction.currency,
                                      ),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green[700],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green[100],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        transaction.status.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.green[700],
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
    );
  }
}
