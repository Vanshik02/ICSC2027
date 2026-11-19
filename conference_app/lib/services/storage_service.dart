import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadFile({required File file, required String path}) async {
    final reference = _storage.ref().child(path);

    final uploadTask = await reference.putFile(file);

    return await uploadTask.ref.getDownloadURL();
  }

  Future<void> deleteFile(String path) async {
    await _storage.ref().child(path).delete();
  }
}
