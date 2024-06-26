import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

admin.initializeApp();

export const sendPushNotification = functions.https.onRequest(async (req, res) => {
  try {
    // we need to add another information in the request body 
    // we need to add 'livekitToken' 
    // if the 'livekitToken' is empty we need to generate new livekit access token using livekit's javascript server sdk 
    // if the 'livekitToken' is not empty, we will use that access token 
    const fcmToken = req.body.fcmToken;
    // const livekitToken = 

    if (!fcmToken) {
      res.status(400).send('FCM Token is required');
      return;
    }

    // we need to send 'livekitToken' to the receiver by push notification
    const message = {
      notification: {
        title: 'Hello!',
        body: 'You have a new notification.',
      },
      token: fcmToken,
    };

    await admin.messaging().send(message);
    // we need to also add the 'livekitToken' to the response
    res.status(200).send('Notification sent successfully');
  } catch (error) {
    console.error('Error sending notification:', error);
    res.status(500).send('Error sending notification');
  }
});
