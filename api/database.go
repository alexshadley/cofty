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
	err = db.QueryRow("INSERT INTO sessions(day, hour, status) VALUES ($1, $2, $3) RETURNING id;", date, hour, "pending").Scan(&sessionID)
	if err != nil {
		log.Fatal(err)
	}

	return sessionID
}

func addUserToSession(user User, sessionID int) {
	_, err = db.Exec("INSERT INTO user_sessions(user_id, session_id, status) VALUES ($1, $2, 'pending');",
		user.Gid, sessionID)
	if err != nil {
		log.Fatal(err)
	}
}

func getAvailability(user User) Availability {
	return Availability{
		obligations: getObligations(user),
		sessions:    getSessions(user),
	}
}

func getObligations(user User) []Obligation {
	obligations := []Obligation{}
	err := db.Select(&obligations, "SELECT * FROM obligations WHERE user_id = $1;", user.Gid)
	if err != nil {
		log.Fatal(err)
	}

	return obligations
}

func getSessions(user User) []Session {
	sessions := []Session{}
	err := db.Select(&sessions, "SELECT sessions.* FROM sessions JOIN user_sessions ON sessions.id = user_sessions.session_id WHERE user_id = $1;", user.Gid)
	if err != nil {
		log.Fatal(err)
	}

	return sessions
}
