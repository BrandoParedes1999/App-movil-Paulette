//ESTE MODULO ES PARA EL READ PARA QUE APAREZCA EN LA LISTA DE DISEÑOS NO LO TOQUEN CULEROS
class DesignModel {
  final String id;
  final String title;
  final List<String> categories;
  final String season;
  final double price;
  final String imageUrl;
  final String publicId;
  final bool isActive;

  DesignModel({
    required this.id,
    required this.title,
    required this.season,
    required this.categories,
    required this.price,
    required this.imageUrl,
    required this.publicId,
    required this.isActive,
  });

  factory DesignModel.fromMap(String id, Map<String, dynamic> data) {
    return DesignModel(
      id: id,
      title: data['nombre'] ?? '',
      season: data['temporada'] ?? '',
      categories: List<String>.from(data['categories'] ?? []),
      price: (data['precio'] ?? 0).toDouble(),
      imageUrl: data['imageUrl'] ?? '',
      publicId: data['publicId'] ?? '',
      isActive: data['isActive'] ?? true,
    );
  }
}