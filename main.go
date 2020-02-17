package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"os"

	"github.com/gorilla/mux"
	"github.com/jinzhu/gorm"
	_ "github.com/jinzhu/gorm/dialects/postgres"
	_ "github.com/jinzhu/gorm/dialects/sqlite"
)

var (
	db  *gorm.DB
	err error
)

type User struct {
	Gid    string   `json:"gid" gorm:"PRIMARY_KEY"`
	Name   string   `json:"name"`
	Groups []*Group `json:"groups" gorm:"many2many:user_groups";`
}

type Group struct {
	ID         int     `json:"id" gorm:"PRIMARY_KEY;AUTO_INCREMENT"`
	AccessCode string  `json:"access_code"`
	Users      []*User `json:"users" gorm:"many2many:user_groups";`
}

func register(w http.ResponseWriter, r *http.Request) {
	reqBody, err := ioutil.ReadAll(r.Body)
	if err != nil {
		fmt.Fprintf(w, "no body supplied")
		return
	}

	newUser := User{}
	json.Unmarshal(reqBody, &newUser)

	existingUser := User{}
	if !db.First(&existingUser, "gid=?", newUser.Gid).RecordNotFound() {
		w.WriteHeader(http.StatusBadRequest)
		return
	}

	db.Create(&newUser)

	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(newUser)
}

func getUser(w http.ResponseWriter, r *http.Request) {
	gid := r.URL.Query().Get("gid")

	user := User{}
	if db.Preload("Groups").First(&user, "gid=?", gid).RecordNotFound() {
		w.WriteHeader(http.StatusBadRequest)
		return
	}

	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(user)
}

func createGroup(w http.ResponseWriter, r *http.Request) {
	reqBody, err := ioutil.ReadAll(r.Body)
	if err != nil {
		fmt.Fprintf(w, "no body supplied")
		return
	}

	creatingUser := User{}
	json.Unmarshal(reqBody, &creatingUser)

	if db.First(&creatingUser, "gid=?", creatingUser.Gid).RecordNotFound() {
		w.WriteHeader(http.StatusBadRequest)
		return
	}

	newGroup := Group{AccessCode: "AAABBB", Users: []*User{&creatingUser}}
	db.Create(&newGroup)

	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(newGroup)
}

func getGroup(w http.ResponseWriter, r *http.Request) {
	id := r.URL.Query()["id"]

	group := Group{}
	if db.Preload("Users").First(&group, "id=?", id).RecordNotFound() {
		w.WriteHeader(http.StatusBadRequest)
		return
	}

	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(group)
}

func joinGroup(w http.ResponseWriter, r *http.Request) {
	userGID, ok1 := r.URL.Query()["user_gid"]
	groupID, ok2 := r.URL.Query()["group_id"]

	if !ok1 || !ok2 {
		w.WriteHeader(http.StatusBadRequest)
		return
	}

	user := User{}
	if db.First(&user, "gid=?", userGID).RecordNotFound() {
		w.WriteHeader(http.StatusBadRequest)
		return
	}

	group := Group{}
	if db.Preload("Users").First(&group, "id=?", groupID).RecordNotFound() {
		w.WriteHeader(http.StatusBadRequest)
		return
	}

	for _, u := range group.Users {
		if u.Gid == user.Gid {
			w.WriteHeader(http.StatusBadRequest)
			return
		}
	}

	db.Model(&group).Association("Users").Append(&user)

	w.WriteHeader(http.StatusCreated)
	fmt.Fprintf(w, "user added to group")
}

func main() {
	dbPass := os.Getenv("COFTY_DB_PASSWORD")
	dbArgs := fmt.Sprintf("host=34.70.136.195 port=5432 user=postgres dbname=cofty password=%v", dbPass)
	db, err = gorm.Open("postgres", dbArgs)

	if err != nil {
		panic("failed to connect database")
	}
	defer db.Close()

	db.AutoMigrate(&User{}, &Group{})

	r := mux.NewRouter()
	r.HandleFunc("/register", register).Methods(http.MethodPost)
	r.HandleFunc("/user", getUser).Methods(http.MethodGet)

	r.HandleFunc("/group", createGroup).Methods(http.MethodPost)
	r.HandleFunc("/group", getGroup).Methods(http.MethodGet)

	r.HandleFunc("/group/join", joinGroup).Methods(http.MethodPost)

	log.Fatal(http.ListenAndServe(":8080", r))
}
