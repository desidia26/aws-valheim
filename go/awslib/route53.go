package awslib

import (
	"fmt"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/route53"
)

func UpdateARecord(ip *string, domain *string, zoneId *string, sess *session.Session) error {
	svc := route53.New(sess)
	input := &route53.ChangeResourceRecordSetsInput{
		ChangeBatch: &route53.ChangeBatch{
			Changes: []*route53.Change{
				{
					Action: aws.String("UPSERT"),
					ResourceRecordSet: &route53.ResourceRecordSet{
						Name: domain,
						Type: aws.String("A"),
						ResourceRecords: []*route53.ResourceRecord{
							{
								Value: ip,
							},
						},
						TTL: aws.Int64(300),
					},
				},
			},
			Comment: aws.String("Updating the A record"),
		},
		HostedZoneId: zoneId,
	}

	_, err := svc.ChangeResourceRecordSets(input)
	if err != nil {
		fmt.Println("Error updating Route53 A record: ", err)
		return err
	}
	return nil
}