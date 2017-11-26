# Defendable Design for AWS
The [Defendable Design project](https://github.com/defendabledesign) attempts to build a standard, self-healing designs for strong security.

Defendable Design for AWS (DD-AWS) uses [Terraform](https://www.terraform.io/) to orchestrate AWS-native functionality, including [AWS CloudTrail](https://aws.amazon.com/cloudtrail/), [AWS Config](https://aws.amazon.com/config/) and [AWS Lambda](https://aws.amazon.com/lambda/).

The Terraform code:
* Enables AWS Config
* Deploys a series of Config Rules that check for common problems
* Creates a Lambda function that can automatically reverse dangerous security group changes.

# How to get started
1. Install [Terraform](https://www.terraform.io/downloads.html)
2. Download and unpack the [latest release](https://github.com/DefendableDesign/DD-AWS/releases), or clone the whole repo.
3. [Configure AWS credentials](http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html)
4. Set a region (defaults to Sydney):
    - Edit `main.tf` to set an explicit `region` (refer to [AWS documentation for supported regions](http://docs.aws.amazon.com/general/latest/gr/rande.html#awsconfig_region))
4. **[Optional]** Enable auto-response for the `restricted_ports` module:
    - Edit `main.tf` and change `enable_auto_response` from `"false"` to `"true"`
5. Prepare Terraform:
    - `terraform init`
    - `terraform get`
    - `terraform plan`
        - Check the output of terraform plan to see what changes will be made to your AWS account.
6. Go live:
    - `terraform apply`