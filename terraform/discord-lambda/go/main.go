package main

import (
	"context"
	"fmt"
	"net/http"
	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/desidia26/valheim-discord-lambda/pkg/helpers"
)

func handleRequest(ctx context.Context, request events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	command, _ := request.QueryStringParameters["command"];
	switch command {
		case "stuff":
			return helpers.GetApiGateWayResponse("stuff!", http.StatusOK), nil
		case "things":
			return helpers.GetApiGateWayResponse("and things!", http.StatusOK), nil
		default:
			return helpers.GetApiGateWayResponse(
				fmt.Sprintf("Command %s not recognized!", command), http.StatusBadRequest,
			), nil
	}
}

func main() {
	lambda.Start(handleRequest)
}