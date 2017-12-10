# Defendable Design for AWS
The [Defendable Design project](https://github.com/defendabledesign) attempts to build standard, self-healing designs for strong security.

Defendable Design for AWS (DD-AWS) uses [Terraform](https://www.terraform.io/) to orchestrate AWS-native functionality, including [AWS CloudTrail](https://aws.amazon.com/cloudtrail/), [AWS Config](https://aws.amazon.com/config/) and [AWS Lambda](https://aws.amazon.com/lambda/).

The Terraform code:
* Enables AWS Config
* Deploys a series of Config Rules that check for common problems
* Creates a Lambda function that can automatically reverse dangerous security group changes.

# How to get started
1. Install [Terraform](https://www.terraform.io/downloads.html)
1. Download and unpack the [latest release](https://github.com/DefendableDesign/DD-AWS/releases), or clone the whole repo.
1. [Configure AWS credentials](http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html)
1. **[Optional]** Enable auto-response for remediating violations:
    - Edit `terraform.tfvars` and change `enable_auto_response` from `"false"` to `"true"`
1. Set a region (defaults to Sydney):
    - Edit `terraform.tfvars` and change `region` to your preferred AWS region (refer to [AWS documentation for supported regions](http://docs.aws.amazon.com/general/latest/gr/rande.html#awsconfig_region))
1. Run `./setup_remote_tfstate.ps1` to create an S3 bucket for storing your Terraform state
1. Check the Terraform plan:
    - `terraform plan`
        - Check the output of terraform plan to see what changes will be made to your AWS account.
1. Go live:
    - `terraform apply`
