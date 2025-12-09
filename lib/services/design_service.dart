import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:paulette/models/design_model.dart';

class DesignService {
  final CollectionReference designsRef = FirebaseFirestore.instance.collection(
    "manicure_designs",
  );

  Stream<List<DesignModel>> getDesigns() {
    return designsRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return DesignModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  Future<void> addDesign(Map<String, dynamic> data) async {
    await designsRef.add(data);
  }

  Future<void> updateDesign(String id, Map<String, dynamic> data) async {
    await designsRef.doc(id).update(data);
  }

  Future<void> deleteDesign(String id) async {
    await designsRef.doc(id).delete();
  }

  Future<void> toggleActiveStatus(String id, bool newStatus) async {
    await designsRef.doc(id).update({'isActive': newStatus});
  }
}
