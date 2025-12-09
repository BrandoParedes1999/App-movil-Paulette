class PedicureServiceModel {
  final String id;
  final String title;
  final String description;
  final int durationMinutes; // Duración del servicio en minutos
  final List<String> categories; // Tipo de cuidado (Estético, Spa, Clínico)
  final double price;
  final String imageUrl;
  final String publicId;
  final bool isActive;

  PedicureServiceModel({
    required this.id,
    required this.title,
    required this.description,
    required this.durationMinutes,
    required this.categories,
    required this.price,
    required this.imageUrl,
    required this.publicId,
    required this.isActive,
  });

  // Convertir desde un mapa (usado por Firestore)
  factory PedicureServiceModel.fromMap(String id, Map<String, dynamic> data) {
    // Helper para asegurar que el precio y la duración son del tipo correcto
    double parsePrice(dynamic p) {
      if (p is num) return p.toDouble();
      return double.tryParse(p.toString()) ?? 0.0;
    }

    int parseDuration(dynamic d) {
      if (d is int) return d;
      return int.tryParse(d.toString()) ?? 0;
    }

    return PedicureServiceModel(
      id: id,
      title: data['nombre'] ?? '',
      description: data['descripcion'] ?? '',
      durationMinutes: parseDuration(data['duracion']),
      categories: List<String>.from(data['categories'] ?? []),
      price: parsePrice(data['precio']),
      imageUrl: data['imageUrl'] ?? '',
      publicId: data['publicId'] ?? '',
      isActive: data['isActive'] ?? true,
    );
  }

  // Convertir a un mapa (para guardar en Firestore)
  Map<String, dynamic> toMap() {
    return {
      'nombre': title,
      'descripcion': description,
      'duracion': durationMinutes,
      'categories': categories,
      'precio': price,
      'imageUrl': imageUrl,
      'publicId': publicId,
      'isActive': isActive,
    };
  }
}