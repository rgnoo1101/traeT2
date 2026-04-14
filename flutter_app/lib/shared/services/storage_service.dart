import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  
  late FirebaseStorage _storage;
  
  StorageService._internal() {
    _storage = FirebaseStorage.instance;
  }
  
  Future<String> uploadImage(String filePath, String storagePath, {Function(double)? onProgress}) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }
      
      // 替换路径中的{uid}为实际用户ID
      final path = storagePath.replaceAll('{uid}', user.uid);
      final file = File(filePath);
      
      final ref = _storage.ref().child(path);
      final uploadTask = ref.putFile(file);
      
      // 监听上传进度
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        if (onProgress != null) {
          onProgress(progress);
        }
      });
      
      await uploadTask;
      return path;
    } catch (e) {
      print('Upload failed: $e');
      rethrow;
    }
  }
  
  Future<String> getDownloadUrl(String storagePath) async {
    try {
      final ref = _storage.ref().child(storagePath);
      return await ref.getDownloadURL();
    } catch (e) {
      print('Get download URL failed: $e');
      rethrow;
    }
  }
  
  Future<void> deleteImage(String storagePath) async {
    try {
      final ref = _storage.ref().child(storagePath);
      await ref.delete();
    } catch (e) {
      print('Delete failed: $e');
      rethrow;
    }
  }
}
