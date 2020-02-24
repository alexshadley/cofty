package main

import (
	"context"
	"database/sql"
	"fmt"
	"log"
	"time"

	_ "github.com/lib/pq"

	firebase "firebase.google.com/go"
	"firebase.google.com/go/messaging"
	"google.golang.org/api/option"
)

type StringSet struct {
	vals map[string]struct{}
}

func newStringSet() *StringSet {
	return &StringSet{vals: make(map[string]struct{})}
}

func (s *StringSet) Add(v string) {
	s.vals[v] = struct{}{}
}

func (s *StringSet) Has(v string) bool {
	_, ok := s.vals[v]
	return ok
}

var db *sql.DB
var err error

func schedule() {
	fmt.Println("scheduling")

	rows, err := db.Query("SELECT user_id FROM user_sessions, sessions WHERE sessions.pending = true;")
	if err != nil {
		log.Fatal(err)
	}

	// keeps track of all users so far scheduled
	scheduled := newStringSet()
	for rows.Next() {
		var id string
		err := rows.Scan(&id)
		if err != nil {
			log.Fatal(err)
		}

		scheduled.Add(id)
	}

	rows, err = db.Query("SELECT group_id, users.* FROM user_groups LEFT JOIN users ON user_groups.user_id = users.gid;")
	if err != nil {
		log.Fatal(err)
	}

	groupUsers := make(map[int][]User)
	var groupId int
	for rows.Next() {
		user := User{}
		err := rows.Scan(&groupId, &user.Gid, &user.Name, &user.MessagingToken)
		if err != nil {
			log.Fatal(err)
		}

		_, ok := groupUsers[groupId]
		if !ok {
			groupUsers[groupId] = make([]User, 0)
		}
		groupUsers[groupId] = append(groupUsers[groupId], user)
	}

	for _, users := range groupUsers {
		for _, user1 := range users {
			if scheduled.Has(user1.Gid) {
				continue
			}

			for _, user2 := range users {
				if user1.Gid != user2.Gid && !scheduled.Has(user2.Gid) {

					// get user obligations
					rows, err = db.Query("SELECT * FROM obligations WHERE user_id = $1;", user1.Gid)
					if err != nil {
						log.Fatal(err)
					}
					user1Obligations := make([]Obligation, 0)
					for rows.Next() {
						o := Obligation{}
						err := rows.Scan(&o.ID, &o.userID, &o.Day, &o.Hour)
						if err != nil {
							log.Fatal(err)
						}

						user1Obligations = append(user1Obligations, o)
					}

					rows, err = db.Query("SELECT * FROM obligations WHERE user_id = $1;", user2.Gid)
					if err != nil {
						log.Fatal(err)
					}
					user2Obligations := make([]Obligation, 0)
					for rows.Next() {
						o := Obligation{}
						err := rows.Scan(&o.ID, &o.userID, &o.Day, &o.Hour)
						if err != nil {
							log.Fatal(err)
						}

						user2Obligations = append(user2Obligations, o)
					}

					date, hour, err := findGap(user1Obligations, user2Obligations, 3)
					if err != nil {
						break
					}

					sessionID := 0
					// TODO: should this use exec?
					err = db.QueryRow("INSERT INTO sessions(day, hour, accepted, pending) VALUES ($1, $2, $3, $4) RETURNING id;", date, hour, false, true).Scan(&sessionID)
					if err != nil {
						log.Fatal(err)
					}

					_, err = db.Exec("INSERT INTO user_sessions(user_id, session_id) VALUES ($1, $2);",
						user1.Gid, sessionID)
					if err != nil {
						log.Fatal(err)
					}
					_, err = db.Exec("INSERT INTO user_sessions(user_id, session_id) VALUES ($1, $2);",
						user2.Gid, sessionID)
					if err != nil {
						log.Fatal(err)
					}

					fmt.Printf("Users %s and %s scheduled\n", user1.Gid, user2.Gid)
					scheduled.Add(user1.Gid)
					scheduled.Add(user2.Gid)

					sendSessionNotification(user1)
					sendSessionNotification(user2)
					break
				}
			}
		}
	}
}

func schedulerWorker(ticker *time.Ticker, quit chan struct{}) {
	for {
		select {
		case <-ticker.C:
			schedule()
		case <-quit:
			fmt.Println("Quitting")
			ticker.Stop()
			return
		}
	}
}

var messagingClient *messaging.Client
var messagingCtx context.Context

func main() {
	opt := option.WithCredentialsFile("/home/alex/Downloads/cofty-268422-firebase-adminsdk-wcpxt-8fe6ad9c1a.json")
	app, err := firebase.NewApp(context.Background(), nil, opt)
	if err != nil {
		fmt.Printf("error initializing app: %v", err)
		//return nil, fmt.Errorf("error initializing app: %v", err)
	}

	// Obtain a messaging.Client from the App.
	messagingCtx = context.Background()
	messagingClient, err = app.Messaging(messagingCtx)
	if err != nil {
		log.Fatalf("error getting Messaging client: %v\n", err)
	}

	connStr := "postgres://postgres:Taco2019!@34.70.136.195:5432/cofty"
	db, err = sql.Open("postgres", connStr)
	if err != nil {
		log.Fatal(err)
	}

	schedule()

	ticker := time.NewTicker(5 * time.Second)
	quit := make(chan struct{})
	go schedulerWorker(ticker, quit)

	<-quit
}

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
		fmt.Printf(err.Error())
	} else {
		// Response is a message ID string.
		fmt.Println("Successfully sent message:", response)
	}
}
