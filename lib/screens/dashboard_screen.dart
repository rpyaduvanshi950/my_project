// import 'package:flutter/material.dart';
// import '../services/auth_service.dart';
// import '../models/user_model.dart';

// class DashboardScreen extends StatelessWidget {
//   final UserModel user;

//   const DashboardScreen({
//     super.key,
//     required this.user,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final firstName = user.name.split(' ').first;

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Dashboard'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.logout),
//             onPressed: () async {
//               final authService = AuthService();
//               await authService.signOut();
//             },
//             tooltip: 'Sign Out',
//           ),
//         ],
//       ),
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.all(24.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 'Welcome, $firstName!',
//                 style: Theme.of(context).textTheme.headlineMedium?.copyWith(
//                       fontWeight: FontWeight.bold,
//                     ),
//               ),
//               const SizedBox(height: 32),
//               Expanded(
//                 child: GridView.count(
//                   crossAxisCount: 2,
//                   crossAxisSpacing: 16,
//                   mainAxisSpacing: 16,
//                   children: [
//                     _DashboardCard(
//                       icon: Icons.person,
//                       title: 'Profile',
//                       subtitle: 'Edit your profile',
//                       color: Colors.blue,
//                       onTap: () {
//                         Navigator.pushNamed(
//                           context,
//                           '/profile',
//                           arguments: user,
//                         );
//                       },
//                     ),
//                     _DashboardCard(
//                       icon: Icons.people,
//                       title: 'People',
//                       subtitle: 'Manage contacts',
//                       color: Colors.green,
//                       onTap: () {
//                         Navigator.pushNamed(
//                           context,
//                           '/people',
//                           arguments: user,
//                         );
//                       },
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _DashboardCard extends StatelessWidget {
//   final IconData icon;
//   final String title;
//   final String subtitle;
//   final Color color;
//   final VoidCallback onTap;

//   const _DashboardCard({
//     required this.icon,
//     required this.title,
//     required this.subtitle,
//     required this.color,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(12),
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(
//                 icon,
//                 size: 48,
//                 color: color,
//               ),
//               const SizedBox(height: 12),
//               Text(
//                 title,
//                 style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                       fontWeight: FontWeight.bold,
//                     ),
//               ),
//               const SizedBox(height: 4),
//               Text(
//                 subtitle,
//                 style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                       color: Colors.grey[600],
//                     ),
//                 textAlign: TextAlign.center,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class DashboardScreen extends StatelessWidget {
  final UserModel user;

  const DashboardScreen({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final firstName = user.name.split(' ').first;

    return Scaffold(
      extendBodyBehindAppBar: true, // Allows gradient to appear behind appbar
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent, // Makes appbar see-through
        title: Row(
          children: [
            // App Logo
            ClipOval(
              child: Image.asset(
                "assets/images/logo.png",
                height: 36,
                width: 36,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Wish Manager',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: () async {
              final authService = AuthService();
              await authService.signOut();
            },
            tooltip: 'Sign Out',
          ),
        ],
      ),

      // *** PINKISH GRADIENT BACKGROUND ***
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFFFE6F0), // soft peach pink
              Color(0xFFFCE4EC), // gentle rosy tint
              Color(0xFFFFF1F7), // very light pink
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),

        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, $firstName!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                ),
                const SizedBox(height: 28),

                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      _DashboardCard(
                        icon: Icons.person,
                        title: 'Profile',
                        subtitle: 'Edit your profile',
                        color: Colors.blue,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/profile',
                            arguments: user,
                          );
                        },
                      ),
                      _DashboardCard(
                        icon: Icons.people,
                        title: 'People',
                        subtitle: 'Manage contacts',
                        color: Colors.green,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/people',
                            arguments: user,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      color: Colors.white.withOpacity(0.9), // soft touch for gradient bg
      shadowColor: Colors.pink.shade100,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[700],
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
