@echo off
REM Guest List Deployment Script - Batch
REM This script deploys the Guest List infrastructure to AWS EKS

setlocal enabledelayedexpansion

set "ENVIRONMENT=%1"
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

REM Check if local override exists
if exist "%ENV_FILE_LOCAL%" (
    echo 📝 Using local override file: %ENV_FILE_LOCAL%
    set "TFVARS_FILE=%ENV_FILE_LOCAL%"
) else (
    echo 📝 Using environment file: %ENV_FILE%
    echo 💡 Tip: Copy to terraform.tfvars.local for local customization
    set "TFVARS_FILE=%ENV_FILE%"
)

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
kubectl get pods -n guestlist-%ENVIRONMENT%

echo.
echo 🎉 Deployment Summary:
echo    Environment: %ENVIRONMENT%
terraform output -raw cluster_name > temp_cluster.txt
set /p CLUSTER_NAME=<temp_cluster.txt
del temp_cluster.txt
echo    Cluster: %CLUSTER_NAME%

terraform output -raw application_url > temp_url.txt
set /p APP_URL=<temp_url.txt
del temp_url.txt
echo    Application URL: %APP_URL%

echo.
echo 📚 Next Steps:
echo    1. Test the API: curl %APP_URL%
echo    2. Monitor costs in AWS Console
echo    3. Scale if needed: kubectl scale deployment guestlist-deployment --replicas=3
echo    4. Clean up when done: terraform destroy -var-file="..\%TFVARS_FILE%"

popd

echo.
echo 🏁 Script completed!

pause
