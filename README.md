# Text Messenger (Cloud Refactor)

This repository is refactored version of my [previous project](https://github.com/kperdek8/text-messenger) adjusted for cloud deployment on AWS.
It was part of 'Design and implementation of cloud systems' course on PWR during which application was prepared for three deployment scenarios:
* Monolithic Application - The rewrite included support for AWS S3, RDS, and Cognito, and utilized AWS Elastic Beanstalk for deployment.
* Microservices - The monolithic application was split into independent microservices and deployed via AWS Fargate, using AWS SQS as a message queue for communication.
* Serverless (AWS Lambda) - The application's logic was refactored to run on AWS Lambda with exception of live sockets.
