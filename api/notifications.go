package main

import "firebase.google.com/go/messaging"

func sendSessionNotification(user User) {
	// See documentation on defining a message payload.
	message := &messaging.Message{
		Notification: &messaging.Notification{
			Title: "You have a new coffee invite!",
			Body:  "Check it out in the app",
		},
		Token: user.MessagingToken,
	}

	// Send a message to the device corresponding to the provided
	// registration token.
	response, err := messagingClient.Send(messagingCtx, message)
	if err != nil {
		log.Errorf(err.Error())
	} else {
		// Response is a message ID string.
		log.Infof("Successfully sent message:", response)
	}
}
