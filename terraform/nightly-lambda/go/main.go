package main

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
	"os"
	"time"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/desidia26/valheim-discord-lambda/pkg/aws"
)

type ServerStatus struct {
	LastStatusUpdate time.Time     `json:"last_status_update"`
	Error            error         `json:"error"`
	ServerName       string        `json:"server_name"`
	ServerType       string        `json:"server_type"`
	Platform         string        `json:"platform"`
	PlayerCount      int           `json:"player_count"`
	PasswordProtected bool          `json:"password_protected"`
	VacEnabled       bool          `json:"vac_enabled"`
	Port             int           `json:"port"`
	SteamID          int64         `json:"steam_id"`
	Keywords         string        `json:"keywords"`
	GameID           int           `json:"game_id"`
	Players          []interface{} `json:"players"`
}

type DiscordMessage struct {
	Username string `json:"username"`
	Content  string `json:"content"`
}

func gripeAtDiscord() {
		message := DiscordMessage{Username: "Valheim-Bot", Content: "Go to bed ya hooligans"}
    messageJSON, _ := json.Marshal(message)

    resp, err := http.Post(os.Getenv("WEBHOOK"), "application/json", bytes.NewBuffer(messageJSON))
		if (err != nil) {
			defer resp.Body.Close()
			fmt.Println(resp.Status)
		} else {
			fmt.Println(err.Error())
		}
}

func playersAreConnected() bool {
	url := "http://"+os.Getenv("DOMAIN")+"/status.json"
	resp, err := http.Get(url)
	if err != nil {
			fmt.Println("Error:", err)
			return true
	}
	defer resp.Body.Close()

	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
			fmt.Println("Error:", err)
			return true
	}

	var serverStatus ServerStatus
	err = json.Unmarshal(body, &serverStatus)
	if err != nil {
			fmt.Println("Error:", err)
			return true
	}
	return len(serverStatus.Players) == 0
}

func handleRequest(ctx context.Context, request events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {

	ecsDetails := aws.ECSDetails{
		Region: os.Getenv("REGION"),
		Service: os.Getenv("SERVICE_ARN"),
		Cluster: os.Getenv("CLUSTER_NAME"),
	}
	if(!playersAreConnected()) {
		aws.UpdateEcsServiceCount(ecsDetails, 0);
		return events.APIGatewayProxyResponse{
			StatusCode: http.StatusOK,
			Body: "Scaled down",
		}, nil
	}
	gripeAtDiscord()
	return events.APIGatewayProxyResponse{
		StatusCode: http.StatusOK,
		Body: "Someone is playing. Not scaling down.",
	}, nil
}

func main() {
	lambda.Start(handleRequest)
}