
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../services/firestore_service.dart';

class SpeakersScreen extends StatefulWidget {
  const SpeakersScreen({super.key});

  @override
  State<SpeakersScreen> createState() => _SpeakersScreenState();
}

class _SpeakersScreenState extends State<SpeakersScreen> {
  final TextEditingController searchController = TextEditingController();
  final FirestoreService firestoreService = FirestoreService();

  String selectedCategory = 'All Speakers';

  final List<String> categories = [
    'All Speakers',
    'Keynote',
    'Invited',
    'Technical',
  ];

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _header()),
            SliverToBoxAdapter(child: _searchBar()),
            SliverToBoxAdapter(child: _categorySelector()),
            SliverToBoxAdapter(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: firestoreService.getSpeakers(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return _messageCard(
                      icon: Icons.cloud_off_rounded,
                      title: 'Unable to Load Speakers',
                      message: 'Please check your internet connection and try again.',
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 70),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.blue,
                        ),
                      ),
                    );
                  }

                  final query = searchController.text.trim().toLowerCase();

                  final speakers = snapshot.data?.docs.where((doc) {
                    final data = doc.data();

                    final name = (data['name'] ?? '').toString().toLowerCase();
                    final designation =
                        (data['designation'] ?? '').toString().toLowerCase();
                    final affiliation =
                        (data['affiliation'] ?? '').toString().toLowerCase();
                    final category =
                        (data['category'] ?? '').toString().toLowerCase();

                    final matchesSearch = query.isEmpty ||
                        name.contains(query) ||
                        designation.contains(query) ||
                        affiliation.contains(query) ||
                        category.contains(query);

                    final matchesCategory = selectedCategory == 'All Speakers' ||
                        category == selectedCategory.toLowerCase();

                    return matchesSearch && matchesCategory;
                  }).toList() ?? [];

                  if (speakers.isEmpty) {
                    return _messageCard(
                      icon: Icons.person_search_rounded,
                      title: query.isNotEmpty || selectedCategory != 'All Speakers'
                          ? 'No Speakers Found'
                          : 'Speaker Profiles Coming Soon',
                      message: query.isNotEmpty || selectedCategory != 'All Speakers'
                          ? 'No published speaker profiles match your search or selected category.'
                          : 'Confirmed speaker profiles will appear here once announced by the conference organisers.',
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 17, 20, 30),
                    child: Column(
                      children: speakers.map((doc) {
                        return _speakerCard(doc.data());
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 23, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ICSC 2027',
            style: TextStyle(
              color: AppTheme.blue,
              fontSize: 10,
              letterSpacing: 2,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Speakers & Experts',
            style: TextStyle(
              color: AppTheme.navy,
              fontSize: 25,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.7,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Meet the researchers and experts shaping the future of technology.',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppTheme.border),
        ),
        child: TextField(
          controller: searchController,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            hintText: 'Search speakers...',
            hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 13),
            prefixIcon: Icon(Icons.search_rounded, color: AppTheme.blue),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ),
    );
  }

  Widget _categorySelector() {
    return SizedBox(
      height: 68,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 9),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = selectedCategory == category;

          return GestureDetector(
            onTap: () {
              setState(() => selectedCategory = category);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.navy : Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: isSelected ? AppTheme.navy : AppTheme.border,
                ),
              ),
              child: Center(
                child: Text(
                  category,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _speakerCard(Map<String, dynamic> data) {
    final name = (data['name'] ?? 'Speaker').toString();
    final designation = (data['designation'] ?? '').toString();
    final affiliation = (data['affiliation'] ?? '').toString();
    final bio = (data['bio'] ?? '').toString();
    final category = (data['category'] ?? '').toString();
    final photoUrl = (data['photoUrl'] ?? '').toString().trim();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Container(
              height: 76,
              width: 76,
              color: const Color(0xFFEAF2FB),
              child: photoUrl.isNotEmpty
                  ? Image.network(
                      photoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _speakerPlaceholder(),
                    )
                  : _speakerPlaceholder(),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (category.isNotEmpty) ...[
                  Text(
                    category.toUpperCase(),
                    style: const TextStyle(
                      color: AppTheme.blue,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 5),
                ],
                Text(
                  name,
                  style: const TextStyle(
                    color: AppTheme.navy,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (designation.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    designation,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ],
                if (affiliation.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    affiliation,
                    style: const TextStyle(
                      color: AppTheme.blue,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (bio.isNotEmpty) ...[
                  const SizedBox(height: 9),
                  Text(
                    bio,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 11,
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _speakerPlaceholder() {
    return const Center(
      child: Icon(
        Icons.person_rounded,
        size: 39,
        color: AppTheme.blue,
      ),
    );
  }

  Widget _messageCard({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 17, 20, 35),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(23),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          children: [
            Container(
              height: 66,
              width: 66,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF2FB),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, color: AppTheme.blue, size: 33),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.navy,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 12,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 17),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F7FB),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.verified_outlined,
                    color: AppTheme.blue,
                    size: 19,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Only officially confirmed speaker information will be displayed.',
                      style: TextStyle(
                        color: AppTheme.navyLight,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                      ),
                    ),
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
