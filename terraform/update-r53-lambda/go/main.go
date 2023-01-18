package main

import (
	"context"
	"errors"
	"fmt"
	"net/http"
	"os"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/ec2"
	"github.com/aws/aws-sdk-go/service/ecs"
	"github.com/aws/aws-sdk-go/service/route53"
)

func updateR53() error {
	region := os.Getenv("REGION")
	domain := os.Getenv("DOMAIN")
	zoneId := os.Getenv("ZONE_ID")
	cluster := os.Getenv("CLUSTER_NAME")
	sess := session.Must(session.NewSessionWithOptions(session.Options{
		Config: aws.Config{Region: aws.String(region)},
	}))
	ecsSvc := ecs.New(sess)

	result, err := ecsSvc.ListTasks(&ecs.ListTasksInput{
		Cluster: aws.String(cluster),
		DesiredStatus: aws.String("RUNNING"),
	})
	if(err != nil) {
		fmt.Println("Failed to get tasks", err)
		return err
	}
	taskArn := result.TaskArns[0]
	describeResult, err := ecsSvc.DescribeTasks(&ecs.DescribeTasksInput{
		Tasks: []*string{
				aws.String(*taskArn),
		},
		Cluster: aws.String(cluster),
	})
	details := describeResult.Tasks[0].Attachments[0].Details;
	eniID := ""
	for _, detail := range details {
		if(*detail.Name == "networkInterfaceId") {
			eniID = *detail.Value;
			break
		}
	}
	if eniID == "" {
		return errors.New("Failed to get ENI ID!")
	}
	ec2Svc := ec2.New(sess)

	// Describe the ENI by its ID.
	eniResult, err := ec2Svc.DescribeNetworkInterfaces(&ec2.DescribeNetworkInterfacesInput{
		NetworkInterfaceIds: []*string{
						aws.String(eniID),
		},
	})
	if(err != nil) {
		fmt.Println("Failed to get eni", err)
		return err
	}
	pubIP := *eniResult.NetworkInterfaces[0].Association.PublicIp
	svc := route53.New(sess)

	input := &route53.ChangeResourceRecordSetsInput{
		ChangeBatch: &route53.ChangeBatch{
			Changes: []*route53.Change{
				{
					Action: aws.String("UPSERT"),
					ResourceRecordSet: &route53.ResourceRecordSet{
						Name: aws.String(domain),
						Type: aws.String("A"),
						ResourceRecords: []*route53.ResourceRecord{
							{
								Value: aws.String(pubIP),
							},
						},
						TTL: aws.Int64(300),
					},
				},
			},
			Comment: aws.String("Updating the A record"),
		},
		HostedZoneId: aws.String(zoneId),
	}

	r53Res, err := svc.ChangeResourceRecordSets(input)
	if err != nil {
		fmt.Println("Error updating Route53 A record: ", err)
		return err
	}

	fmt.Println("Successfully updated Route53 A record: ", r53Res)
	return nil
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