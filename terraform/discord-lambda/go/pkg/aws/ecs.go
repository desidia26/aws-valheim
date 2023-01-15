package aws

import (
	"fmt"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/ecs"
)

type ECSDetails struct {
	Region string
	Cluster string
	Service string
}

func UpdateEcsServiceCount(ecsDetails ECSDetails, taskCount int) (error) {
    sess := session.Must(session.NewSessionWithOptions(session.Options{
        Config: aws.Config{Region: aws.String(ecsDetails.Region)},
    }))

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

func GetDesiredCount(ecsDetails ECSDetails) (int64, error) {
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
	desiredTaskCount := *result.Services[0].DesiredCount

	return desiredTaskCount, nil;
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