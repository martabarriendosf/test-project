enecccdkeilbinibthlinffljkurbjhruvduntukceeg
# CI/CD with Terraform

Authors: Marta Barriendos Fortuño (martabf@amazon.es)


## Introduction

This project shows a cloud architecture that implements a CI/CD pipeline capable of deploying Terraform code on AWS Graviton instances, using GitHub Actions to automatically make the deployment of the Terraform code to AWS. When a `git push` is made to the `main` branch, the pipeline runs and applies the changes to the infrastructure defined by Terraform in AWS. This architecture is a scalable mechanism that allows to deploy an infrastructure in a cost-effective manner. Moreover, thanks to the use of GitHub Actions, the process of setting up CI/CD pipelines is simplified. Starting from your GitHub repository, GitHub Actions enables seamless automation of workflows directly from the repository where the code resides. It facilitates and enhance your cloud deployment by using flexible workflows, which support a wide range of triggers and conditions. These workflows can be triggered by various events such as pushes, pull requests, etc. Additionally, there is a vast marketplace of reusable pre-built actions, which you can leverage to extend the capabilities of your workflows, saving time and effort in writing custom scripts for common tasks. 


## On this page

- [Understanding the CI/CD Pipeline](#understanding-the-cicd-pipeline)
- [Project Architecture](#project-architecture)
- [Requirements](#requirements)
- [Installation](#installation)
- [Update](#update)
- [Cleanup](#cleanup)
- [Using the Tool](#using-the-tool)
- [Security Considerations](#security-considerations)
- [Metrics](#metrics)

## Understanding the CI/CD Pipeline

The CI/CD pipeline is configured using GitHub Actions and consists of the following steps. First we define a workflow ([About workflows](https://docs.github.com/en/actions/using-workflows/about-workflows)) or configurable automated process, that will run a job. An event will trigger this workflow, specifically a push to the main branch, using the syntax of GitHub Actions ([Workflow syntax for GitHub Actions](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions#jobsjob_idruns-on)
). Finally, within the job, we define two steps that implement two actions developed by AWS for GitHub Actions.

1. **AWS Credentials Configuration**: Uses the [`aws-actions/configure-aws-credentials`](https://github.com/marketplace/actions/configure-aws-credentials-action-for-github-actions)
 action, that configures your AWS credentials and region environment variables to enable secure connectivity between your GitHub workflows and yor AWS account.
2. **CodeBuild Execution**: Uses the [`aws-actions/aws-codebuild-run-build`](https://github.com/aws-actions/aws-codebuild-run-build) action to build and run a CodeBuild project (that executes Terraform), collect the build logs and print them, specifying an inline buildspec definition with the required commands to deploy the Terraform project.

## Project Architecture

![Architecture Diagram](esquema1.PNG)

The project includes the following components:

- **GitHub Actions**: Manages the CI/CD workflow.
- **AWS CodeBuild**: Executes the Terraform commands to deploy the infrastructure.
- **Amazon S3**: Stores the Terraform state.
- **AWS IAM**: Manages the credentials and necessary permissions.

As can be seen in the presented architecture, we have a local repository hosting a Terraform code that defines the infrastructure we intend to deploy on AWS. When a change is made to this Terraform file and pushed, reflecting the change from the local repository to the remote repository, the defined workflow automatically initiates. It begins executing the job that has defined, starting with the first step where we use the GitHub action `aws-actions/configure-aws-credentials` to configure AWS credentials. Subsequently, the second step deploys the CodeBuild project running on a Graviton instance `aws-actions/aws-codebuild-run-build`. During this step, Terraform is installed and configured. After successful setup, Terraform is initialized (`terraform init`), storing its state in the configured S3 bucket, followed by the deployment of the Terraform code with `terraform apply`. 

Each time a new change is made in the main branch (`git push`), CodeBuild verifies if the Terraform state stored in the S3 bucket matches the current state. If they match, no changes are made. Otherwise, the new Terraform state is stored in the bucket (replacing the old one), and the updated infrastructure is deployed anew.

## Requirements

In order to develop the architecture the following requirements are mandatory:
- **Repository in your GitHub account**
- **GitHub Actions Configuration**: Enable the option `Allow all actions and reusable workflows`in your settings repository, to be able to use actions created by AWS ([More information about managing GitHub Actions settings](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/enabling-features-for-your-repository/managing-github-actions-settings-for-a-repository))
-  **AWS Account**: ([For more information about creating an AWS Account](https://repost.aws/es/knowledge-center/create-and-activate-aws-account))
-  **Terraform code to deploy (IaaC)**: This will be the code tht will undergo changes.
## Installation

### 1. Clone the Repository

Create an empty repository (test-project) in your personal GitHub account, see [Create a repo](https://docs.github.com/en/repositories/creating-and-managing-repositories/quickstart-for-repositories). Clone it locally to your computer. You can ignore the warning about cloning an empty repository.

```
git clone [https://github.com/yourusername/your-repo.git (https://github.com/martabarriendosf/test-project.git)
```

Once you have the repository, it is important to configure Code Defender (PREGUNTAR BORJA) to allow pushing code to a public repository.

```
git defender --setup
```
Finally, make sure your remote repository points to your personal GitHub repository using the following commands.

```
git remote remove origin
```

```
git remote add origin <your repository url>
```

```
git branch -M main
```

```
git push -u origin main
```

### 2. Set up the Repository
In this step, we can now work in the local GitHub repository to create the project. From this point forward, it is advisable to use a code editor tool such as [Visual Studio Code](https://code.visualstudio.com/) . Within the repository itself, the first task is to generate the main Terraform file (main.tf) which will contain the IaaC to be deployed to AWS. Secondly, create a folder with the path .github\workflows where the YAML file will be housed to configure the workflow with the necessary GitHub Actions.

### 3. AWS Architecture
In this section, we will use the AWS console with which we must make 3 steps to achieve the desired configuration:
- **1. Create an IAM user**: [Info about creating a new IAM user](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_users_create.html)
- **2. Create a S3 bucket**: [Info about creating a new S3 bucket]( https://docs.aws.amazon.com/AmazonS3/latest/userguide/creating-bucket.html)
- **3. Create a CodeBuild project**: [Info about creating a new CodeBuild project](https://docs.aws.amazon.com/codebuild/latest/userguide/create-project-console.html)

The first step is to create an IAM user with programmatic access, so that this user has an access key and access key ID, which we will use with the first GitHub action (`aws-actions/configure-aws-credentials`) to configure the credentials and access to the AWS environment. Additionally, these credentials must be saved as GitHub secrets. Once the IAM user is created, appropriate permissions need to be assigned since it does not have any by default. This is done using IAM policies. Specifically, we need to grant the IAM user Administrator access (`AdministratorAccess`), access to the S3 bucket (`AmazonS3FullAccess`), and for this project, access to the EC2 instance that Terraform will deploy (`AmazonEC2FullAccess`). 

Similarly, it will be necessary to create the S3 bucket where we will store the Terraform state. When creating the bucket, ensure to enable `Bucket versioning` to be able to preserve, retrieve, and restore every version of every object stored in your Amazon S3 bucket. Moreover, the name of the S3 bucket will also be saved as a GitHub Secret, to configure the backend for saving the Terrafom state file.

Lastly, it is necessary to create a CodeBuild project. Since the buildspec.yml file will be provided from GitHub, no specific configuration is required through the AWS console. Simply associate the project with the same name that will be assigned in the buildspec for the GitHub action (`aws-actions/aws-codebuild-run-build`) to deploy it properly. Additionally, a default role will be created for this project, so it is important to assign this IAM role permissions for accessing the S3 bucket (as CodeBuild needs to access the Terraform state in that bucket), `AmazonS3FullAccess`, and permissions to deploy the EC2 instance (`AmazonEC2FullAccess`).


### 4. Worflow configuration

