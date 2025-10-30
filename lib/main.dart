import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final firebaseReady = await _initializeFirebase();
  final repository = AirdropRepository(
    firebaseReady ? FirebaseFirestore.instance : null,
  );

  runApp(GiftDropApp(
    repository: repository,
    firebaseReady: firebaseReady,
  ));
}

Future<bool> _initializeFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    return true;
  } on FirebaseException catch (error, stackTrace) {
    // Firebase is optional during development; fall back to sample data.
    debugPrint('Firebase initialization failed: ${error.message}\n$stackTrace');
    return false;
  } catch (error, stackTrace) {
    debugPrint('Unexpected error initializing Firebase: $error\n$stackTrace');
    return false;
  }
}

class GiftDropApp extends StatelessWidget {
  const GiftDropApp({
    super.key,
    required this.repository,
    required this.firebaseReady,
  });

  final AirdropRepository repository;
  final bool firebaseReady;

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFFFFF8E1);
    const surface = Color(0xFFFFFDED);
    const primary = Color(0xFF1818DD);
    const secondary = Color(0xFF00C2A8);

    final textTheme = GoogleFonts.spaceGroteskTextTheme();

    return MaterialApp(
      title: 'GIFTDROP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          primary: primary,
          secondary: secondary,
          surface: surface,
          background: background,
          onPrimary: Colors.white,
          onSecondary: Colors.black,
          onSurface: Colors.black,
        ),
        textTheme: textTheme.copyWith(
          displayLarge: textTheme.displayLarge?.copyWith(fontWeight: FontWeight.w800),
          titleLarge: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          bodyLarge: textTheme.bodyLarge?.copyWith(height: 1.4),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: background,
          foregroundColor: Colors.black,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: textTheme.headlineSmall?.copyWith(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
            color: Colors.black,
          ),
        ),
        tabBarTheme: TabBarThemeData(
          labelStyle: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          unselectedLabelStyle: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
      ),
      home: GiftDropHome(
        repository: repository,
        firebaseReady: firebaseReady,
      ),
    );
  }
}

class GiftDropHome extends StatelessWidget {
  const GiftDropHome({
    super.key,
    required this.repository,
    required this.firebaseReady,
  });

  final AirdropRepository repository;
  final bool firebaseReady;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notice = firebaseReady
        ? null
        : Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: _NeubrutalBanner(
              icon: Icons.wifi_off_rounded,
              message:
                  'Firebase is not configured yet. Showing sample airdrop data. Configure Firebase to publish live updates.',
              accentColor: theme.colorScheme.secondary,
            ),
          );

    return DefaultTabController(
      length: AirdropCategory.values.length,
      child: Scaffold(
        backgroundColor: theme.colorScheme.background,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(132),
          child: AppBar(
            toolbarHeight: 84,
            titleSpacing: 24,
            title: const Text('GIFTDROP'),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 24),
                child: _IconNeubButton(
                  icon: Icons.menu_rounded,
                  tooltip: 'Navigation menu',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Navigation menu coming soon.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(64),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: _GiftDropTabBar(theme: theme),
              ),
            ),
          ),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (notice != null) notice,
            Expanded(
              child: TabBarView(
                children: [
                  for (final category in AirdropCategory.values)
                    AirdropListView(
                      category: category,
                      repository: repository,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GiftDropTabBar extends StatelessWidget {
  const _GiftDropTabBar({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            offset: Offset(5, 5),
            blurRadius: 0,
          ),
        ],
      ),
      child: TabBar(
        labelColor: Colors.white,
        unselectedLabelColor: Colors.black,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black, width: 2),
          boxShadow: const [
            BoxShadow(
              color: Colors.black,
              offset: Offset(4, 4),
              blurRadius: 0,
            ),
          ],
        ),
        tabs: [
          for (final category in AirdropCategory.values)
            Tab(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                child: Text(
                  category.label.toUpperCase(),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class AirdropListView extends StatefulWidget {
  const AirdropListView({
    super.key,
    required this.category,
    required this.repository,
  });

  final AirdropCategory category;
  final AirdropRepository repository;

  @override
  State<AirdropListView> createState() => _AirdropListViewState();
}

class _AirdropListViewState extends State<AirdropListView> {
  late Future<List<Airdrop>> _airdropsFuture;

  @override
  void initState() {
    super.initState();
    _airdropsFuture = widget.repository.loadCategory(widget.category);
  }

  Future<void> _refresh() async {
    setState(() {
      _airdropsFuture = widget.repository.loadCategory(widget.category);
    });
    await _airdropsFuture;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      color: Theme.of(context).colorScheme.primary,
      child: FutureBuilder<List<Airdrop>>(
        future: _airdropsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              children: [
                const SizedBox(height: 160),
                Center(
                  child: _NeubrutalLoader(label: 'Loading ${widget.category.label}...'),
                ),
              ],
            );
          }

          if (snapshot.hasError) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              children: [
                _NeubrutalBanner(
                  icon: Icons.error_outline,
                  message: 'Could not load ${widget.category.label} airdrops. Pull to refresh.',
                  accentColor: Colors.deepOrangeAccent,
                ),
              ],
            );
          }

          final items = snapshot.data ?? const <Airdrop>[];

          if (items.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              children: [
                _NeubrutalBanner(
                  icon: Icons.inbox_outlined,
                  message: 'No airdrops found yet. Pull to refresh or add new entries in Firebase.',
                  accentColor: Theme.of(context).colorScheme.secondary,
                ),
              ],
            );
          }

          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final airdrop = items[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: AirdropCard(
                  airdrop: airdrop,
                  onJoinPressed: () => _launchJoinUrl(context, airdrop.joinUrl),
                  onHowToJoinPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AirdropDetailPage(airdrop: airdrop),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class AirdropCard extends StatelessWidget {
  const AirdropCard({
    super.key,
    required this.airdrop,
    required this.onJoinPressed,
    required this.onHowToJoinPressed,
  });

  final Airdrop airdrop;
  final VoidCallback onJoinPressed;
  final VoidCallback onHowToJoinPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.black, width: 2.5),
        boxShadow: const [
          BoxShadow(color: Colors.black, offset: Offset(7, 7)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      airdrop.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      airdrop.description ?? 'Exclusive community drop with curated rewards and clear entry rules.',
                      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[800]),
                    ),
                  ],
                ),
              ),
              _StatusPill(label: airdrop.category.label, color: airdrop.category.accentColor),
            ],
          ),
          const SizedBox(height: 20),
          _InfoRow(
            label: 'Reward Pool',
            value: airdrop.amountLabel,
            icon: Icons.card_giftcard,
          ),
          if (airdrop.network != null) ...[
            const SizedBox(height: 12),
            _InfoRow(
              label: 'Network',
              value: airdrop.network!,
              icon: Icons.hub_outlined,
            ),
          ],
          if (airdrop.deadlineLabel != null) ...[
            const SizedBox(height: 12),
            _InfoRow(
              label: 'Deadline',
              value: airdrop.deadlineLabel!,
              icon: Icons.calendar_month,
            ),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _NeubrutalButton(
                  label: 'Join Now',
                  icon: Icons.arrow_outward_rounded,
                  backgroundColor: theme.colorScheme.secondary,
                  foregroundColor: Colors.black,
                  onPressed: onJoinPressed,
                ),
              ),
              const SizedBox(width: 16),
              _NeubrutalLinkButton(
                label: 'How to join?',
                onPressed: onHowToJoinPressed,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AirdropDetailPage extends StatelessWidget {
  const AirdropDetailPage({super.key, required this.airdrop});

  final Airdrop airdrop;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: Text(airdrop.name.toUpperCase()),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.black, width: 2.5),
              boxShadow: const [
                BoxShadow(color: Colors.black, offset: Offset(7, 7)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  airdrop.amountLabel,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  airdrop.description ?? 'Complete the steps below to qualify for the reward pool.',
                  style: theme.textTheme.bodyLarge,
                ),
                if (airdrop.deadlineLabel != null) ...[
                  const SizedBox(height: 16),
                  _InfoRow(
                    label: 'Deadline',
                    value: airdrop.deadlineLabel!,
                    icon: Icons.calendar_month,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'How to join',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          ...airdrop.requirements.map(
            (step) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _NeubrutalChecklistItem(text: step),
            ),
          ),
          const SizedBox(height: 32),
          _NeubrutalButton(
            label: 'Join Now',
            icon: Icons.arrow_outward_rounded,
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: Colors.white,
            onPressed: () => _launchJoinUrl(context, airdrop.joinUrl),
          ),
        ],
      ),
    );
  }
}

class AirdropRepository {
  AirdropRepository(this._firestore);

  final FirebaseFirestore? _firestore;

  Future<List<Airdrop>> loadCategory(AirdropCategory category) async {
    final fallback = _sampleAirdrops
        .where((airdrop) => airdrop.category == category)
        .toList();

    if (_firestore == null) {
      return fallback;
    }

    try {
    final snapshot = await _firestore
          .collection('airdrops')
          .where('category', isEqualTo: category.name)
          .orderBy('priority', descending: true)
          .get();

      if (snapshot.docs.isEmpty) {
        return fallback;
      }

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Airdrop.fromJson(doc.id, data);
      }).toList();
    } on FirebaseException catch (error) {
      debugPrint('Failed to load ${category.name} from Firestore: ${error.message}');
      return fallback;
    } catch (error) {
      debugPrint('Unexpected error loading ${category.name}: $error');
      return fallback;
    }
  }
}

enum AirdropCategory { featured, latest, ended }

extension AirdropCategoryLabel on AirdropCategory {
  String get label {
    switch (this) {
      case AirdropCategory.featured:
        return 'Featured';
      case AirdropCategory.latest:
        return 'Latest';
      case AirdropCategory.ended:
        return 'Ended';
    }
  }

  Color get accentColor {
    switch (this) {
      case AirdropCategory.featured:
        return const Color(0xFF0D47A1);
      case AirdropCategory.latest:
        return const Color(0xFF1B5E20);
      case AirdropCategory.ended:
        return const Color(0xFFB71C1C);
    }
  }

}

AirdropCategory parseAirdropCategory(String? value) {
  return AirdropCategory.values.firstWhere(
    (category) => category.name.toLowerCase() == value?.toLowerCase(),
    orElse: () => AirdropCategory.latest,
  );
}

class Airdrop {
  const Airdrop({
    required this.id,
    required this.name,
    required this.amountUsdt,
    required this.category,
    required this.joinUrl,
    required this.requirements,
    this.description,
    this.network,
    this.deadline,
  });

  factory Airdrop.fromJson(String id, Map<String, dynamic> json) {
    return Airdrop(
      id: id,
      name: json['name'] as String? ?? 'Untitled Airdrop',
      amountUsdt: (json['amountUsdt'] as num?)?.toDouble() ??
          (json['amount_usdt'] as num?)?.toDouble() ??
          0,
  category: parseAirdropCategory(json['category'] as String?),
      joinUrl: json['joinUrl'] as String? ?? json['join_url'] as String? ?? '',
      requirements: (json['requirements'] as List?)
              ?.whereType<String>()
              .toList() ??
          const <String>[],
      description: json['description'] as String?,
      network: json['network'] as String?,
      deadline: _parseDeadline(json['deadline']),
    );
  }

  final String id;
  final String name;
  final double amountUsdt;
  final AirdropCategory category;
  final String joinUrl;
  final List<String> requirements;
  final String? description;
  final String? network;
  final DateTime? deadline;

  String get amountLabel {
    final formatted = amountUsdt % 1 == 0
        ? amountUsdt.toStringAsFixed(0)
        : amountUsdt.toStringAsFixed(2);
    return '$formatted USDT';
  }

  String? get deadlineLabel {
    if (deadline == null) {
      return null;
    }
    return '${deadline!.year}-${deadline!.month.toString().padLeft(2, '0')}-${deadline!.day.toString().padLeft(2, '0')}';
  }

  static DateTime? _parseDeadline(dynamic raw) {
    if (raw == null) {
      return null;
    }
    if (raw is Timestamp) {
      return raw.toDate();
    }
    if (raw is String) {
      return DateTime.tryParse(raw);
    }
    return null;
  }
}

final List<Airdrop> _sampleAirdrops = [
  Airdrop(
    id: 'galaxy-gift',
    name: 'Galaxy Gift Drop',
    amountUsdt: 1200,
    category: AirdropCategory.featured,
    joinUrl: 'https://example.com/airdrops/galaxy-gift',
    description: 'Top community members share a 1,200 USDT prize pool for supporting Galaxy ecosystems.',
    network: 'Arbitrum',
    deadline: DateTime.utc(2025, 11, 30),
    requirements: [
      'Hold at least 250 GALX in your wallet.',
      'Stake GALX in the loyalty vault for 14 days.',
      'Submit your wallet address via the Galaxy Airdrop portal.',
      'Complete the partner quests in the campaign dashboard.',
    ],
  ),
  Airdrop(
    id: 'aurora-wave',
    name: 'Aurora Wave',
    amountUsdt: 800,
    category: AirdropCategory.latest,
    joinUrl: 'https://example.com/airdrops/aurora-wave',
    description: 'Boost Aurora network adoption with a gamified quest and share the wave rewards.',
    network: 'NEAR',
    deadline: DateTime.utc(2025, 10, 12),
    requirements: [
      'Bridge any asset to Aurora using the official bridge.',
      'Provide liquidity to the WNEAR-AURORA pool on Trisolaris.',
      'Complete KYC Level 1 on the Aurora Quest hub.',
      'Submit proof-of-liquidity transaction hash in the dashboard.',
    ],
  ),
  Airdrop(
    id: 'zenith-legends',
    name: 'Zenith Legends',
    amountUsdt: 450,
    category: AirdropCategory.latest,
    joinUrl: 'https://example.com/airdrops/zenith-legends',
    description: 'Level up inside Zenith universe to unlock hero NFTs and USDT bounties.',
    network: 'Polygon',
    deadline: DateTime.utc(2025, 9, 25),
    requirements: [
      'Mint a hero NFT on the Zenith launchpad.',
      'Complete any three weekly missions before the deadline.',
      'Refer two new players using your referral code.',
      'Stake your hero NFT for at least 48 hours.',
    ],
  ),
  Airdrop(
    id: 'ember-vault',
    name: 'Ember Vault Finale',
    amountUsdt: 0,
    category: AirdropCategory.ended,
    joinUrl: 'https://example.com/airdrops/ember-vault',
    description: 'Ended community drop rewarding early Ember Vault strategists.',
    network: 'Base',
    deadline: DateTime.utc(2025, 7, 12),
    requirements: [
      'This campaign is closed. Winners have been notified via email.',
      'Check your wallet for EMBX governance token distribution.',
    ],
  ),
  Airdrop(
    id: 'lumen-prologue',
    name: 'Lumen Prologue',
    amountUsdt: 2000,
    category: AirdropCategory.featured,
    joinUrl: 'https://example.com/airdrops/lumen-prologue',
    description: 'Flagship launch campaign celebrating Lumen layer-2 mainnet release.',
    network: 'Ethereum L2',
    deadline: DateTime.utc(2025, 12, 5),
    requirements: [
      'Bridge a minimum of 0.1 ETH to Lumen mainnet.',
      'Complete the validator delegation tutorial quests.',
      'Vote in at least one governance proposal.',
      'Follow @LumenChainHQ on X and join the Discord community.',
    ],
  ),
];

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.black, width: 2),
          ),
          child: Icon(icon, color: Colors.black87, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.85),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black, offset: Offset(4, 4)),
        ],
      ),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

class _NeubrutalButton extends StatelessWidget {
  const _NeubrutalButton({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black, width: 2.5),
          boxShadow: const [
            BoxShadow(color: Colors.black, offset: Offset(6, 6)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label.toUpperCase(),
              style: TextStyle(
                color: foregroundColor,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(width: 10),
            Icon(icon, color: foregroundColor, size: 22),
          ],
        ),
      ),
    );
  }
}

class _NeubrutalLinkButton extends StatelessWidget {
  const _NeubrutalLinkButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: Colors.black,
        textStyle: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
          decoration: TextDecoration.underline,
        ),
      ),
      icon: const Icon(Icons.rule_folder_outlined),
      label: Text(label),
    );
  }
}

class _NeubrutalBanner extends StatelessWidget {
  const _NeubrutalBanner({
    required this.icon,
    required this.message,
    required this.accentColor,
  });

  final IconData icon;
  final String message;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black, offset: Offset(5, 5)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black, width: 2),
            ),
            child: Icon(icon, color: Colors.black, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NeubrutalLoader extends StatelessWidget {
  const _NeubrutalLoader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black, width: 2),
            boxShadow: const [
              BoxShadow(color: Colors.black, offset: Offset(4, 4)),
            ],
          ),
          child: const Padding(
            padding: EdgeInsets.all(14),
            child: CircularProgressIndicator(strokeWidth: 4),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

class _IconNeubButton extends StatelessWidget {
  const _IconNeubButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.black, width: 2),
            boxShadow: const [
              BoxShadow(color: Colors.black, offset: Offset(5, 5)),
            ],
          ),
          child: Icon(icon, color: Colors.black, size: 26),
        ),
      ),
    );
  }
}

class _NeubrutalChecklistItem extends StatelessWidget {
  const _NeubrutalChecklistItem({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black, offset: Offset(4, 4)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.black, width: 2),
            ),
            child: const Icon(Icons.check, size: 16, color: Colors.black),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _launchJoinUrl(BuildContext context, String url) async {
  if (url.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Join link not provided yet. Check back soon.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    return;
  }

  final uri = Uri.tryParse(url);
  if (uri == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Could not open the join link.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    return;
  }

  final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!launched) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Unable to launch the join link.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
