# Defendable Design for AWS
The [Defendable Design project](https://github.com/defendabledesign) builds standard, self-healing designs for strong security, using serverless and cloud-native tools.

Defendable Design for AWS (DD-AWS) uses [Terraform](https://www.terraform.io/) to orchestrate AWS-native functionality, including [AWS CloudTrail](https://aws.amazon.com/cloudtrail/), [AWS Config](https://aws.amazon.com/config/) and [AWS Lambda](https://aws.amazon.com/lambda/) to provide strong security fundamentals, monitoring and automatic response.


Deploying DD-AWS via Terraform:
* Uses [AWS KMS](https://aws.amazon.com/kms/) for encryption at rest
* Enables AWS Config
* Enables CloudTrail
* Configures an IAM password policy
* Deploys a series of Config Rules that check for common problems
* Configures alerts for dangerous CloudTrail events
* Deploys tools that automatically:
    * Reverse dangerous security group changes
    * Lock down public S3 buckets
* Deploys alert integration for Slack.

# How to get started
1. Install [Terraform](https://www.terraform.io/downloads.html)
1. Download and unpack the [latest release](https://github.com/DefendableDesign/DD-AWS/releases), or clone the whole repo.
1. [Configure AWS credentials](http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html)
1. **[Optional]** Create a Incoming Webhook for Slack
    1. Go to https://my.slack.com/services/new/incoming-webhook/
    1. Choose the channel where messages will be sent and click "Add Incoming WebHooks Integration".
    1. Copy the webhook URL and supply it as the `slack_webhook_url` variable to `terraform apply`.\
    Terraform will automatically encrypt the url for you.
1. **[Optional]** Enable auto-response for remediating violations:
    - Edit `terraform.tfvars` and change `enable_auto_response` from `"false"` to `"true"`
1. Set a region (defaults to Sydney):
    - Edit `terraform.tfvars` and change `region` to your preferred AWS region (refer to [AWS documentation for supported regions](http://docs.aws.amazon.com/general/latest/gr/rande.html#awsconfig_region))
1. From PowerShell run `./setup_remote_tfstate.ps1` to create an S3 bucket for storing your Terraform state
    - On a non-Windows system, create the state bucket and run `terraform init` manually.
1. Deploy:
    1. Run:
        - Without Slack integration: \
        `terraform apply`
        - With Slack integration: \
        `terraform apply -var "slack_webhook_url=https://hooks.slack.com/services/YOUR/WEBHOOK/URL/HERE"`
    1. Review the proposed changes to your AWS account
    1. Type `yes` when you're ready to go
