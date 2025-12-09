import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:paulette/models/design_model_pedicure.dart';


class PedicureService {
  final CollectionReference servicesRef =
      FirebaseFirestore.instance.collection("pedicure_services");

  // Stream para obtener todos los servicios (para el listado)
  Stream<List<PedicureServiceModel>> getServices() {
    return servicesRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return PedicureServiceModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  // Añadir un nuevo servicio
  Future<void> addService(Map<String, dynamic> data) async {
    await servicesRef.add(data);
  }

  // Actualizar un servicio existente
  Future<void> updateService(String id, Map<String, dynamic> data) async {
    await servicesRef.doc(id).update(data);
  }

  // Eliminar un servicio
  Future<void> deleteService(String id) async {
    await servicesRef.doc(id).delete();
  }

  Future<void> toggleActiveStatus(String id, bool newStatus) async{
    await servicesRef.doc(id).update({
      'isActive': newStatus,
    });
  }
}