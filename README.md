# Terraform Codes

## Using Terraform to deploy Wordpress and Monit
This Terraform code is used to deploy a WordPress server on AWS using Bitnami AMI and enable
Monit for monitoring purpose. By default, the script will use AWS Singapore region and default VPC subnet.

### Prerequisites
* AWS AKI/SAK keys with AdministratorAccess privilege
* AWS SSH key pair

### How to use the script
First, you need to install Terraform on your PC, see [this guide] (https://www.terraform.io/intro/getting-started/install.html). Clone this repo and go to `wp-elb` directory and run following commands:
```bash
export AWS_ACCESS_KEY_ID=my_access_key_id
export AWS_SECRET_ACCESS_KEY=my_secret_access_key_id
terraform init
terraform plan
terraform apply
```
You will be asked to key in the name of your AWS EC2 SSH Key when you do `terraform plan` and `terraform apply`.

`terraform apply` will create EC2 instances running Wordpress and Monit.

### Accessing WordPress
`terraform apply` will give output of `elb_dns_name`. Use your browser to connect to the DNS name of `elb_dns_name` to access WordPress. The get the credentials to login to WordPress, you need to SSH to the EC2 instance and get it from `bitnami_credentials` file.

### Acccessing Monitoring Server
`terraform apply` will also give output of `web_server_dns_name`. Use browser to access the URL at port 2812 to get access to the monitoring of WordPress services.
