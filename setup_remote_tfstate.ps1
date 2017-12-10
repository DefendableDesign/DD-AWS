#Determine Region
$region = @(Get-DefaultAWSRegion).Region
If ($region -eq $null) {
    $region = Read-Host -Prompt 'Enter the AWS region for your Terraform state S3 bucket'
}

#Determine AWS Account ID
Try {
    $accountId = @(get-ec2securitygroup -GroupNames "default" -Region $region)[0].OwnerId
}
Catch {
    Write-Host "Error determining AWS Account ID"
    Break
}

#Define Bucket Name
$bucketName = "dd-tfstate-{0}" -f $accountId

#Create Bucket
Try {
    Write-Host "Creating Terraform state S3 bucket: $bucketName"
    New-S3Bucket -BucketName $bucketName -Region $region -ErrorAction 'SilentlyContinue'
}
Catch [System.AggregateException]{
    $safeToIgnore = $Error[0].Exception.ToString().Contains("Your previous request to create the named bucket succeeded and you already own it")
    If ($safeToIgnore) {
        Write-Host "Using existing bucket: $bucketName."
    } Else {
        Write-Host "Error creating S3 bucket: $bucketName."
        Break
    }
}

#Enable versioning
Write-Host "Enabling versioning."
Write-S3BucketVersioning -BucketName $bucketName -Region $region -VersioningConfig_Status Enabled

#Initialise Terraform
terraform init `
    -backend-config="bucket=$bucketName" `
    -backend-config="region=$region"
