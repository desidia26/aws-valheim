package awslib

import (
	"errors"
	"fmt"
	"os"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/ec2"
	"github.com/aws/aws-sdk-go/service/ecs"
)

type ECSDetails struct {
	Region string
	Cluster string
	Service string
}

func GetECSDetailsFromEnv() ECSDetails {
	return ECSDetails{
		Region: os.Getenv("REGION"),
		Service: os.Getenv("SERVICE_ARN"),
		Cluster: os.Getenv("CLUSTER_NAME"),
	}
}

func UpdateEcsServiceCount(ecsDetails ECSDetails, taskCount int, sess *session.Session) (error) {

    // Create an ECS service client
    ecsSvc := ecs.New(sess)

    // Define the desired count of the service
    desiredCount := int64(taskCount)

    // Update the desired count of the service
    _, err := ecsSvc.UpdateService(&ecs.UpdateServiceInput{
        Cluster:       aws.String(ecsDetails.Cluster),
        Service:       aws.String(ecsDetails.Service),
        DesiredCount:  &desiredCount,
    })
    return err
}

func GetDesiredCount(ecsDetails ECSDetails, sess *session.Session) (int64, error) {
	// Create an ECS client
	svc := ecs.New(sess)

	// Describe the service
	result, err := svc.DescribeServices(&ecs.DescribeServicesInput{
		Cluster:  aws.String(ecsDetails.Cluster),
		Services: []*string{aws.String(ecsDetails.Service)},
	})
	if err != nil {
		fmt.Println("Error describing service:", err)
		return 0, err
	}

	// Get the desired task count from the service description
	desiredTaskCount := *result.Services[0].DesiredCount

	return desiredTaskCount, nil;
}

func GetTaskPubIP(ecsDetails ECSDetails, sess *session.Session) (*string, error) {
	ecsSvc := ecs.New(sess)

	result, err := ecsSvc.ListTasks(&ecs.ListTasksInput{
		Cluster: aws.String(ecsDetails.Cluster),
		DesiredStatus: aws.String("RUNNING"),
	})
	if(err != nil) {
		fmt.Println("Failed to get tasks", err)
		return nil, err
	}
	taskArn := result.TaskArns[0]
	describeResult, err := ecsSvc.DescribeTasks(&ecs.DescribeTasksInput{
		Tasks: []*string{
				aws.String(*taskArn),
		},
		Cluster: aws.String(ecsDetails.Cluster),
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
		return nil, errors.New("Failed to get ENI ID!")
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
		return nil, err
	}
	return eniResult.NetworkInterfaces[0].Association.PublicIp, nil
}

func GetRunningCount(ecsDetails ECSDetails) (int64, error) {
    // Create an ECS client
    sess := session.Must(session.NewSessionWithOptions(session.Options{
        Config: aws.Config{Region: aws.String(ecsDetails.Region)},
    }))
	svc := ecs.New(sess)

	// Describe the service
	result, err := svc.DescribeServices(&ecs.DescribeServicesInput{
		Cluster:  aws.String(ecsDetails.Cluster),
		Services: []*string{aws.String(ecsDetails.Service)},
	})
	if err != nil {
		fmt.Println("Error describing service:", err)
		return 0, err
	}

	// Get the desired task count from the service description
	runningCount := *result.Services[0].RunningCount

	return runningCount, nil;
}