package main

import (
	"context"
	"fmt"
	"net/http"
	"net/http/httputil"
	"net/url"
	"os"
	"strconv"
	"time"

	_ "github.com/lib/pq"

	firebase "firebase.google.com/go"
	"firebase.google.com/go/messaging"
	"github.com/gorilla/mux"
	"github.com/jmoiron/sqlx"
	"github.com/op/go-logging"
	"google.golang.org/api/option"
)

var db *sqlx.DB
var err error

var log = logging.MustGetLogger("example")

// Example format string. Everything except the message has a custom color
// which is dependent on the log level. Many fields have a custom output
// formatting too, eg. the time returns the hour down to the milli second.
var format = logging.MustStringFormatter(
	`%{color}%{time:15:04:05.000} %{shortfile} %{shortfunc} ▶ %{level:.4s} %{id:03x}%{color:reset} %{message}`,
)

var messagingClient *messaging.Client
var messagingCtx context.Context

func main() {
	backend := logging.NewLogBackend(os.Stdout, "", 0)
	formatter := logging.NewBackendFormatter(backend, format)
	logging.SetBackend(formatter)

	opt := option.WithCredentialsFile("./cofty_firebase_creds.json")
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
	db, err = sqlx.Open("postgres", connStr)
	if err != nil {
		log.Fatal(err)
	}

	ticker := time.NewTicker(time.Hour)
	quit := make(chan struct{})
	go schedulerWorker(ticker, quit)

	r := mux.NewRouter()

	r.HandleFunc("/attendSession", attendSession)
	r.HandleFunc("/admin/schedule", runSchedule)
	r.PathPrefix("/").HandlerFunc(postgrestProxy)

	log.Fatal(http.ListenAndServe(":8080", r))
}

func attendSession(w http.ResponseWriter, r *http.Request) {
	sessionID, _ := strconv.Atoi(r.FormValue("session_id"))
	userID := r.FormValue("user_id")
	status := r.FormValue("status")

	setUserSessionStatus(sessionID, userID, status)

	userSessions := getSessionUsers(sessionID)

	accepted := 0
	rejected := 0
	for _, u := range userSessions {
		if u.Status == "accepted" {
			accepted++
		} else if u.Status == "rejected" {
			rejected++
		}
	}

	log.Infof("After user %s sets session %d status to %s: %d accepted, %d rejected\n",
		userID, sessionID, status, accepted, rejected)
	if accepted >= 2 {
		setSessionConfirmed(sessionID, "accepted")
	} else if rejected >= 1 {
		setSessionConfirmed(sessionID, "rejected")
	}

	fmt.Fprint(w, "{}")
}

func runSchedule(w http.ResponseWriter, r *http.Request) {
	go schedule()

	fmt.Fprint(w, "ok")
}

func postgrestProxy(w http.ResponseWriter, r *http.Request) {
	url, _ := url.Parse("http://localhost:3000")
	proxy := httputil.NewSingleHostReverseProxy(url)

	proxy.ServeHTTP(w, r)
}
