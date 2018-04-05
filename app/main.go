package main

import (
	"database/sql"
	"fmt"
	"html/template"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/go-sql-driver/mysql"
)

type statusData struct {
	Components []component
	Days       []day
}

type component struct {
	Name, Status string
}

type day struct {
	Date      time.Time
	Incidents []incident
}

type incident struct {
	Date               time.Time
	Title, Description string
}

type statusPageHandler struct {
	db *sql.DB
	t  *template.Template
}

func main() {

	d := os.Getenv("MYSQL_DATABASE")
	host := os.Getenv("MYSQL_HOST")
	port := os.Getenv("MYSQL_PORT")
	pw := os.Getenv("MYSQL_PASSWORD")
	user := os.Getenv("MYSQL_USER")

	db, err := sql.Open("mysql", fmt.Sprintf("%s:%s@tcp(%s:%s)/%s", user, pw, host, port, d))
	if err != nil {
		log.Fatalln(err)
	}
	defer db.Close()

	if err = db.Ping(); err != nil {
		log.Println(err)
	}

	tpl := template.Must(template.ParseFiles("index.html"))
	handler := &statusPageHandler{db: db, t: tpl}
	staticDir := "./static"

	http.HandleFunc("/favicon.ico", func(w http.ResponseWriter, r *http.Request) {
		http.ServeFile(w, r, "static/favicon.ico")
	})
	http.Handle("/static/", http.StripPrefix("/static/", http.FileServer(http.Dir(staticDir))))
	http.Handle("/", handler)

	log.Fatal(http.ListenAndServe(":8080", nil))
}

func (h *statusPageHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {

	w.Header().Set("Content-Type", "text/html")

	components, err := h.getComponents()
	if err != nil {
		components = []component{
			{Name: err.Error(), Status: "unknown"},
		}
	}

	incidents, err := h.getIncidents()
	if err != nil {
		incidents = []incident{
			{Date: time.Now(), Title: "Error", Description: err.Error()},
		}
	}

	var days []day
	start := time.Now()
	for d := start; d.After(start.AddDate(0, 0, -14)); d = d.AddDate(0, 0, -1) {
		nd := day{Date: d}
		for _, inc := range incidents {
			if inc.Date.YearDay() == d.YearDay() {
				nd.Incidents = append(nd.Incidents, inc)
			}
		}
		days = append(days, nd)
	}

	data := statusData{
		Components: components,
		Days:       days,
	}

	if err := h.t.Execute(w, data); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
	}
}

func (h *statusPageHandler) getComponents() ([]component, error) {

	var components []component

	rows, err := h.db.Query("SELECT name, status FROM components ORDER BY name")
	if err != nil {
		log.Println(err)
		return nil, err
	}
	defer rows.Close()

	for rows.Next() {
		var name string
		var status int
		if err := rows.Scan(&name, &status); err != nil {
			log.Println(err)
			continue
		}

		var statusStr string
		switch status {
		case 0:
			statusStr = "operational"
		case 1:
			statusStr = "partial outage"
		case 2:
			statusStr = "down"
		default:
			statusStr = "unknown"
		}

		components = append(components, component{Name: name, Status: statusStr})
	}

	return components, nil
}

func (h *statusPageHandler) getIncidents() ([]incident, error) {

	var incidents []incident

	rows, err := h.db.Query("SELECT datetime, title, description FROM incidents WHERE datetime > DATE_SUB(CURDATE(), INTERVAL 14 DAY) ORDER BY datetime DESC")
	if err != nil {
		log.Println(err)
		return nil, err
	}
	defer rows.Close()

	for rows.Next() {
		var date mysql.NullTime
		var title, description string
		if err := rows.Scan(&date, &title, &description); err != nil {
			log.Println(err)
			continue
		}

		if date.Valid {
			incidents = append(incidents, incident{Date: date.Time, Title: title, Description: description})
		}
	}

	return incidents, nil
}
