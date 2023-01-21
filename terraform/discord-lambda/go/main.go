package main

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/desidia26/aws-valheim-go-lib/awslib"
	"github.com/desidia26/aws-valheim-go-lib/discord"
)

func handleRequest(ctx context.Context, request events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	var cmd discord.DiscordCommand
	sess := awslib.GetSession()
	err := json.Unmarshal([]byte(request.Body), &cmd)
	if err != nil {
			fmt.Println("Failed to parse json")
			fmt.Println(err)
	}
	if cmd.Type == float64(1) {
		fmt.Println("Sending discord ping reply!")
		return discord.GetDiscordPingResponse(request), nil
	}
	fmt.Println("request : "+cmd.Data.Name)
	ecsDetails := awslib.GetECSDetailsFromEnv()
	
	desiredCount, err := awslib.GetDesiredCount(ecsDetails, sess);
	if(err != nil) {
		fmt.Println(err)
		return discord.GetDiscordCommandResponse(err.Error(), http.StatusOK), nil
	}
	runningCount, err := awslib.GetRunningCount(ecsDetails);
	if(err != nil) {
		fmt.Println(err)
		return discord.GetDiscordCommandResponse(err.Error(), http.StatusOK), nil
	}
	switch cmd.Data.Name {
		case "valheimserverstart":
			if(desiredCount == int64(0)) {
				err := awslib.UpdateEcsServiceCount(ecsDetails, 1, sess)
				if (err != nil) {
					fmt.Println(err)
					return discord.GetDiscordCommandResponse("Failed to kick off server. Go yell at Ben...", http.StatusOK), nil
				} else {
					return discord.GetDiscordCommandResponse("Kicking off server!", http.StatusOK), nil
				}
			} else {
				return discord.GetDiscordCommandResponse("Server already running!", http.StatusOK), nil
			}
		case "valheimserverstatus":
			playerCount, _ := discord.GetPlayerCount();
			return discord.GetDiscordCommandResponse(
				fmt.Sprintf("Desired count: %d\nRunning count: %d\nPlayer count: %d", desiredCount, runningCount, playerCount), http.StatusOK), nil
		default:
			return discord.GetDiscordCommandResponse(
				fmt.Sprintf("Command %s not recognized!", cmd.Data.Name), http.StatusBadRequest,
			), nil
	}
}

func main() {
	lambda.Start(handleRequest)
}