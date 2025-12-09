import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();

// Trigger: Se ejecuta cuando se crea un documento en la colección 'notifications'
export const sendPushNotification = functions.firestore
  .document("notifications/{notificationId}")
  .onCreate(async (snapshot, context) => {
    
    // 1. Obtener los datos de la notificación guardada
    const notificationData = snapshot.data();
    const userId = notificationData.userId;
    const title = notificationData.title;
    const body = notificationData.body;

    if (!userId || !title || !body) {
      console.log("Datos de notificación incompletos");
      return;
    }

    try {
      // 2. Buscar el token FCM del usuario en la colección 'users'
      const userDoc = await admin.firestore().collection("users").doc(userId).get();
      
      if (!userDoc.exists) {
        console.log(`Usuario ${userId} no encontrado`);
        return;
      }

      const userData = userDoc.data();
      const fcmToken = userData?.fcmToken;

      if (!fcmToken) {
        console.log(`Usuario ${userId} no tiene un token FCM registrado`);
        return;
      }

      // 3. Construir el mensaje
      const message = {
        notification: {
          title: title,
          body: body,
        },
        token: fcmToken,
        data: {
          click_action: "FLUTTER_NOTIFICATION_CLICK",
          type: notificationData.type || "general",
          // Puedes añadir más datos aquí si necesitas navegar a una pantalla específica
        }
      };

      // 4. Enviar la notificación a través de FCM
      const response = await admin.messaging().send(message);
      console.log("Notificación enviada exitosamente:", response);

    } catch (error) {
      console.error("Error enviando notificación:", error);
    }
  });
