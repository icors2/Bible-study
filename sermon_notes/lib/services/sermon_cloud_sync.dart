import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/sermon_models.dart';

/// Firebase Auth + Firestore sync for [SermonDraft] (per signed-in user).
class SermonCloudSync {
  static const _draftDocId = 'sermon_draft';

  bool get isFirebaseReady => Firebase.apps.isNotEmpty;

  FirebaseAuth? get _auth {
    if (!isFirebaseReady) return null;
    return FirebaseAuth.instance;
  }

  FirebaseFirestore? get _db {
    if (!isFirebaseReady) return null;
    return FirebaseFirestore.instance;
  }

  User? get currentUser => _auth?.currentUser;

  Stream<User?> authStateChanges() {
    final auth = _auth;
    if (auth == null) {
      return Stream<User?>.value(null);
    }
    return auth.authStateChanges();
  }

  DocumentReference<Map<String, dynamic>>? _draftRef(String uid) {
    final db = _db;
    if (db == null) return null;
    return db.collection('users').doc(uid).collection('data').doc(_draftDocId);
  }

  Future<SermonDraft?> loadRemoteDraft() async {
    final uid = currentUser?.uid;
    final ref = uid == null ? null : _draftRef(uid);
    if (ref == null) return null;

    final snap = await ref.get();
    if (!snap.exists) return null;

    final raw = snap.data()?['draftJson'];
    if (raw is! String || raw.isEmpty) return null;
    return SermonDraft.tryParse(raw);
  }

  Future<void> saveRemoteDraft(SermonDraft draft) async {
    final uid = currentUser?.uid;
    final ref = uid == null ? null : _draftRef(uid);
    if (ref == null) return;

    await ref.set(
      {
        'draftJson': draft.serialize(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> clearRemoteDraft() async {
    final uid = currentUser?.uid;
    final ref = uid == null ? null : _draftRef(uid);
    if (ref == null) return;
    await ref.delete();
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final auth = _auth;
    if (auth == null) {
      throw StateError('Firebase Auth is not available.');
    }
    await auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> registerWithEmail({
    required String email,
    required String password,
  }) async {
    final auth = _auth;
    if (auth == null) {
      throw StateError('Firebase Auth is not available.');
    }
    await auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _auth?.signOut();
  }
}
