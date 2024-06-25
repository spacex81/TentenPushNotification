import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

admin.initializeApp();

export const sendPushNotification = functions.https.onRequest(async (req, res) => {
  try {
    const fcmToken = req.body.fcmToken;

    if (!fcmToken) {
      res.status(400).send('FCM Token is required');
      return;
    }

    const message = {
      notification: {
        title: 'Hello!',
        body: 'You have a new notification.',
      },
      token: fcmToken,
    };

    await admin.messaging().send(message);
    res.status(200).send('Notification sent successfully');
  } catch (error) {
    console.error('Error sending notification:', error);
    res.status(500).send('Error sending notification');
  }
});
