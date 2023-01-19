module github.com/desidia26/valheim-nightly-lambda

go 1.19

require (
	github.com/aws/aws-lambda-go v1.37.0
	github.com/desidia26/aws-valheim-go-lib v0.0.0
)

require (
	github.com/aws/aws-sdk-go v1.44.182 // indirect
	github.com/jmespath/go-jmespath v0.4.0 // indirect
)

replace github.com/desidia26/aws-valheim-go-lib v0.0.0 => ../../../go
