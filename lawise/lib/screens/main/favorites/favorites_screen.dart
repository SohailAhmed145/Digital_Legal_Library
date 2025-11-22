import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  String _selectedFilter = 'All';
  final List<String> _filterOptions = ['All', 'Cases', 'Laws', 'Documents'];
  final List<FavoriteItem> _favorites = [
    FavoriteItem(
      title: 'Contract Law Fundamentals',
      subtitle: 'Essential principles of contract formation and enforcement',
      type: FavoriteType.law,
      category: 'Contract Law',
      isBookmarked: true,
      lastAccessed: '2 days ago',
    ),
    FavoriteItem(
      title: 'Smith vs. Johnson Corp',
      subtitle: 'Employment discrimination case - settlement reached',
      type: FavoriteType.caseItem,
      category: 'Employment Law',
      isBookmarked: true,
      lastAccessed: '1 week ago',
    ),
    FavoriteItem(
      title: 'Corporate Formation Guide',
      subtitle: 'Step-by-step guide to forming LLCs and corporations',
      type: FavoriteType.document,
      category: 'Business Law',
      isBookmarked: true,
      lastAccessed: '3 days ago',
    ),
    FavoriteItem(
      title: 'Property Rights in Pakistan',
      subtitle: 'Comprehensive overview of property laws and regulations',
      type: FavoriteType.law,
      category: 'Property Law',
      isBookmarked: true,
      lastAccessed: '5 days ago',
    ),
    FavoriteItem(
      title: 'Roberts Family Trust',
      subtitle: 'Estate planning and trust administration case',
      type: FavoriteType.caseItem,
      category: 'Estate Law',
      isBookmarked: true,
      lastAccessed: '2 weeks ago',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final filteredFavorites = _getFilteredFavorites();
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Favorites',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.grey),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.grey),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: _filterOptions.map((filter) {
                final isSelected = _selectedFilter == filter;
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(
                        filter,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedFilter = filter;
                        });
                      },
                      backgroundColor: Colors.grey[200],
                      selectedColor: const Color(0xFF1A237E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          
          // Favorites Count and Sort
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${filteredFavorites.length} favorites',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Recently Added',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down, size: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Favorites List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filteredFavorites.length,
              itemBuilder: (context, index) {
                final favorite = filteredFavorites[index];
                return _buildFavoriteCard(favorite);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  List<FavoriteItem> _getFilteredFavorites() {
    if (_selectedFilter == 'All') {
      return _favorites;
    }
    return _favorites.where((favorite) {
      switch (_selectedFilter) {
        case 'Cases':
          return favorite.type == FavoriteType.caseItem;
        case 'Laws':
          return favorite.type == FavoriteType.law;
        case 'Documents':
          return favorite.type == FavoriteType.document;
        default:
          return true;
      }
    }).toList();
  }

  Widget _buildFavoriteCard(FavoriteItem favorite) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Type Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getTypeColor(favorite.type).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getTypeIcon(favorite.type),
                  color: _getTypeColor(favorite.type),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            favorite.title,
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              favorite.isBookmarked = !favorite.isBookmarked;
                            });
                          },
                          icon: Icon(
                            favorite.isBookmarked
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                            color: favorite.isBookmarked
                                ? const Color(0xFF1A237E)
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      favorite.subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF757575),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Category and Last Accessed
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getTypeColor(favorite.type).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  favorite.category,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _getTypeColor(favorite.type),
                  ),
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 16,
                    color: Color(0xFF9E9E9E),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    favorite.lastAccessed,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF9E9E9E),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(FavoriteType type) {
    switch (type) {
      case FavoriteType.caseItem:
        return Colors.blue;
      case FavoriteType.law:
        return Colors.green;
      case FavoriteType.document:
        return Colors.orange;
    }
  }

  IconData _getTypeIcon(FavoriteType type) {
    switch (type) {
      case FavoriteType.caseItem:
        return Icons.gavel;
      case FavoriteType.law:
        return Icons.library_books;
      case FavoriteType.document:
        return Icons.description;
    }
  }
}

enum FavoriteType { caseItem, law, document }

class FavoriteItem {
  final String title;
  final String subtitle;
  final FavoriteType type;
  final String category;
  bool isBookmarked;
  final String lastAccessed;

  FavoriteItem({
    required this.title,
    required this.subtitle,
    required this.type,
    required this.category,
    required this.isBookmarked,
    required this.lastAccessed,
  });
}
