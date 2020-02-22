package main

import (
	"context"
	"fmt"
	"log"
	"time"

	firebase "firebase.google.com/go"
	"firebase.google.com/go/messaging"
	"google.golang.org/api/option"
)

func schedulerWorker(ticker *time.Ticker, quit chan struct{}) {
	for {
		select {
		case <-ticker.C:
			fmt.Println("Time elapsed!")
		case <-quit:
			fmt.Println("Quitting")
			ticker.Stop()
			return
		}
	}
}

func main() {
	ticker := time.NewTicker(5 * time.Second)
	quit := make(chan struct{})
	go schedulerWorker(ticker, quit)

	<-quit
}

func main2() {
	opt := option.WithCredentialsFile("/home/alex/Downloads/cofty-268422-firebase-adminsdk-wcpxt-8fe6ad9c1a.json")
	app, err := firebase.NewApp(context.Background(), nil, opt)
	if err != nil {
		fmt.Printf("error initializing app: %v", err)
		//return nil, fmt.Errorf("error initializing app: %v", err)
	}

	// Obtain a messaging.Client from the App.
	ctx := context.Background()
	client, err := app.Messaging(ctx)
	if err != nil {
		log.Fatalf("error getting Messaging client: %v\n", err)
	}

	// This registration token comes from the client FCM SDKs.
	registrationToken := "cHW7_fokCLY:APA91bEAcvcbMvd-YDkIA9d3UTrwfXujGL8vbfdf482MynIm5xwARvm0IVVhyqcx_tFJx963BM3yxDE10K3t0T83MhpTyXnJZzZ4BN21IqL6NZE9SwK0tzSJIN8x8E1_af9R2QdScrIk"

	// See documentation on defining a message payload.
	message := &messaging.Message{
		Notification: &messaging.Notification{
			Title: "Howdy Partner",
			Body:  "Yeehaw",
		},
		Token: registrationToken,
	}

	// Send a message to the device corresponding to the provided
	// registration token.
	response, err := client.Send(ctx, message)
	if err != nil {
		log.Fatalln(err)
	}
	// Response is a message ID string.
	fmt.Println("Successfully sent message:", response)

}
