package main

import (
	"context"
	"net/http"
	"os"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/desidia26/aws-valheim-go-lib/awslib"
)

func updateR53() error {
	ecsDetails := awslib.GetECSDetailsFromEnv()
	domain := os.Getenv("DOMAIN")
	zoneId := os.Getenv("ZONE_ID")
	sess := awslib.GetSession()
	pubIP, err := awslib.GetTaskPubIP(ecsDetails, sess)
	if(err != nil) {
		return err
	}
	err = awslib.UpdateARecord(pubIP, &domain, &zoneId, sess)
	return err
}

func handleRequest(ctx context.Context, request events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	err := updateR53()
	if (err != nil) {
		return events.APIGatewayProxyResponse{
			StatusCode: http.StatusInternalServerError,
			Body: err.Error(),
		}, nil
	}
	return events.APIGatewayProxyResponse{
		StatusCode: http.StatusOK,
		Body: "Success",
	}, nil
}

func main() {
	lambda.Start(handleRequest)
}