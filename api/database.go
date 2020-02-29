package main

import "time"

func setUserSessionStatus(sessionID int, userID string, status string) bool {
	_, err := db.Exec("UPDATE user_sessions SET status = $1 WHERE session_id = $2 AND user_id = $3", status, sessionID, userID)
	if err != nil {
		log.Fatal(err)
	}

	return true
}

func setSessionConfirmed(sessionID int, status string) bool {
	_, err := db.Exec("UPDATE sessions SET status = $1 WHERE id = $2", status, sessionID)
	if err != nil {
		log.Fatal(err)
	}

	return true
}

func getSessionUsers(sessionID int) []UserSession {
	userSessions := []UserSession{}
	err := db.Select(&userSessions, "SELECT user_id, session_id, status FROM user_sessions WHERE session_id = $1", sessionID)
	if err != nil {
		log.Fatal(err)
	}

	return userSessions
}

func addSession(date time.Time, hour int) int {
	sessionID := 0
	// TODO: should this use exec?
	err = db.QueryRow("INSERT INTO sessions(day, hour, accepted, pending) VALUES ($1, $2, $3, $4) RETURNING id;", date, hour, "pending").Scan(&sessionID)
	if err != nil {
		log.Fatal(err)
	}

	return sessionID
}
