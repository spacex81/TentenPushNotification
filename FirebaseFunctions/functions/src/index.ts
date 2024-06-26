import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { AccessToken } from 'livekit-server-sdk';
import { v4 as uuidv4 } from 'uuid';

admin.initializeApp();

const livekitApiKey = 'API4vY5fJ6zxS6e';
const livekitApiSecret = 'GGqV7dBkfi4mtBwK1UD1EvJCLRQCouB7YcDSwyR07MR';
const livekitHost = 'wss://tentwenty-bp8gb2jg.livekit.cloud';

export const sendPushNotification = functions.https.onRequest(async (req, res) => {
  try {
    const { fcmToken, senderUid, receiverUid } = req.body;

    if (!fcmToken || !senderUid || !receiverUid) {
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
        livekitToken: receiverLivekitToken,
        channelUUID: channelUUID,
      },
      token: fcmToken,
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
