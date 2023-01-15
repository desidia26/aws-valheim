package helpers

import (
	"crypto/ed25519"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"os"
	"strings"

	"github.com/aws/aws-lambda-go/events"
	"github.com/bwmarrin/discordgo"
)

type DiscordCommandResponse struct {
	Type int `json:"type"`
	Data struct {
		Content string `json:"content"`
	} `json:"data"`
}

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
