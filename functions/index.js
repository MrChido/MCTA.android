const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.sendThreeDayReminder = functions.pubsub
  .schedule('0 10 */3 * *')  // Run at 10:00 AM every 3 days
  .timeZone('America/Los_Angeles') // Adjust to your timezone
  .onRun(async (context) => {
    try {
      // Get all device tokens (you'll need to implement token storage)
      const tokens = await admin.firestore()
        .collection('device_tokens')
        .get()
        .then(snapshot => snapshot.docs.map(doc => doc.data().token));

      if (tokens.length === 0) {
        console.log('No devices to notify');
        return null;
      }

      // Notification payload
      const message = {
        notification: {
          title: 'Spoonie Check-In',
          body: 'How are you feeling today? Care to log your symptoms?'
        },
        android: {
          notification: {
            channelId: 'spoonie_channel',
            priority: 'high',
            defaultSound: true,
            defaultVibrateTimings: true
          }
        }
      };

      // Send to all devices
      const response = await admin.messaging().sendMulticast({
        tokens,
        ...message
      });

      console.log('Successfully sent messages:', response.successCount);
      if (response.failureCount > 0) {
        console.log('Failed to send some messages:', response.failureCount);
      }

      return null;
    } catch (error) {
      console.error('Error sending notifications:', error);
      return null;
    }
  });