import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/tour/tour_overlay_controller.dart';
import '../../core/tour/tour_step.dart';
import '../../core/widgets/offline_banner.dart';
import '../../providers/auth_provider.dart';
import '../../providers/connectivity_provider.dart';
import '../../providers/tour_provider.dart';
import '../../services/tour_service.dart';
import '../contacts/contacts_screen.dart';
import '../history/call_history_screen.dart';
import '../profile/profile_screen.dart';
import 'home_tab.dart';

/// The bottom-nav shell that holds the app's four main sections.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  final _startCallKey = GlobalKey();
  final _groupCallKey = GlobalKey();
  final _recentContactsKey = GlobalKey();
  final _contactsTabKey = GlobalKey();
  final _callsTabKey = GlobalKey();
  final _profileTabKey = GlobalKey();
  final _appearanceKey = GlobalKey();
  final _blockedUsersKey = GlobalKey();

  TourOverlayController? _tour;
  bool _tourChecked = false;

  void _goToTab(int index) => setState(() => _currentIndex = index);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_tourChecked) {
      _tourChecked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeStartTour());
    }
  }

  Future<void> _maybeStartTour() async {
    final uid = ref.read(authStateProvider).value?.uid;
    if (uid == null || !mounted) {
      TourGate.resolvePending();
      return;
    }
    final tourService = ref.read(tourServiceProvider);
    final alreadyCompleted = await tourService.hasCompletedTour(uid);
    if (alreadyCompleted || !mounted) {
      TourGate.resolvePending();
      return;
    }

    final steps = [
      TourStep(
        key: _startCallKey,
        tabIndex: 0,
        icon: Icons.call_rounded,
        title: 'Start a Call',
        description: 'Tap here to quickly start an audio or video call.',
      ),
      TourStep(
        key: _groupCallKey,
        tabIndex: 0,
        icon: Icons.groups_rounded,
        title: 'Group Calls',
        description:
            'Choose multiple contacts to start a group audio or video call.',
      ),
      TourStep(
        key: _recentContactsKey,
        tabIndex: 0,
        icon: Icons.history_rounded,
        title: 'Recent Contacts',
        description: 'Quickly call people you contact frequently.',
      ),
      TourStep(
        key: _contactsTabKey,
        tabIndex: 0,
        icon: Icons.people_alt_rounded,
        title: 'Contacts',
        description: 'Find people and start a call from your contacts.',
      ),
      TourStep(
        key: _callsTabKey,
        tabIndex: 0,
        icon: Icons.phone_in_talk_rounded,
        title: 'Call History',
        description: 'See your previous calls in one place.',
      ),
      TourStep(
        key: _profileTabKey,
        tabIndex: 0,
        icon: Icons.person_rounded,
        title: 'Profile & Settings',
        description: 'Manage your profile, appearance and privacy settings.',
      ),
      TourStep(
        key: _appearanceKey,
        tabIndex: 3,
        icon: Icons.palette_rounded,
        title: 'Appearance',
        description: 'Switch between System, Light and Dark themes anytime.',
      ),
      TourStep(
        key: _blockedUsersKey,
        tabIndex: 3,
        icon: Icons.block_rounded,
        title: 'Blocked Users',
        description: 'Manage who can reach you from your privacy settings.',
      ),
    ];

    _tour = TourOverlayController(
      steps: steps,
      onGoToTab: _goToTab,
      onFinish: () => _completeTour(uid),
      onSkip: () => _completeTour(uid),
    );
    TourGate.start();
    _tour!.start(context);
  }

  Future<void> _completeTour(String uid) async {
    await ref.read(tourServiceProvider).markTourCompleted(uid);
    TourGate.finish();
    if (mounted) _goToTab(0);
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      HomeTab(
        onGoToContacts: () => _goToTab(1),
        startCallKey: _startCallKey,
        groupCallKey: _groupCallKey,
        recentContactsKey: _recentContactsKey,
      ),
      const ContactsScreen(),
      const CallHistoryScreen(),
      ProfileScreen(
        appearanceKey: _appearanceKey,
        blockedUsersKey: _blockedUsersKey,
      ),
    ];

    final isOnline = ref.watch(isOnlineProvider).value ?? true;

    return Scaffold(
      body: Column(
        children: [
          if (!isOnline) const OfflineBanner(),
          Expanded(
            child: IndexedStack(index: _currentIndex, children: tabs),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline, key: _contactsTabKey),
            activeIcon: Icon(Icons.people),
            label: 'Contacts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.call_outlined, key: _callsTabKey),
            activeIcon: Icon(Icons.call),
            label: 'Calls',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline, key: _profileTabKey),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
