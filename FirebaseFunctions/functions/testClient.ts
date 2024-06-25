const axios = require('axios');

const sendNotification = async (fcmToken) => {
  try {
    

    const response = await axios.post('https://us-central1-tentenios.cloudfunctions.net/sendPushNotification', {
      fcmToken: fcmToken,
    });
    console.log(response.data);
  } catch (error) {
    console.error('Error sending notification:', error);
  }
};

sendNotification(
    'fVHGnlwzwkcriZGCxPIjS1:APA91bG3GtFAmEVH9pzIBbWQqe89QkcQCfEAuHFgdHymS-9diI6XqiY3XMskZp_ibScpbU4eg5ls90U3SlAqYRh_4T3BJvv4oxE5jCxaFeHELikCCKCmICgmNG95ner6--1G51SPAfVN'
);
