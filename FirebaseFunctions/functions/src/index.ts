import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { AccessToken } from 'livekit-server-sdk';
import { v4 as uuidv4 } from 'uuid';

admin.initializeApp();
const db = admin.firestore();

const livekitApiKey = 'API4vY5fJ6zxS6e';
const livekitApiSecret = 'GGqV7dBkfi4mtBwK1UD1EvJCLRQCouB7YcDSwyR07MR';
const livekitHost = 'wss://tentwenty-bp8gb2jg.livekit.cloud';

export const sendPttNotification = functions.https.onCall(async (data, context) => {
  const { channelUUID, message } = data 

  if (!channelUUID || !message) {
    throw new functions.https.HttpsError('invalid-argument', 'Channel UUID and message are required')
  }

  // Retrieve EPT from Firestore 
  const doc = await db.collection('pttTokens').doc(channelUUID).get() 
  if (!doc.exists) {
    throw new functions.https.HttpsError('not-found', 'Channel not found')
  }

  const docData = doc.data() 
  if (!docData || !docData.ephemeralPushToken) {
    throw new functions.https.HttpsError('not-found', 'Ephemeral Token not found')
  }

  const ephemeralPushToken: string = docData.ephemeralPushToken

  const notificationMessage = {
    notification: {
      title: 'New PTT Audio', 
      body: message, 
    },
    data: {
      channelUUID: channelUUID
    }, 
    token: ephemeralPushToken, 
    apns: {
      headers: {
        'apns-push-type': 'pushtotalk', 
        'apns-priority': '10', 
        'apns-expiration': '0',
      },
      payload: {
        aps: {
          sound: 'default'
        }
      }
    }
  }

  await admin.messaging().send(notificationMessage)

  return {success: true}
})


export const handleEphemeralPushToken = functions.https.onRequest(async (req, res) => {
  try {
    const { ephemeralPushToken, senderFcmToken, receiverFcmToken, channelUUID, message } = req.body;

    if (!ephemeralPushToken || !senderFcmToken || !receiverFcmToken || !channelUUID || !message) {
      res.status(400).send('Ephemeral Push Token, Sender FCM Token, Receiver FCM Token, Channel UUID, and message are required');
      return;
    }

    // Store the EPT in Firestore
    await db.collection("pttTokens").doc(channelUUID).set({
      ephemeralPushToken: ephemeralPushToken,  // receiver's EPT
      senderFcmToken: senderFcmToken, 
      receiverFcmToken: receiverFcmToken, 
      timestamp: admin.firestore.FieldValue.serverTimestamp()
    });

    // Prepare push notification message to send to the receiver
    const notificationMessage = {
      token: receiverFcmToken,
      apns: {
        headers: {
          'apns-push-type': 'pushtotalk',
          'apns-priority': '10',
          'apns-expiration': '0',
        },
        payload: {
          aps: {
            alert: {
              title: 'PTT Notification',
              body: message,
            },
            sound: 'default',
          },
          customData: {
            channelUUID: channelUUID,
            ephemeralPushToken: ephemeralPushToken,
          }
        }
      },
    };

    // Send push notification
    await admin.messaging().send(notificationMessage);

    // Send response
    res.status(200).send('Ephemeral Push Token stored and notification sent successfully');

  } catch (error) {
    console.error('Error handling ephemeral push token: ', error);
    res.status(500).send('Error handling ephemeral push token');
  }
});

export const sendPushNotification = functions.https.onRequest(async (req, res) => {
  try {
    const { senderFcmToken, receiverFcmToken, senderUid, receiverUid } = req.body;

    if (!senderFcmToken || !receiverFcmToken || !senderUid || !receiverUid) {
      res.status(400).send('FCM Token, Sender UID, and Receiver UID are required');
      return;
    }

    // Generate UUID for the channel
    const channelUUID = uuidv4();

    // Generate LiveKit access tokens
    const roomName = `room-${channelUUID}`;

    // Sender's access token
    const senderAccessToken = new AccessToken(livekitApiKey, livekitApiSecret, {
      identity: senderUid,
    });
    senderAccessToken.addGrant({ roomJoin: true, room: roomName });
    const senderLivekitToken = await senderAccessToken.toJwt();

    // Receiver's access token
    const receiverAccessToken = new AccessToken(livekitApiKey, livekitApiSecret, {
      identity: receiverUid,
    });
    receiverAccessToken.addGrant({ roomJoin: true, room: roomName });
    const receiverLivekitToken = await receiverAccessToken.toJwt();

    // Prepare push notification message
    const message = {
      notification: {
        title: 'Hello!',
        body: 'You have a new notification.',
      },
      data: {
        senderFcmToken: senderFcmToken,
        receiverFcmToken: receiverFcmToken,
        livekitToken: receiverLivekitToken,
        channelUUID: channelUUID,
      },
      token: receiverFcmToken,
    };

    // Send push notification
    await admin.messaging().send(message);

    // Send response
    res.status(200).send({ message: 'Notification sent successfully', senderLivekitToken, channelUUID });
  } catch (error) {
    console.error('Error sending notification:', error);
    res.status(500).send('Error sending notification');
  }
});
