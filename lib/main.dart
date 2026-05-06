import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarBrightness: Brightness.dark),
  );
  runApp(const MyApp());
}

// ─── Data ────────────────────────────────────────────────────────────────────

class Song {
  final String title;
  final String album;
  final String artist;
  final String imageId;

  const Song({
    required this.title,
    required this.album,
    required this.artist,
    required this.imageId,
  });
}

const List<Song> kSongs = [
  Song(title: "Didn't",        album: "Human (Deluxe) 2020",    artist: "OneRepublic",  imageId: "10"),
  Song(title: "Apologize",     album: "Dreaming Out Loud 2006",  artist: "OneRepublic",  imageId: "20"),
  Song(title: "God's Plan",    album: "God's Plan",              artist: "Drake",        imageId: "30"),
  Song(title: "YUNGBLUD",      album: "YUNGBLUD",                artist: "YUNGBLUD",     imageId: "40"),
  Song(title: "Jungle Baby",   album: "Jungle Baby",             artist: "Jungle",       imageId: "50"),
  Song(title: "All the Right Movers", album: "Waking up 2009",  artist: "OneRepublic",  imageId: "60"),
  Song(title: "Lose Somebody", album: "Lose Somebody",           artist: "Kygo",         imageId: "70"),
  Song(title: "Woofer",        album: "Woofer",                  artist: "Badshah",      imageId: "80"),
  Song(title: "Blinding Lights", album: "After Hours 2020",      artist: "The Weeknd",   imageId: "90"),
  Song(title: "Levitating",    album: "Future Nostalgia 2020",   artist: "Dua Lipa",     imageId: "11"),
  Song(title: "Stay",          album: "Stay - Single",           artist: "Kid Laroi",    imageId: "21"),
  Song(title: "Heat Waves",    album: "Dreamland 2020",          artist: "Glass Animals", imageId: "31"),
];

// ─── App ─────────────────────────────────────────────────────────────────────

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Music',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFFE8503A),
          surface: const Color(0xFF1A1A1A),
        ),
        useMaterial3: true,
      ),
      home: const MusicHomeScreen(),
    );
  }
}

// ─── Home Screen ─────────────────────────────────────────────────────────────

class MusicHomeScreen extends StatefulWidget {
  const MusicHomeScreen({super.key});

  @override
  State<MusicHomeScreen> createState() => _MusicHomeScreenState();
}

class _MusicHomeScreenState extends State<MusicHomeScreen> {
  bool _isGridView = true;
  Song? _nowPlaying;

  void _play(Song song) => setState(() => _nowPlaying = song);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // ── SliverAppBar ─────────────────────────
              SliverAppBar(
                expandedHeight: 260,
                pinned: true,
                stretch: true,
                backgroundColor: const Color(0xFF0F0F0F),
                elevation: 0,
                actions: [
                  IconButton(
                    icon: Icon(
                      _isGridView ? Icons.list_rounded : Icons.grid_view_rounded,
                      color: Colors.white,
                    ),
                    onPressed: () =>
                        setState(() => _isGridView = !_isGridView),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding:
                      const EdgeInsets.only(left: 20, bottom: 16),
                  title: const Text(
                    "Sliver List and Grid",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                  background: _HeroBackground(
                    nowPlaying: _nowPlaying,
                  ),
                  stretchModes: const [
                    StretchMode.zoomBackground,
                    StretchMode.blurBackground,
                  ],
                ),
              ),

              // ── Genre chips ──────────────────────────
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 52,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    children: const [
                      _Chip(label: "All",     active: true),
                      _Chip(label: "Pop"),
                      _Chip(label: "Hip-Hop"),
                      _Chip(label: "R&B"),
                      _Chip(label: "Dance"),
                      _Chip(label: "Indie"),
                    ],
                  ),
                ),
              ),

              // ── Section header ───────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Popular Tracks",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        "See all",
                        style: TextStyle(
                          fontSize: 13,
                          color: const Color(0xFFE8503A),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Grid or List ─────────────────────────
              _isGridView ? _buildGrid() : _buildList(),

              // Bottom padding for mini player
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),

          // ── Mini Player ──────────────────────────────
          if (_nowPlaying != null)
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: _MiniPlayer(song: _nowPlaying!),
            ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (context, i) => _SongCard(
            song: kSongs[i],
            onTap: () => _play(kSongs[i]),
          ),
          childCount: kSongs.length,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.72,
        ),
      ),
    );
  }

  Widget _buildList() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, i) => _SongListTile(
          song: kSongs[i],
          index: i + 1,
          onTap: () => _play(kSongs[i]),
        ),
        childCount: kSongs.length,
      ),
    );
  }
}

// ─── Hero Background ─────────────────────────────────────────────────────────

class _HeroBackground extends StatelessWidget {
  final Song? nowPlaying;
  const _HeroBackground({this.nowPlaying});

  @override
  Widget build(BuildContext context) {
    final song = nowPlaying ?? kSongs[0];
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          "https://picsum.photos/600/400?random=${song.imageId}",
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              Container(color: const Color(0xFF1A1A1A)),
        ),
        // Dark gradient overlay
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.3),
                Colors.black.withOpacity(0.5),
                const Color(0xFF0F0F0F),
              ],
              stops: const [0.0, 0.6, 1.0],
            ),
          ),
        ),
        // Now playing hint
        if (nowPlaying != null)
          Positioned(
            right: 16,
            bottom: 48,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFE8503A),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.equalizer_rounded,
                      color: Colors.white, size: 14),
                  const SizedBox(width: 5),
                  Text(
                    "Now playing",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Genre Chip ──────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final String label;
  final bool active;
  const _Chip({required this.label, this.active = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: active
            ? const Color(0xFFE8503A)
            : const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: active ? Colors.white : Colors.white60,
        ),
      ),
    );
  }
}

// ─── Song Card (Grid) ────────────────────────────────────────────────────────

class _SongCard extends StatelessWidget {
  final Song song;
  final VoidCallback onTap;
  const _SongCard({required this.song, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(14),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Album art
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    "https://picsum.photos/300?random=${song.imageId}",
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: const Color(0xFF2A2A2A)),
                  ),
                  // Play overlay
                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE8503A),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.play_arrow_rounded,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    song.album,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white54,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

// ─── Song List Tile ───────────────────────────────────────────────────────────

class _SongListTile extends StatelessWidget {
  final Song song;
  final int index;
  final VoidCallback onTap;
  const _SongListTile(
      {required this.song, required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                "https://picsum.photos/100?random=${song.imageId}",
                width: 52,
                height: 52,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 52,
                  height: 52,
                  color: const Color(0xFF2A2A2A),
                  child: const Icon(Icons.music_note,
                      color: Colors.white24, size: 24),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    song.album,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white54,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Duration placeholder
            const Text(
              "3:45",
              style: TextStyle(fontSize: 12, color: Colors.white38),
            ),
            const SizedBox(width: 10),
            // More button
            const Icon(Icons.more_vert_rounded,
                color: Colors.white38, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─── Mini Player ─────────────────────────────────────────────────────────────

class _MiniPlayer extends StatefulWidget {
  final Song song;
  const _MiniPlayer({required this.song});

  @override
  State<_MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<_MiniPlayer> {
  bool _playing = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(16)),
            child: Image.network(
              "https://picsum.photos/100?random=${widget.song.imageId}",
              width: 64,
              height: 64,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 64,
                height: 64,
                color: const Color(0xFF2A2A2A),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Song info
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.song.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  widget.song.artist,
                  style: const TextStyle(
                      fontSize: 11, color: Colors.white54),
                ),
              ],
            ),
          ),
          // Controls
          IconButton(
            icon: const Icon(Icons.skip_previous_rounded,
                color: Colors.white70, size: 22),
            onPressed: () {},
          ),
          GestureDetector(
            onTap: () => setState(() => _playing = !_playing),
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFFE8503A),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _playing
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.skip_next_rounded,
                color: Colors.white70, size: 22),
            onPressed: () {},
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}