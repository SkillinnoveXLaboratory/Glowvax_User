import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../providers/search_provider.dart';
import '../../widgets/home/service_card.dart';
import '../../widgets/common/app_button.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  String? _initialQuery;
  Timer? _debounce;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final query = ModalRoute.of(context)?.settings.arguments as String?;
    if (query != null && query.isNotEmpty && query != _initialQuery) {
      _initialQuery = query;
      _controller.text = query;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<SearchProvider>().search(query);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _initialQuery != null) return;
      context.read<SearchProvider>().search('');
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) context.read<SearchProvider>().search(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final search = context.watch<SearchProvider>();
    final showFullLoader =
        search.isLoading && !search.hasLoaded && search.results.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: AppStrings.searchHint,
            border: InputBorder.none,
            hintStyle: TextStyle(color: AppColors.textHintOf(context)),
          ),
          onChanged: _onQueryChanged,
          onSubmitted: (q) => search.search(q, force: true),
        ),
      ),
      body: showFullLoader
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : Column(
              children: [
                if (search.isLoading)
                  const LinearProgressIndicator(
                    color: AppColors.primary,
                    backgroundColor: AppColors.surfaceElevated,
                    minHeight: 2,
                  ),
                Expanded(
                  child: search.error != null && search.results.isEmpty
                      ? EmptyStateWidget(
                          title: 'Search failed',
                          subtitle: search.error!,
                          icon: Icons.error_outline,
                        )
                      : search.results.isEmpty
                      ? EmptyStateWidget(
                          title: 'No results found',
                          subtitle:
                              'Try salon, spa, haircut, or a business name',
                          icon: Icons.search_off_rounded,
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: search.results.length,
                          itemBuilder: (context, index) {
                            final service = search.results[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: ServiceListTile(
                                service: service,
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  AppRoutes.serviceDetail,
                                  arguments: service,
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
