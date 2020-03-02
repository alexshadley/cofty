package main

import (
	"errors"
	"math/rand"
	"time"
)

// how many pending sessions a user can have
var maxSessions = 2

// how many pending sessions a user can have with another user
var maxPairings = 1

type MultiSet struct {
	vals map[string]int
}

func newMultiSet() *MultiSet {
	return &MultiSet{vals: make(map[string]int)}
}

func (s *MultiSet) Add(v string) {
	if _, ok := s.vals[v]; ok {
		s.vals[v]++
	} else {
		s.vals[v] = 1
	}
}

func (s *MultiSet) Has(v string) bool {
	_, ok := s.vals[v]
	return ok
}

func (s *MultiSet) Count(v string) int {
	count, ok := s.vals[v]
	if ok {
		return count
	} else {
		return 0
	}
}

func (s *MultiSet) Size() int {
	return len(s.vals)
}

type SessionSet struct {
	vals map[string]*MultiSet
}

func newSessionSet() *SessionSet {
	return &SessionSet{vals: make(map[string]*MultiSet)}
}

func (s *SessionSet) Add(userID string, otherID string) {
	if _, ok := s.vals[userID]; ok {
		s.vals[userID].Add(otherID)
	} else {
		set := newMultiSet()
		set.Add(otherID)
		s.vals[userID] = set
	}
}

func (s *SessionSet) CountPair(userID string, otherID string) int {
	if _, ok := s.vals[userID]; ok {
		return s.vals[userID].Count(otherID)
	} else {
		return 0
	}
}

func (s *SessionSet) Count(userID string) int {
	if _, ok := s.vals[userID]; ok {
		return s.vals[userID].Size()
	}
	return 0
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

	rows, err := db.Query("SELECT session_id, user_id FROM user_sessions, sessions WHERE sessions.day >= $1 AND user_sessions.status != 'rejected' ORDER BY session_id;", time.Now().In(time.UTC))
	if err != nil {
		log.Fatal(err)
	}

	// keeps track of all users so far scheduled
	scheduled := newSessionSet()

	inSession := newMultiSet()
	userID := ""
	lastSessionID := ""
	sessionID := ""
	for rows.Next() {
		err := rows.Scan(&sessionID, &userID)
		if err != nil {
			log.Fatal(err)
		}

		if sessionID == lastSessionID || lastSessionID == "" {
			inSession.Add(userID)
		} else {
			for user, _ := range inSession.vals {
				for other, _ := range inSession.vals {
					if user != other {
						scheduled.Add(user, other)
					}
				}
			}
			inSession = newMultiSet()
		}
		lastSessionID = sessionID
	}

	// one last time, since last sessionID won't change
	for user, _ := range inSession.vals {
		for other, _ := range inSession.vals {
			if user != other {
				scheduled.Add(user, other)
			}
		}
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
			if scheduled.Count(user1.Gid) >= maxSessions {
				continue
			}

			// construct an ordering of other users to attempt to schedule with. For now, random is fine
			prefList := make([]User, len(users))
			copy(prefList, users)
			rand.Seed(time.Now().UnixNano())
			rand.Shuffle(len(prefList), func(i, j int) { prefList[i], prefList[j] = prefList[j], prefList[i] })

			for _, user2 := range prefList {

				if user1.Gid != user2.Gid && scheduled.Count(user2.Gid) < maxSessions &&
					scheduled.CountPair(user1.Gid, user2.Gid) < maxPairings {
					// get user obligations
					user1Obligations := getObligations(user1)
					user2Obligations := getObligations(user2)

					date, hour, err := findGap(user1Obligations, user2Obligations, 3)
					if err != nil {
						log.Infof("Could not find gap for users %s and %s", user1.Gid, user2.Gid)
						break
					}

					sessionID := addSession(date, hour)
					addUserToSession(user1, sessionID)
					addUserToSession(user2, sessionID)

					log.Infof("Users %s and %s scheduled\n", user1.Gid, user2.Gid)
					scheduled.Add(user1.Gid, user2.Gid)
					scheduled.Add(user2.Gid, user1.Gid)

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
			if hasFree(user1Obs, weekday, hour) && hasFree(user2Obs, weekday, hour) {
				return now.AddDate(0, 0, daysAhead), hour, nil
			}
		}
	}

	return now, -1, errors.New("Could not schedule users")
}
