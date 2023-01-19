package main

import (
	"context"
	"net/http"
	"os"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/desidia26/aws-valheim-go-lib/awslib"
	"github.com/desidia26/aws-valheim-go-lib/discord"
)

func handleRequest(ctx context.Context, request events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	sess := awslib.GetSession()
	ecsDetails := awslib.GetECSDetailsFromEnv()
	desiredTasks, _ := awslib.GetDesiredCount(ecsDetails, sess);
	if(desiredTasks == int64(0)) {
		return events.APIGatewayProxyResponse{
			StatusCode: http.StatusOK,
			Body: "Already scaled down",
		}, nil
	}
	if(!discord.PlayersAreConnected()) {
		awslib.UpdateEcsServiceCount(ecsDetails, 0, sess);
		domain := os.Getenv("DOMAIN")
		zoneId := os.Getenv("ZONE_ID")
		ip := "0.0.0.0"
		awslib.UpdateARecord(&ip, &domain, &zoneId, sess)
		return events.APIGatewayProxyResponse{
			StatusCode: http.StatusOK,
			Body: "Scaled down",
		}, nil
	}
	discord.GripeAtDiscord("Go to bed ya hooligans")
	return events.APIGatewayProxyResponse{
		StatusCode: http.StatusOK,
		Body: "Someone is playing. Not scaling down.",
	}, nil
}

func main() {
	lambda.Start(handleRequest)
}