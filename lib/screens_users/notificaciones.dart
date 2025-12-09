import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Asegúrate de importar intl

class NotificacionesScreen extends StatelessWidget {
  const NotificacionesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Notificaciones", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: user == null 
          ? const Center(child: Text("Inicia sesión para ver notificaciones"))
          : StreamBuilder<QuerySnapshot>(
              // Escucha la subcolección de notificaciones del usuario (o una colección global filtrada)
              // Ajusta esta ruta según cómo guardes tus notificaciones
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('notifications') 
                  .orderBy('createdAt', descending: true)
                  .limit(20)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.pinkAccent));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey[300]),
                        const SizedBox(height: 10),
                        const Text("No tienes notificaciones nuevas", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final date = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
                    final isRead = data['read'] ?? false;

                    return Dismissible(
                      key: Key(doc.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: Colors.red,
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (direction) {
                        doc.reference.delete(); // Borrar al deslizar
                      },
                      child: Card(
                        elevation: isRead ? 0 : 2,
                        color: isRead ? Colors.white : Colors.pink.shade50,
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isRead ? Colors.grey.shade200 : Colors.pinkAccent,
                            child: Icon(
                              Icons.notifications, 
                              color: isRead ? Colors.grey : Colors.white,
                              size: 20,
                            ),
                          ),
                          title: Text(data['title'] ?? 'Notificación', style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(data['body'] ?? ''),
                              const SizedBox(height: 4),
                              Text(DateFormat('dd MMM - hh:mm a').format(date), style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                            ],
                          ),
                          onTap: () {
                            // Marcar como leída al tocar
                            doc.reference.update({'read': true});
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}