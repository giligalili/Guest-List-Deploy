# 🪟 Windows Setup Guide

Complete setup guide for deploying Guest List infrastructure on Windows systems with **multi-student support**.

**Students**: `sivan`, `dvir`, `saar`, `gili` - each gets isolated infrastructure with unique naming.

## 📋 Prerequisites Installation

### 1. AWS CLI Installation

**Option A: Windows Installer (Recommended)**
```powershell
# Download and install AWS CLI v2
# Visit: https://aws.amazon.com/cli/
# Or use PowerShell to download directly:
Invoke-WebRequest -Uri "https://awscli.amazonaws.com/AWSCLIV2.msi" -OutFile "AWSCLIV2.msi"
Start-Process msiexec.exe -Wait -ArgumentList '/i AWSCLIV2.msi /quiet'
```

**Option B: Using Chocolatey**
```powershell
# Install Chocolatey first (if not installed)
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install AWS CLI
choco install awscli -y
```

**Option C: Using Winget**
```powershell
winget install Amazon.AWSCLI
```

**Verify Installation:**
```powershell
aws --version
# Expected output: aws-cli/2.x.x Python/x.x.x Windows/x.x.x source/x86_64
```

### 2. Terraform Installation

**Option A: Direct Download (Recommended)**
```powershell
# Create directory for Terraform
New-Item -ItemType Directory -Force -Path "C:\terraform"

# Download Terraform (replace version as needed)
$terraformVersion = "1.6.0"
$downloadUrl = "https://releases.hashicorp.com/terraform/${terraformVersion}/terraform_${terraformVersion}_windows_amd64.zip"
Invoke-WebRequest -Uri $downloadUrl -OutFile "C:\terraform\terraform.zip"

# Extract Terraform
Expand-Archive -Path "C:\terraform\terraform.zip" -DestinationPath "C:\terraform" -Force
Remove-Item "C:\terraform\terraform.zip"

# Add to PATH
$env:PATH += ";C:\terraform"
[Environment]::SetEnvironmentVariable("Path", $env:PATH, [EnvironmentVariableTarget]::Machine)
```

**Option B: Using Chocolatey**
```powershell
choco install terraform -y
```

**Option C: Using Winget**
```powershell
winget install HashiCorp.Terraform
```

**Verify Installation:**
```powershell
terraform --version
# Expected output: Terraform v1.x.x
```

### 3. kubectl Installation

**Option A: Direct Download**
```powershell
# Create directory for kubectl
New-Item -ItemType Directory -Force -Path "C:\kubectl"

# Download kubectl (get latest version)
$kubectlVersion = (Invoke-RestMethod -Uri "https://dl.k8s.io/release/stable.txt").Trim()
$downloadUrl = "https://dl.k8s.io/release/$kubectlVersion/bin/windows/amd64/kubectl.exe"
Invoke-WebRequest -Uri $downloadUrl -OutFile "C:\kubectl\kubectl.exe"

# Add to PATH
$env:PATH += ";C:\kubectl"
[Environment]::SetEnvironmentVariable("Path", $env:PATH, [EnvironmentVariableTarget]::Machine)
```

**Option B: Using Chocolatey**
```powershell
choco install kubernetes-cli -y
```

**Option C: Using Winget**
```powershell
winget install Kubernetes.kubectl
```

**Verify Installation:**
```powershell
kubectl version --client
# Expected output: Client Version information
```

### 4. Git Installation (if not already installed)

**Using Winget:**
```powershell
winget install Git.Git
```

**Or download from:** https://git-scm.com/download/win

## 🔧 Configuration

### 1. Configure AWS Credentials

```powershell
# Interactive configuration
aws configure

# You'll be prompted for:
# AWS Access Key ID: [Enter your access key]
# AWS Secret Access Key: [Enter your secret key]  
# Default region name: [e.g., us-west-2]
# Default output format: [json]
```

**Verify AWS Configuration:**
```powershell
aws sts get-caller-identity
# Should return your account information
```

### 2. Set PowerShell Execution Policy

```powershell
# Allow local scripts to run (run as Administrator)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine
```

### 3. Optional: Install Windows Terminal (Better Experience)

```powershell
winget install Microsoft.WindowsTerminal
```

## 🚀 Student Deployment Options

### Method 1: Super Simple with UserName (Recommended)

**Perfect for students: sivan, dvir, saar, gili**

```powershell
# Clone the repository
git clone https://github.com/giligalili/Guest-List-Deploy.git
cd Guest-List-Deploy

# One-command deployment (automatically creates unique configuration)
.\deploy.ps1 -UserName "sivan" -Environment dev
```

**What this does automatically:**
- Creates cluster: `guestlist-sivan-dev`
- Sets student name: `sivan`  
- Tags all resources with your name
- Shows cost estimates and requires approval
- No manual file editing needed!

### Method 2: Manual Configuration (Traditional)

```powershell
# Clone the repository
git clone https://github.com/giligalili/Guest-List-Deploy.git
cd Guest-List-Deploy

# Copy and customize environment file
Copy-Item "environments\dev\terraform.tfvars" "environments\dev\terraform.tfvars.local"

# Edit the local file (use your preferred editor)
notepad "environments\dev\terraform.tfvars.local"

# Deploy using PowerShell script
.\deploy.ps1 -Environment dev
```

### Method 3: Batch Script (Simple Alternative)

```cmd
REM Clone the repository
git clone https://github.com/giligalili/Guest-List-Deploy.git
cd Guest-List-Deploy

REM Deploy with username
deploy.bat dev sivan
```

## 🎓 Student-Specific Examples

### Each Student Gets Isolated Infrastructure

```powershell
# Sivan's deployment
.\deploy.ps1 -UserName "sivan" -Environment dev
# Creates: guestlist-sivan-dev

# Dvir's deployment  
.\deploy.ps1 -UserName "dvir" -Environment dev
# Creates: guestlist-dvir-dev

# Saar's deployment
.\deploy.ps1 -UserName "saar" -Environment dev
# Creates: guestlist-saar-dev

# Gili's deployment
.\deploy.ps1 -UserName "gili" -Environment dev
# Creates: guestlist-gili-dev
```

### Available Commands per Student

```powershell
# Plan only (see costs and resources, no deployment)
.\deploy.ps1 -UserName "sivan" -Environment dev -Plan

# Deploy with manual cost approval (default)
.\deploy.ps1 -UserName "sivan" -Environment dev

# Deploy without confirmation (skip approval)
.\deploy.ps1 -UserName "sivan" -Environment dev -AutoApprove

# Destroy infrastructure (STOP ALL CHARGES)
.\deploy.ps1 -UserName "sivan" -Environment dev -Destroy
```

## 💰 Windows Cost Management

### Cost Display Before Deployment

The script shows detailed costs before any deployment:

```
ESTIMATED MONTHLY COSTS:
  EKS Cluster:              ~$72.00
  EC2 Nodes (2x t3.small): ~$30.40
  NAT Gateway:              ~$32.40
  Load Balancer:            ~$16.20
  -------------------------
  TOTAL ESTIMATED:          ~$151.00/month

IMPORTANT: You will be charged by AWS for these resources!
Do you want to proceed with deployment? Type 'yes' to continue
```

### Windows-Specific Cost Optimization

Create a PowerShell script for easy cost management:

```powershell
# Create cost-optimization.ps1
@"
# Windows Cost Management Helper

# Ultra-cheap configuration
function Set-CheapConfig {
    param([string]`$StudentName)
    
    `$config = @"
cluster_name         = "guestlist-`$StudentName-dev"
student_name        = "`$StudentName"
aws_region          = "us-west-2"
environment         = "dev"

# ULTRA-CHEAP SETTINGS (~`$120/month)
node_instance_type     = "t3.micro"      # Smallest instance
node_desired_capacity  = 1               # Single node
node_min_capacity      = 1
node_max_capacity      = 2
app_replicas          = 1               # Single app instance
capacity_type         = "SPOT"          # Use spot instances

common_tags = {
  Environment = "dev"
  Project     = "guest-list" 
  Owner       = "`$StudentName"
  CostProfile = "ultra-cheap"
  Course      = "DevSecOps"
}
"@
    
    `$config | Out-File -FilePath "environments\dev\terraform.tfvars.local" -Encoding UTF8
    Write-Host "Ultra-cheap configuration created for `$StudentName" -ForegroundColor Green
}

# Standard configuration  
function Set-StandardConfig {
    param([string]`$StudentName)
    
    `$config = @"
cluster_name         = "guestlist-`$StudentName-dev"
student_name        = "`$StudentName"
aws_region          = "us-west-2"
environment         = "dev"

# STANDARD SETTINGS (~`$151/month)
node_instance_type     = "t3.small"      # Good performance
node_desired_capacity  = 2               # High availability
node_min_capacity      = 1
node_max_capacity      = 3
app_replicas          = 2

common_tags = {
  Environment = "dev"
  Project     = "guest-list"
  Owner       = "`$StudentName"
  CostProfile = "standard"
  Course      = "DevSecOps"
}
"@
    
    `$config | Out-File -FilePath "environments\dev\terraform.tfvars.local" -Encoding UTF8
    Write-Host "Standard configuration created for `$StudentName" -ForegroundColor Green
}

Write-Host "Cost management functions loaded!" -ForegroundColor Green
Write-Host "Usage:"
Write-Host "  Set-CheapConfig -StudentName 'sivan'"
Write-Host "  Set-StandardConfig -StudentName 'sivan'"
"@ | Out-File -FilePath "cost-optimization.ps1" -Encoding UTF8

Write-Host "Created cost-optimization.ps1 helper script" -ForegroundColor Green
```

### Using Cost Optimization Helper

```powershell
# Load the helper functions
. .\cost-optimization.ps1

# Create ultra-cheap configuration
Set-CheapConfig -StudentName "sivan"

# Deploy with cheap settings
.\deploy.ps1 -Environment dev

# Or create standard configuration
Set-StandardConfig -StudentName "sivan"
.\deploy.ps1 -Environment dev
```

## 🛠️ Windows-Specific Troubleshooting

### PowerShell Execution Policy Issues

**Problem:** "Execution of scripts is disabled on this system"

**Solution:**
```powershell
# Run PowerShell as Administrator and execute:
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine

# Or for current user only:
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Path Environment Variable Issues

**Problem:** Commands not found after installation

**Solution:**
```powershell
# Refresh environment variables
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# Or restart your terminal/PowerShell session
```

### AWS CLI Configuration Issues

**Problem:** AWS credentials not working

**Solution:**
```powershell
# Check current configuration
aws configure list

# Reconfigure if needed
aws configure

# Test with specific profile
aws sts get-caller-identity --profile default
```

### Terraform Duplicate Providers Issue

**Problem:** "Duplicate required providers configuration"

**Solution:**
```powershell
# Delete the problematic providers.tf file
del terraform\providers.tf

# The main.tf file contains the provider configuration
```

### kubectl Version Check Issue

**Problem:** "unknown flag: --version"

**Solution:** The deploy script now handles this automatically with fallback, but you can test manually:
```powershell
# Try new format first
kubectl version --client=true

# If that fails, try old format
kubectl version --client
```

### Long Path Issues

**Problem:** "Path too long" errors

**Solution:**
```powershell
# Enable long paths (requires Administrator privileges)
New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name "LongPathsEnabled" -Value 1 -PropertyType DWORD -Force
```

## 📝 Windows Student Workflow Examples

### Sivan's Complete Workflow
```powershell
# Setup (one time)
git clone https://github.com/giligalili/Guest-List-Deploy.git
cd Guest-List-Deploy

# Deploy
.\deploy.ps1 -UserName "sivan" -Environment dev
# Script shows costs, asks for approval, then deploys

# Test the deployment
# (Application URL will be shown in output)

# Monitor costs
# Check AWS billing dashboard

# When done - CLEANUP (STOP CHARGES)
.\deploy.ps1 -UserName "sivan" -Environment dev -Destroy
```

### Dvir's Ultra-Cheap Deployment
```powershell
# Setup
git clone https://github.com/giligalili/Guest-List-Deploy.git
cd Guest-List-Deploy

# Load cost helper
. .\cost-optimization.ps1

# Create cheap configuration
Set-CheapConfig -StudentName "dvir"

# Deploy with cheap settings
.\deploy.ps1 -Environment dev

# Cleanup when done
.\deploy.ps1 -Environment dev -Destroy
```

### Multi-Student Batch Deployment (Class Demo)
```powershell
# Deploy for all students at once (demo purposes)
$students = @("sivan", "dvir", "saar", "gili")

foreach ($student in $students) {
    Write-Host "Deploying for student: $student" -ForegroundColor Green
    .\deploy.ps1 -UserName $student -Environment dev -AutoApprove
}

# Later cleanup for all students
foreach ($student in $students) {
    Write-Host "Cleaning up for student: $student" -ForegroundColor Red
    .\deploy.ps1 -UserName $student -Environment dev -Destroy
}
```

## 🔄 Windows Development Workflow

### Daily Development Cycle
```powershell
# Morning - Start work
.\deploy.ps1 -UserName "sivan" -Environment dev

# Development work...
# Test API, modify code, etc.

# Evening - Stop charges
.\deploy.ps1 -UserName "sivan" -Environment dev -Destroy
```

### Testing Different Configurations
```powershell
# Test cheap configuration
Set-CheapConfig -StudentName "sivan"
.\deploy.ps1 -Environment dev -Plan      # See what will be created

# Test standard configuration  
Set-StandardConfig -StudentName "sivan"
.\deploy.ps1 -Environment dev -Plan      # Compare resources

# Deploy your chosen configuration
.\deploy.ps1 -Environment dev
```

## 🎯 Windows Helper Scripts

### Create deployment-helpers.ps1
```powershell
# Student deployment helper functions

function Deploy-Student {
    param(
        [string]$StudentName,
        [string]$Environment = "dev",
        [switch]$Plan,
        [switch]$Destroy
    )
    
    if ($Plan) {
        .\deploy.ps1 -UserName $StudentName -Environment $Environment -Plan
    } elseif ($Destroy) {
        .\deploy.ps1 -UserName $StudentName -Environment $Environment -Destroy  
    } else {
        .\deploy.ps1 -UserName $StudentName -Environment $Environment
    }
}

function Get-StudentStatus {
    param([string]$StudentName)
    
    $clusterName = "guestlist-$StudentName-dev"
    Write-Host "Checking status for student: $StudentName" -ForegroundColor Cyan
    Write-Host "Expected cluster name: $clusterName" -ForegroundColor Gray
    
    # Check if cluster exists
    try {
        aws eks describe-cluster --name $clusterName --region us-west-2
        Write-Host "✅ Cluster exists and is active" -ForegroundColor Green
        
        # Check kubectl connection
        kubectl get nodes
        kubectl get pods -n guestlist-dev
    } catch {
        Write-Host "❌ No active deployment found for $StudentName" -ForegroundColor Red
    }
}

function Show-AllStudents {
    $students = @("sivan", "dvir", "saar", "gili")
    
    Write-Host "Student Deployment Status:" -ForegroundColor Cyan
    Write-Host "=========================" -ForegroundColor Cyan
    
    foreach ($student in $students) {
        Write-Host "`n👤 Student: $student" -ForegroundColor White
        Get-StudentStatus $student
    }
}

# Load functions
Write-Host "Student helper functions loaded!" -ForegroundColor Green
Write-Host "Available commands:"
Write-Host "  Deploy-Student -StudentName 'sivan'"
Write-Host "  Deploy-Student -StudentName 'sivan' -Plan"
Write-Host "  Deploy-Student -StudentName 'sivan' -Destroy"
Write-Host "  Get-StudentStatus -StudentName 'sivan'"
Write-Host "  Show-AllStudents"
```

### Using Helper Functions
```powershell
# Load helpers
. .\deployment-helpers.ps1

# Quick deployment
Deploy-Student -StudentName "sivan"

# Check status
Get-StudentStatus -StudentName "sivan"

# Plan for staging
Deploy-Student -StudentName "dvir" -Environment staging -Plan

# Show all students
Show-AllStudents
```

---

## 🆘 Getting Help on Windows

### Common Windows Issues
- **Antivirus blocking**: Add terraform.exe to exclusions
- **Windows Defender**: May quarantine downloaded binaries
- **Corporate proxy**: Configure terraform and AWS CLI proxy settings
- **Firewall**: Ensure outbound HTTPS (443) access

### Student Support Commands
```powershell
# Verify everything is working
aws sts get-caller-identity        # AWS credentials
terraform --version               # Terraform installation
kubectl version --client          # kubectl installation

# Check current deployments
aws eks list-clusters --region us-west-2

# Emergency cleanup (if script fails)
terraform destroy -var-file="../environments/dev/terraform.tfvars.local"
```

### Resources
- [AWS CLI Windows Documentation](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2-windows.html)
- [Terraform Windows Installation](https://learn.hashicorp.com/tutorials/terraform/install-cli)
- [kubectl Windows Installation](https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/)

---

**💡 Pro Tips for Windows Students:**
- Use Windows Terminal for better experience
- Enable Developer Mode for better symlink support
- Use PowerShell 7+ for better performance
- Always use the `-UserName` parameter for automatic configuration
- Set up Git with proper line ending configuration
- Monitor AWS costs daily during active development
- Always run `-Destroy` when finished to stop charges

**👥 Students**: Remember, each student (sivan, dvir, saar, gili) gets completely isolated infrastructure with unique naming and resource tagging!

---

Made with ❤️ for Windows DevSecOps practitioners  
**Multi-Student Support**: Sivan, Dvir, Saar, and Gili
