package main

import (
	"errors"
	"time"
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

func schedulerWorker(ticker *time.Ticker, quit chan struct{}) {
	schedule()

	for {
		select {
		case <-ticker.C:
			schedule()
		case <-quit:
			log.Infof("Scheduler quitting\n")
			ticker.Stop()
			return
		}
	}
}

func schedule() {
	log.Info("Starting scheduling round")

	rows, err := db.Query("SELECT user_id FROM user_sessions, sessions;")
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
						err := rows.Scan(&o.ID, &o.UserID, &o.Day, &o.Hour)
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
						err := rows.Scan(&o.ID, &o.UserID, &o.Day, &o.Hour)
						if err != nil {
							log.Fatal(err)
						}

						user2Obligations = append(user2Obligations, o)
					}

					date, hour, err := findGap(user1Obligations, user2Obligations, 3)
					if err != nil {
						log.Infof("Could not find gap for users %s and %s", user1.Gid, user2.Gid)
						break
					}

					sessionID := 0
					// TODO: should this use exec?
					err = db.QueryRow("INSERT INTO sessions(day, hour, status) VALUES ($1, $2, $3) RETURNING id;", date, hour, "pending").Scan(&sessionID)
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

					log.Infof("Users %s and %s scheduled\n", user1.Gid, user2.Gid)
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

func hasFree(obligations []Obligation, day int, hour int) bool {
	for _, o := range obligations {
		if o.Day == day && o.Hour == hour {
			return false
		}
	}
	return true
}

// finds a time to schedule, between tomorrow and maxInAdvance, inclusive
func findGap(user1Obs []Obligation, user2Obs []Obligation, maxInAdvance int) (time.Time, int, error) {
	now := time.Now().In(time.UTC)
	for daysAhead := 1; daysAhead <= maxInAdvance; daysAhead++ {
		weekday := int(now.AddDate(0, 0, daysAhead).Weekday()) - 1
		if weekday == -1 {
			weekday = 6
		}

		for hour := 8; hour <= 17; hour++ {
			if hasFree(user1Obs, weekday, hour) && hasFree(user1Obs, weekday, hour) {
				return now.AddDate(0, 0, daysAhead), hour, nil
			}
		}
	}

	return now, -1, errors.New("Could not schedule users")
}
