package main

type User struct {
	Gid            string `json:"gid" gorm:"PRIMARY_KEY"`
	Name           string `json:"name"`
	MessagingToken string `json:"name"`
}

type Group struct {
	ID         int    `json:"id"`
	Name       string `json:"name"`
	AccessCode string `json:"access_code"`
}

type Obligation struct {
	ID     int
	userID string
	Day    int
	Hour   int
}
