package main

import (
	"bufio"
	"bytes"
	"flag"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"sync"
	"text/template"
	"time"

	"github.com/joho/godotenv"
	pusher "github.com/pusher/pusher-http-go"
)

const (
	channelName = "realtime-terminal"
	eventName   = "logs"
)

func main() {

	var httpPort = flag.Int("http.port", 1500, "Port to run HTTP server on ?")

	flag.Parse()

	info, err := os.Stdin.Stat()
	if err != nil {
		log.Fatal(err)
	}

	if info.Mode()&os.ModeCharDevice != 0 {
		log.Println("This command is intended to be used as a pipe such as yourprogram | thisprogram")
		os.Exit(0)
	}

	if err := godotenv.Load(); err != nil {
		log.Fatal("Error loading .env file")
	}

	appID := os.Getenv("PUSHER_APP_ID")
	appKey := os.Getenv("PUSHER_APP_KEY")
	appSecret := os.Getenv("PUSHER_APP_SECRET")
	appCluster := os.Getenv("PUSHER_APP_CLUSTER")
	appIsSecure := os.Getenv("PUSHER_APP_SECURE")

	var isSecure bool
	if appIsSecure == "1" {
		isSecure = true
	}

	client := &pusher.Client{
		AppId:   appID,
		Key:     appKey,
		Secret:  appSecret,
		Cluster: appCluster,
		Secure:  isSecure,
		HttpClient: &http.Client{
			Timeout: time.Minute * 2,
		},
	}

	go func() {
		var t *template.Template
		var once sync.Once

		http.Handle("/static/", http.StripPrefix("/static/", http.FileServer(http.Dir("."))))

		http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {

			once.Do(func() {
				tem, err := template.ParseFiles("index.html")
				if err != nil {
					log.Fatal(err)
				}

				t = tem.Lookup("index.html")
			})

			t.Execute(w, nil)
		})
		log.Fatal(http.ListenAndServe(fmt.Sprintf(":%d", *httpPort), nil))
	}()

	reader := bufio.NewReader(os.Stdin)

	var writer io.Writer
	writer = pusherChannelWriter{client: client}

	for {
		in, _, err := reader.ReadLine()
		if err != nil && err == io.EOF {
			break
		}

		in = append(in, []byte("\n")...)
		if _, err := writer.Write(in); err != nil {
			log.Fatalln(err)
		}
	}
}

type pusherChannelWriter struct {
	client *pusher.Client
}

func (pusher pusherChannelWriter) Write(p []byte) (int, error) {
	s := string(p)
	dd := bytes.Split(p, []byte("\n"))

	var data = make([]string, 0, len(dd))

	for _, v := range dd {
		data = append(data, string(v))
	}

	_, err := pusher.client.Trigger(channelName, eventName, s)
	return len(p), err
}
