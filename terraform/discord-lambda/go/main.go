package main

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"os"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/desidia26/valheim-discord-lambda/pkg/aws"
	"github.com/desidia26/valheim-discord-lambda/pkg/helpers"
)

func handleRequest(ctx context.Context, request events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {

	var cmd helpers.DiscordCommand
	err := json.Unmarshal([]byte(request.Body), &cmd)
	if err != nil {
			fmt.Println("Failed to parse json")
			fmt.Println(err)
	}
	if cmd.Type == float64(1) {
		fmt.Println("Sending discord ping reply!")
		return helpers.GetDiscordPingResponse(request), nil
	}
	fmt.Println("request : "+cmd.Data.Name)

	ecsDetails := aws.ECSDetails{
		Region: os.Getenv("REGION"),
		Service: os.Getenv("SERVICE_ARN"),
		Cluster: os.Getenv("CLUSTER_NAME"),
	}

	desiredCount, err := aws.GetDesiredCount(ecsDetails);
	if(err != nil) {
		fmt.Println(err)
		return helpers.GetDiscordCommandResponse(err.Error(), http.StatusOK), nil
	}
	runningCount, err := aws.GetRunningCount(ecsDetails);
	if(err != nil) {
		fmt.Println(err)
		return helpers.GetDiscordCommandResponse(err.Error(), http.StatusOK), nil
	}
	switch cmd.Data.Name {
		case "valheimserverstart":
			if(desiredCount == int64(0)) {
				err := aws.UpdateEcsServiceCount(ecsDetails, 1)
				if (err != nil) {
					fmt.Println(err)
					return helpers.GetDiscordCommandResponse("Failed to kick off server. Go yell at Ben...", http.StatusOK), nil
				} else {
					return helpers.GetDiscordCommandResponse("Kicking off server!", http.StatusOK), nil
				}
			} else {
				return helpers.GetDiscordCommandResponse("Server already running!", http.StatusOK), nil
			}
		case "valheimserverstatus":
			return helpers.GetDiscordCommandResponse(
				fmt.Sprintf("Desired count: %d\nRunning count: %d", desiredCount, runningCount), http.StatusOK), nil
		default:
			return helpers.GetDiscordCommandResponse(
				fmt.Sprintf("Command %s not recognized!", cmd.Data.Name), http.StatusBadRequest,
			), nil
	}
}

func main() {
	lambda.Start(handleRequest)
}