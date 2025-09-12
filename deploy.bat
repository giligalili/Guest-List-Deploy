@echo off
REM deploy.bat - Batch deployment script for Guest List API on EKS
REM Compatible with Windows Command Prompt

setlocal enabledelayedexpansion

REM Set default values
set "ACTION=%1"
set "AWS_REGION=us-west-2"
set "ENVIRONMENT=dev"

if "%ACTION%"=="" set "ACTION=deploy"

REM Colors (limited in CMD)
set "INFO_COLOR=echo [INFO]"
set "SUCCESS_COLOR=echo [SUCCESS]"
set "WARNING_COLOR=echo [WARNING]"
set "ERROR_COLOR=echo [ERROR]"

echo ==================================================
echo 🎉 Guest List API - EKS Deployment Script (Windows)
echo ==================================================
echo.

REM Check prerequisites
echo Checking prerequisites...

REM Check AWS CLI
aws --version >nul 2>&1
if !errorlevel! neq 0 (
    %ERROR_COLOR% AWS CLI is not installed or not in PATH
    echo Please install AWS CLI v2 from: https://aws.amazon.com/cli/
    pause
    exit /b 1
)

REM Check Terraform
terraform version >nul 2>&1
if !errorlevel! neq 0 (
    %ERROR_COLOR% Terraform is not installed or not in PATH
    echo Please install Terraform from: https://www.terraform.io/downloads.html
    pause
    exit /b 1
)

REM Check kubectl
kubectl version --client=true >nul 2>&1
if !errorlevel! neq 0 (
    %ERROR_COLOR% kubectl is not installed or not in PATH
    echo Please install kubectl from: https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/
    pause
    exit /b 1
)

REM Check AWS credentials
aws sts get-caller-identity >nul 2>&1
if !errorlevel! neq 0 (
    %ERROR_COLOR% AWS credentials not configured
    echo Please run: aws configure
    pause
    exit /b 1
)

%SUCCESS_COLOR% All prerequisites met!
echo.

REM Handle different actions
if "%ACTION%"=="deploy" goto :deploy
if "%ACTION%"=="destroy" goto :destroy
if "%ACTION%"=="status" goto :status

echo Usage: %0 [deploy^|destroy^|status]
echo   deploy  - Deploy the infrastructure (default)
echo   destroy - Destroy all resources
echo   status  - Show current deployment status
exit /b 1

:deploy
echo Starting deployment process...
echo.

REM Get student name
if "%STUDENT_NAME%"=="" (
    set /p STUDENT_NAME="Enter your name (for resource tagging): "
)

if "%STUDENT_NAME%"=="" (
    %ERROR_COLOR% Student name is required!
    pause
    exit /b 1
)

REM Set cluster name
if "%CLUSTER_NAME%"=="" (
    set "CLUSTER_NAME=guestlist-%STUDENT_NAME%"
    REM Remove spaces and special characters
    set "CLUSTER_NAME=!CLUSTER_NAME: =-!"
    set "CLUSTER_NAME=!CLUSTER_NAME:~0,20!"
)

REM Create terraform.tfvars.local
echo Creating environment configuration...
(
echo # Auto-generated environment configuration for Windows CMD
echo aws_region = "%AWS_REGION%"
echo cluster_name = "%CLUSTER_NAME%"
echo environment = "%ENVIRONMENT%"
echo student_name = "%STUDENT_NAME%"
echo.
echo # Cost-optimized defaults
echo node_instance_type = "t3.small"
echo node_desired_capacity = 2
echo node_max_capacity = 3
echo node_min_capacity = 1
echo.
echo app_image = "giligalili/guestlistapi:ver03"
echo app_replicas = 2
) > terraform.tfvars.local

%INFO_COLOR% Environment configured:
echo   Student Name: %STUDENT_NAME%
echo   Cluster Name: %CLUSTER_NAME%
echo   AWS Region: %AWS_REGION%
echo   Environment: %ENVIRONMENT%
echo.

REM Initialize Terraform
%INFO_COLOR% Initializing Terraform...
terraform init
if !errorlevel! neq 0 (
    %ERROR_COLOR% Terraform init failed!
    pause
    exit /b 1
)

REM Plan deployment
%INFO_COLOR% Planning deployment...
terraform plan -var-file="terraform.tfvars.local"
if !errorlevel! neq 0 (
    %ERROR_COLOR% Terraform plan failed!
    pause
    exit /b 1
)

REM Confirm deployment
echo.
%WARNING_COLOR% This will create AWS resources that incur costs (~$150/month^).
set /p CONFIRM="Continue with deployment? (y/N): "
if /i not "%CONFIRM%"=="y" (
    %INFO_COLOR% Deployment cancelled.
    pause
    exit /b 0
)

REM Apply Terraform
%INFO_COLOR% Applying Terraform configuration...
%INFO_COLOR% This will take 15-20 minutes for EKS cluster creation...
terraform apply -var-file="terraform.tfvars.local" -auto-approve
if !errorlevel! neq 0 (
    %ERROR_COLOR% Terraform apply failed!
    pause
    exit /b 1
)

REM Configure kubectl
%INFO_COLOR% Configuring kubectl...
aws eks update-kubeconfig --region %AWS_REGION% --name %CLUSTER_NAME%
if !errorlevel! neq 0 (
    %ERROR_COLOR% kubectl configuration failed!
    pause
    exit /b 1
)

REM Verify deployment
%INFO_COLOR% Verifying deployment...
echo Waiting for nodes to be ready...
kubectl wait --for=condition=Ready nodes --all --timeout=300s

echo Waiting for application pods...
kubectl wait --for=condition=Ready pods -l app=guestlist-api -n guestlist-%ENVIRONMENT% --timeout=300s

echo.
%INFO_COLOR% Cluster Status:
kubectl get nodes
kubectl get pods -n guestlist-%ENVIRONMENT%
kubectl get service guestlist-service -n guestlist-%ENVIRONMENT%

echo.
%SUCCESS_COLOR% Deployment completed successfully!
echo.
%WARNING_COLOR% === COST INFORMATION ===
echo Estimated monthly costs: ~$151.00
echo REMEMBER: Run 'deploy.bat destroy' when done!
echo.
%INFO_COLOR% Next steps:
echo 1. Wait a few minutes for Load Balancer to be ready
echo 2. Get LB URL: terraform output load_balancer_ip
echo 3. Test API: curl http://[LB_URL]/guests
echo 4. Monitor costs at AWS Console
pause
exit /b 0

:destroy
echo.
%WARNING_COLOR% This will destroy all resources and stop billing.
set /p CONFIRM="Are you sure? (y/N): "
if /i not "%CONFIRM%"=="y" (
    %INFO_COLOR% Destroy cancelled.
    pause
    exit /b 0
)

%INFO_COLOR% Destroying infrastructure...
terraform destroy -var-file="terraform.tfvars.local" -auto-approve
if !errorlevel! neq 0 (
    %ERROR_COLOR% Destroy failed!
    pause
    exit /b 1
)

%SUCCESS_COLOR% Resources destroyed successfully!
pause
exit /b 0

:status
echo Current Deployment Status:
echo.
kubectl get nodes 2>nul
if !errorlevel! neq 0 (
    %ERROR_COLOR% Cannot connect to cluster. Is kubectl configured?
    echo Try: aws eks update-kubeconfig --region %AWS_REGION% --name [CLUSTER_NAME]
    pause
    exit /b 1
)

kubectl get pods -n guestlist-%ENVIRONMENT% 2>nul
kubectl get service guestlist-service -n guestlist-%ENVIRONMENT% 2>nul
pause
exit /b 0

endlocal
