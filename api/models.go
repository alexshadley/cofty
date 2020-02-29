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
	UserID string
	Day    int
	Hour   int
}

type UserSession struct {
	UserID    string `db:"user_id"`
	SessionID int    `db:"session_id"`
	Status    string
}
