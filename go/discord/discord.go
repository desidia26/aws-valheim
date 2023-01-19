package discord

import (
	"bytes"
	"crypto/ed25519"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
	"net/http/httptest"
	"os"
	"strings"

	"github.com/aws/aws-lambda-go/events"
	"github.com/bwmarrin/discordgo"
)

func GetDiscordCommandResponse (response string, code int) events.APIGatewayProxyResponse {
	discordResponse := DiscordCommandResponse{
		Type: 4, 
		Data: struct {
			Content string `json:"content"`
		}{Content: response},
	}
	json_response, _ := json.Marshal(discordResponse)
	return events.APIGatewayProxyResponse{
		StatusCode: code,
		Body:       string(json_response),
	}
}

func GetDiscordPingResponse (req events.APIGatewayProxyRequest) events.APIGatewayProxyResponse {
	discord_key, _ := hex.DecodeString(os.Getenv("DISCORD_KEY"))
	fmt.Println(discord_key)
	httpReq := httptest.NewRequest(req.HTTPMethod, req.Path, strings.NewReader(req.Body))
	for key, value := range req.Headers {
		httpReq.Header.Add(key, value)
	}
	if(discordgo.VerifyInteraction(httpReq, ed25519.PublicKey(discord_key))) {
		fmt.Println("Sending postive")
		return events.APIGatewayProxyResponse{
			StatusCode: http.StatusOK,
			Body:       req.Body,
		}
	} else {
		fmt.Println("Sending negative")
		return events.APIGatewayProxyResponse{
			StatusCode: http.StatusUnauthorized,
			Body: "invalid request signature",
		} 
	}
}

func GripeAtDiscord(text string) {
	message := DiscordMessage{Username: "Valheim-Bot", Content: text}
	messageJSON, _ := json.Marshal(message)

	resp, err := http.Post(os.Getenv("WEBHOOK"), "application/json", bytes.NewBuffer(messageJSON))
	if (err != nil) {
		defer resp.Body.Close()
		fmt.Println(resp.Status)
	} else {
		fmt.Println(err.Error())
	}
}

func PlayersAreConnected() bool {
	url := "http://"+os.Getenv("DOMAIN")+"/status.json"
	resp, err := http.Get(url)
	if err != nil {
			fmt.Println("Error:", err)
			return false
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
	return len(serverStatus.Players) != 0
}
