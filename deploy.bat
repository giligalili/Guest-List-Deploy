@echo off
REM Enhanced Guest List Deployment Script - Batch
REM This script deploys the Guest List infrastructure to AWS EKS with UserName support

setlocal enabledelayedexpansion

set "ENVIRONMENT=%1"
set "USERNAME_ARG=%2"

if "%ENVIRONMENT%"=="" set "ENVIRONMENT=dev"

echo.
echo 🚀 Guest List Deployment Script
echo =================================

REM Check if we're in the right directory
if not exist "terraform" (
    echo ❌ terraform directory not found. Please run this script from the project root.
    exit /b 1
)

REM Validate environment
if /i not "%ENVIRONMENT%"=="dev" if /i not "%ENVIRONMENT%"=="staging" if /i not "%ENVIRONMENT%"=="prod" (
    echo ❌ Invalid environment. Must be one of: dev, staging, prod
    exit /b 1
)

echo 📁 Using environment: %ENVIRONMENT%

REM Set environment file paths
set "ENV_FILE=environments\%ENVIRONMENT%\terraform.tfvars"
set "ENV_FILE_LOCAL=environments\%ENVIRONMENT%\terraform.tfvars.local"

if not exist "%ENV_FILE%" (
    echo ❌ Environment file not found: %ENV_FILE%
    exit /b 1
)

REM Handle UserName parameter
if not "%USERNAME_ARG%"=="" (
    echo 👤 Using provided username: %USERNAME_ARG%
    
    REM Generate unique cluster name
    set "CLUSTER_NAME=guestlist-%USERNAME_ARG%-%ENVIRONMENT%"
    
    echo 📝 Creating user-specific configuration...
    
    REM Create user-specific configuration file
    (
        echo # User-specific Guest List Configuration for %USERNAME_ARG%
        echo # Generated automatically by deploy.bat
        echo.
        echo # Basic Configuration
        echo cluster_name         = "%CLUSTER_NAME%"
        echo student_name        = "%USERNAME_ARG%"
        echo aws_region          = "us-west-2"
        echo environment         = "%ENVIRONMENT%"
        echo.
        echo # Cost Optimization Settings
        if /i "%ENVIRONMENT%"=="dev" (
            echo node_instance_type     = "t3.small"
            echo node_desired_capacity  = 2
        ) else if /i "%ENVIRONMENT%"=="staging" (
            echo node_instance_type     = "t3.medium"
            echo node_desired_capacity  = 2
        ) else (
            echo node_instance_type     = "t3.large"
            echo node_desired_capacity  = 3
        )
        echo node_min_capacity      = 1
        echo node_max_capacity      = 10
        echo.
        echo # Application Settings
        echo app_image           = "giligalili/guestlistapi:ver01"
        echo app_port            = 1111
        echo app_replicas        = 2
        echo.
        echo # Networking
        echo availability_zones  = ["us-west-2a", "us-west-2b"]
        echo.
        echo # Tags
        echo common_tags = {
        echo   Environment = "%ENVIRONMENT%"
        echo   Project     = "guest-list"
        echo   Owner       = "%USERNAME_ARG%"
        echo   Course      = "DevSecOps"
        echo }
    ) > "%ENV_FILE_LOCAL%"
    
    echo ✅ Created %ENV_FILE_LOCAL% with user-specific settings
    set "TFVARS_FILE=%ENV_FILE_LOCAL%"
) else (
    REM Check if local override exists
    if exist "%ENV_FILE_LOCAL%" (
        echo 📝 Using existing local override file: %ENV_FILE_LOCAL%
        echo 💡 Tip: Use 'deploy.bat dev username' for automatic configuration
        set "TFVARS_FILE=%ENV_FILE_LOCAL%"
    ) else (
        echo 📝 Using environment file: %ENV_FILE%
        echo 💡 Tip: Use 'deploy.bat dev username' for automatic configuration
        set "TFVARS_FILE=%ENV_FILE%"
    )
)

REM Display current configuration
echo.
echo 📋 Configuration Summary:
if not "%USERNAME_ARG%"=="" (
    echo    👤 Student Name: %USERNAME_ARG%
    echo    🏷️  Cluster Name: %CLUSTER_NAME%
)
echo    🌍 Environment: %ENVIRONMENT%
echo    📄 Config File: %TFVARS_FILE%

REM Change to terraform directory
pushd terraform

echo.
echo 🔧 Checking prerequisites...

REM Check for required tools
terraform --version >nul 2>&1
if errorlevel 1 (
    echo ❌ terraform is not installed or not in PATH
    popd
    exit /b 1
)
echo ✅ terraform is installed

aws --version >nul 2>&1
if errorlevel 1 (
    echo ❌ aws is not installed or not in PATH
    popd
    exit /b 1
)
echo ✅ aws is installed

kubectl version --client >nul 2>&1
if errorlevel 1 (
    echo ❌ kubectl is not installed or not in PATH
    popd
    exit /b 1
)
echo ✅ kubectl is installed

REM Check AWS credentials
aws sts get-caller-identity >nul 2>&1
if errorlevel 1 (
    echo ❌ AWS credentials not configured. Run 'aws configure'
    popd
    exit /b 1
)
echo ✅ AWS credentials are configured

echo.
echo 🏗️ Initializing Terraform...
terraform init
if errorlevel 1 (
    echo ❌ Terraform init failed
    popd
    exit /b 1
)

echo.
echo 📋 Planning deployment...
terraform plan -var-file="..\%TFVARS_FILE%"
if errorlevel 1 (
    echo ❌ Terraform plan failed
    popd
    exit /b 1
)

echo.
echo 🚀 Applying deployment...
echo ⏳ This may take 15-20 minutes for EKS cluster creation...
if not "%USERNAME_ARG%"=="" (
    echo 👤 Deploying infrastructure for: %USERNAME_ARG%
)

terraform apply -var-file="..\%TFVARS_FILE%" -auto-approve
if errorlevel 1 (
    echo ❌ Terraform apply failed
    popd
    exit /b 1
)

echo.
echo ✅ Deployment completed successfully!

echo.
echo 📊 Deployment Information:
terraform output

echo.
echo 🔧 Configuring kubectl...
for /f "tokens=*" %%i in ('terraform output -raw kubectl_config') do (
    %%i
    if not errorlevel 1 (
        echo ✅ kubectl configured successfully!
    )
)

echo.
echo 🧪 Testing cluster connection...
kubectl get nodes

for /f "tokens=*" %%i in ('terraform output -raw namespace') do (
    kubectl get pods -n %%i
)

echo.
echo 🎉 Deployment Summary:
if not "%USERNAME_ARG%"=="" (
    echo    👤 Student: %USERNAME_ARG%
) else (
    echo    👤 Student: Not specified
)
echo    🌍 Environment: %ENVIRONMENT%

terraform output -raw cluster_name > temp_cluster.txt
set /p CLUSTER_NAME_OUTPUT=<temp_cluster.txt
del temp_cluster.txt
echo    🏷️  Cluster: %CLUSTER_NAME_OUTPUT%

terraform output -raw application_url > temp_url.txt
set /p APP_URL=<temp_url.txt
del temp_url.txt
echo    🌐 Application URL: %APP_URL%

echo.
echo 📚 Next Steps:
echo    1. Test the API: curl %APP_URL%
echo    2. Monitor costs in AWS Console
echo    3. Scale if needed: kubectl scale deployment guestlist-deployment --replicas=3
if not "%USERNAME_ARG%"=="" (
    echo    4. Clean up when done: Run terraform destroy in terraform directory
) else (
    echo    4. Clean up when done: Run terraform destroy in terraform directory
)

popd

echo.
echo 🏁 Script completed!

pause
