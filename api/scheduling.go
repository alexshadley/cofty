package main

import (
	"errors"
	"time"
)

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
		weekday := (now.AddDate(0, 0, daysAhead).Weekday() + 1) % 6

		for hour := 8; hour <= 17; hour++ {
			if hasFree(user1Obs, int(weekday), hour) && hasFree(user1Obs, int(weekday), hour) {
				return now.AddDate(0, 0, daysAhead), hour, nil
			}
		}
	}

	return now, -1, errors.New("Could not schedule users")
}
