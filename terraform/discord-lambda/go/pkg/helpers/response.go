package helpers

import (
	"encoding/json"
	"github.com/aws/aws-lambda-go/events"
)

func GetApiGateWayResponse (response string, code int) events.APIGatewayProxyResponse {
	json_response, _ := json.Marshal(response)
	return events.APIGatewayProxyResponse{
		StatusCode: code,
		Body:       string(json_response),
	}
}