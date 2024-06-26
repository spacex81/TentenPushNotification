import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

admin.initializeApp();

const livekitApiKey = 'API4vY5fJ6zxS6e';
const livekitApiSecret = 'GGqV7dBkfi4mtBwK1UD1EvJCLRQCouB7YcDSwyR07MR';

export const sendPushNotification = functions.https.onRequest(async (req, res) => {
  try {
    // we need to generate new livekit access token using livekit's javascript server sdk 
    // we also need to generate a uuid that will be used in the swiftui 'UUID(uuidString: )'
    const fcmToken = req.body.fcmToken;
    // const livekitToken = 
    // const channelUUID = 


    if (!fcmToken) {
      res.status(400).send('FCM Token is required');
      return;
    }

    // we need to send 'livekitToken' and 'channelUUID' to the receiver by push notification
    const message = {
      notification: {
        title: 'Hello!',
        body: 'You have a new notification.',
      },
      token: fcmToken,
    };

    await admin.messaging().send(message);
    // we need to also need to add the 'livekitToken', 'channelUUID' to the response
    res.status(200).send('Notification sent successfully');
  } catch (error) {
    console.error('Error sending notification:', error);
    res.status(500).send('Error sending notification');
  }
});
