import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/features/album/state/album_provider.dart';
import 'package:flutter_app/shared/services/storage_service.dart';

class AlbumPage extends StatefulWidget {
  const AlbumPage({super.key});

  @override
  State<AlbumPage> createState() => _AlbumPageState();
}

class _AlbumPageState extends State<AlbumPage> {
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      // 获取个人相簿
      final albumProvider = AlbumProvider.of(context);
      albumProvider.getMyShots();
      _isInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final albumProvider = Provider.of<AlbumProvider>(context);

    return albumProvider.isLoading
        ? const Center(child: CircularProgressIndicator())
        : albumProvider.errorMessage != null
            ? Center(child: Text(albumProvider.errorMessage!))
            : albumProvider.dateGroups.isEmpty
                ? const Center(child: Text('暂无照片'))
                : ListView.builder(
                    itemCount: albumProvider.dateGroups.length,
                    itemBuilder: (context, index) {
                      final group = albumProvider.dateGroups[index];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 日期标题
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              group.localDate,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          // 照片列表
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: group.shots.length,
                            itemBuilder: (context, shotIndex) {
                              final shot = group.shots[shotIndex];
                              return FutureBuilder<String>(
                                future: StorageService().getDownloadUrl(shot.storagePath),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData) {
                                    return Image.network(
                                      snapshot.data!,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: 100,
                                    );
                                  } else {
                                    return Container(
                                      color: Colors.grey[200],
                                      child: const Center(
                                        child: Icon(Icons.photo),
                                      ),
                                    );
                                  }
                                },
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                        ],
                      );
                    },
                  );
  }
}
