import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

void main() {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarBrightness: Brightness.dark),
  );
  runApp(const MyApp());
}

// ─── Model ───────────────────────────────────────────────────────────────────

class Song {
  final int id;
  final String title;
  final String artist;
  final String album;
  final String genre;
  final String coverUrl;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.genre,
    required this.coverUrl,
  });

  /// Maps a raw track from the iTunes Search API to our Song model
  factory Song.fromItunes(Map<String, dynamic> json) {
    return Song(
      id: json['trackId'] ?? 0,
      title: json['trackName'] ?? 'Unknown',
      artist: json['artistName'] ?? 'Unknown',
      album: json['collectionName'] ?? 'Unknown',
      genre: json['primaryGenreName'] ?? 'Other',
      // artwork is 100x100 by default — request 300x300
      coverUrl: (json['artworkUrl100'] as String? ?? '')
          .replaceAll('100x100', '300x300'),
    );
  }
}

// ─── API Service ─────────────────────────────────────────────────────────────

class MusicApiService {
  static const String _base = 'https://itunes.apple.com/search';

  /// Fetches top tracks for a given search term.
  /// Uses the iTunes Search API — no API key needed.
  static Future<List<Song>> fetchTracks({String term = 'top hits'}) async {
    final uri = Uri.parse(
      '$_base?term=${Uri.encodeComponent(term)}&media=music&limit=20',
    );
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to load tracks: ${response.statusCode}');
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    final results = data['results'] as List<dynamic>;
    return results
        .where((r) => r['trackId'] != null)
        .map((r) => Song.fromItunes(r as Map<String, dynamic>))
        .toList();
  }
}

// ─── App ─────────────────────────────────────────────────────────────────────

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sliver Widgets Projet',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFE8503A),
          surface: Color(0xFF1A1A1A),
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
  String _selectedGenre = 'All';
  List<Song> _allSongs = [];
  bool _loading = true;
  String? _error;

  List<String> get _genres {
    final set = <String>{'All'};
    for (final s in _allSongs) {
      set.add(s.genre);
    }
    return set.toList();
  }

  List<Song> get _filteredSongs {
    if (_selectedGenre == 'All') return _allSongs;
    return _allSongs.where((s) => s.genre == _selectedGenre).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadTracks();
  }

  Future<void> _loadTracks() async {
    try {
      setState(() { _loading = true; _error = null; });
      final songs = await MusicApiService.fetchTracks(term: 'top hits 2024');
      setState(() { _allSongs = songs; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _play(Song song) => setState(() => _nowPlaying = song);
  void _closePlayer() => setState(() => _nowPlaying = null);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: Stack(
        children: [
          NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverOverlapAbsorber(
                handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                sliver: SliverAppBar(
                  expandedHeight: 260,
                  pinned: true,        // ← always visible, never disappears
                  floating: false,
                  forceElevated: innerBoxIsScrolled,
                  stretch: true,
                  backgroundColor: const Color(0xFF0F0F0F),
                  elevation: 0,
                  actions: [
                    IconButton(
                      icon: Icon(
                        _isGridView ? Icons.list_rounded : Icons.grid_view_rounded,
                        color: Colors.white,
                      ),
                      onPressed: () => setState(() => _isGridView = !_isGridView),
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                    title: const Text(
                      'Sliver List and Grid',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                    // ← hero shows the now-playing cover (or first song cover)
                    background: _HeroBackground(
                      coverUrl: _nowPlaying?.coverUrl ??
                          (_allSongs.isNotEmpty ? _allSongs.first.coverUrl : null),
                    ),
                    stretchModes: const [
                      StretchMode.zoomBackground,
                      StretchMode.blurBackground,
                    ],
                  ),
                ),
              ),
            ],
            body: Builder(
              builder: (context) {
                return CustomScrollView(
                  slivers: [
                    SliverOverlapInjector(
                      handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                    ),

                    // ── Genre chips — STICKY below AppBar ────────
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _StickyGenreDelegate(
                        genres: _genres,
                        selected: _selectedGenre,
                        onSelect: (g) => setState(() => _selectedGenre = g),
                      ),
                    ),

                    // ── Section header ────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedGenre == 'All' ? 'Popular Tracks' : _selectedGenre,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.3,
                              ),
                            ),
                            Text(
                              '${_filteredSongs.length} tracks',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFFE8503A),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── Loading / Error / Songs ───────────────────
                    if (_loading)
                      const SliverFillRemaining(
                        child: Center(
                          child: CircularProgressIndicator(color: Color(0xFFE8503A)),
                        ),
                      )
                    else if (_error != null)
                      SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.wifi_off_rounded, color: Colors.white38, size: 48),
                              const SizedBox(height: 12),
                              const Text('Failed to load tracks',
                                  style: TextStyle(color: Colors.white54)),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadTracks,
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFE8503A)),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (_filteredSongs.isEmpty)
                      const SliverFillRemaining(
                        child: Center(
                          child: Text('No tracks in this genre',
                              style: TextStyle(color: Colors.white54)),
                        ),
                      )
                    else
                      _isGridView ? _buildGrid() : _buildList(),

                    const SliverToBoxAdapter(child: SizedBox(height: 90)),
                  ],
                );
              },
            ),
          ),

          // ── Mini Player ──────────────────────────────────
          if (_nowPlaying != null)
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: _MiniPlayer(song: _nowPlaying!, onClose: _closePlayer),
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
          (context, index) => _SongCard(
            song: _filteredSongs[index],
            onTap: () => _play(_filteredSongs[index]),
          ),
          childCount: _filteredSongs.length,
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
        (context, index) => _SongListTile(
          song: _filteredSongs[index],
          index: index + 1,
          onTap: () => _play(_filteredSongs[index]),
        ),
        childCount: _filteredSongs.length,
      ),
    );
  }
}

// ─── Sticky Genre Delegate ────────────────────────────────────────────────────

class _StickyGenreDelegate extends SliverPersistentHeaderDelegate {
  final List<String> genres;
  final String selected;
  final ValueChanged<String> onSelect;

  const _StickyGenreDelegate({
    required this.genres,
    required this.selected,
    required this.onSelect,
  });

  @override double get minExtent => 52;
  @override double get maxExtent => 52;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color(0xFF0F0F0F),
      height: 52,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: genres.length,
        itemBuilder: (_, i) {
          final genre = genres[i];
          final active = genre == selected;
          return GestureDetector(
            onTap: () => onSelect(genre),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: active ? const Color(0xFFE8503A) : const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                genre,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: active ? Colors.white : Colors.white60,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  bool shouldRebuild(_StickyGenreDelegate old) =>
      old.selected != selected || old.genres.length != genres.length;
}

// ─── Hero Background ─────────────────────────────────────────────────────────

class _HeroBackground extends StatelessWidget {
  final String? coverUrl;
  const _HeroBackground({this.coverUrl});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (coverUrl != null && coverUrl!.isNotEmpty)
          Image.network(
            coverUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                Container(color: const Color(0xFF1A1A1A)),
          )
        else
          Container(color: const Color(0xFF1A1A1A)),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.2),
                Colors.black.withOpacity(0.5),
                const Color(0xFF0F0F0F),
              ],
              stops: const [0.0, 0.6, 1.0],
            ),
          ),
        ),
      ],
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
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    song.coverUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: const Color(0xFF2A2A2A)),
                  ),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
              child: Text(song.title,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: Text(song.album,
                  style: const TextStyle(fontSize: 11, color: Colors.white54),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
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
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                song.coverUrl,
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(song.title,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text(song.album,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.white54),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(song.genre,
                  style: const TextStyle(fontSize: 10, color: Colors.white38)),
            ),
            const SizedBox(width: 8),
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
  final VoidCallback onClose;
  const _MiniPlayer({required this.song, required this.onClose});

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
          // ← same cover as the song card
          ClipRRect(
            borderRadius:
                const BorderRadius.horizontal(left: Radius.circular(16)),
            child: Image.network(
              widget.song.coverUrl,
              width: 64,
              height: 64,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(width: 64, height: 64, color: const Color(0xFF2A2A2A)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.song.title,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(widget.song.artist,
                    style: const TextStyle(
                        fontSize: 11, color: Colors.white54)),
              ],
            ),
          ),
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
                _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
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
          // ← X close button
          GestureDetector(
            onTap: widget.onClose,
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: Colors.white12,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded,
                  color: Colors.white60, size: 15),
            ),
          ),
        ],
      ),
    );
  }
}