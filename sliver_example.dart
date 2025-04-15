import '../../../discovery_app.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final double searchBarHeight = 80;

  // This will be determined dynamically based on your actual data
  final List<String> featuredEvents = ["Concert in the Park", "Tech Conference 2025", "Food Festival", "Festival", "Art Exhibition", "Art "];

  // Key to measure the size of the featured events section
  final GlobalKey _featuredEventsKey = GlobalKey();

  // Threshold when search bar should start scrolling
  double _scrollThreshold = 0;
  bool _thresholdCalculated = false;
  bool _isSearchBarPinned = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Schedule a post-frame callback to calculate the threshold after layout
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateScrollThreshold();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _calculateScrollThreshold() {
    // Get the size of the featured events section
    final RenderBox? featuredEventsBox = _featuredEventsKey.currentContext?.findRenderObject() as RenderBox?;

    if (featuredEventsBox != null) {
      // The threshold is the distance from top of scroll view to bottom of search bar
      // This equals the height of the featured events section
      _scrollThreshold = featuredEventsBox.size.height;
      _thresholdCalculated = true;
      setState(() {});
    }
  }

  void _onScroll() {
    if (!_thresholdCalculated) return;

    // Check if we've scrolled past the threshold
    final shouldPin = _scrollController.offset < _scrollThreshold;

    if (shouldPin != _isSearchBarPinned) {
      setState(() {
        _isSearchBarPinned = shouldPin;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // AppBar with city and notification icons
          SliverAppBar(
            backgroundColor: Colors.white,
            pinned: true,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("📍 City Name", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                Row(
                  children: [
                    IconButton(icon: Icon(Icons.confirmation_num, color: Colors.black), onPressed: () {}),
                    IconButton(icon: Icon(Icons.notifications, color: Colors.black), onPressed: () {}),
                  ],
                ),
              ],
            ),
            centerTitle: false,
          ),

          // Search Bar (pinned or not based on scroll position)
          SliverPersistentHeader(
            pinned: _isSearchBarPinned,
            delegate: _SearchBarDelegate(
              expandedHeight: searchBarHeight,
            ),
          ),

          // Category events (horizontal carousels)
          SliverToBoxAdapter(
            child: Container(
              key: _featuredEventsKey, // Use this key to measure height
              child: _buildCategoryEvents(),
            ),
          ),

          // Sticky Filter Chips
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickyFilterChipsDelegate(),
          ),

          // Paginated ListView
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                // build your paginated event item here
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      "Event ${index + 1}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        SizedBox(height: 8),
                        Text('April 15, 2025 • 8:00 PM'),
                        SizedBox(height: 4),
                        Text('Some venue location here'),
                      ],
                    ),
                    leading: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.event),
                    ),
                  ),
                );
              },
              childCount: 50, // replace with actual item count
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryEvents() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
            child: Text("Featured Events", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          ...List.generate(featuredEvents.length, (index) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(featuredEvents[index], style: const TextStyle(fontSize: 16)),
            );
          }),
        ],
      ),
    );
  }
}

// Search Bar Delegate
class _SearchBarDelegate extends SliverPersistentHeaderDelegate {
  final double expandedHeight;

  _SearchBarDelegate({
    required this.expandedHeight,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final double offset = shrinkOffset.clamp(0.0, expandedHeight);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      alignment: Alignment.center,
      transform: Matrix4.translationValues(0, -offset, 0),
      child: TextField(
        decoration: InputDecoration(
          hintText: "Search events...",
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding: EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  @override
  double get maxExtent => expandedHeight;

  @override
  double get minExtent => expandedHeight;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => true;
}

// Filter Chips Delegate
class _StickyFilterChipsDelegate extends SliverPersistentHeaderDelegate {
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: SizedBox(
        height: 40,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            FilterChip(label: Text("All"), selected: true, onSelected: (_) {}),
            SizedBox(width: 8),
            FilterChip(label: Text("Music"), selected: false, onSelected: (_) {}),
            SizedBox(width: 8),
            FilterChip(label: Text("Tech"), selected: false, onSelected: (_) {}),
            SizedBox(width: 8),
            FilterChip(label: Text("Sports"), selected: false, onSelected: (_) {}),
            SizedBox(width: 8),
            FilterChip(label: Text("Art"), selected: false, onSelected: (_) {}),
            SizedBox(width: 8),
            FilterChip(label: Text("Food"), selected: false, onSelected: (_) {}),
          ],
        ),
      ),
    );
  }

  @override
  double get maxExtent => 64;

  @override
  double get minExtent => 64;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => true;
}
