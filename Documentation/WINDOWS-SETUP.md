# 🪟 Windows Setup Guide

Complete setup guide for deploying Guest List infrastructure on Windows systems.

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

## 🚀 Quick Windows Deployment

### Method 1: PowerShell Script (Recommended)

```powershell
# Clone the repository
git clone https://github.com/giligalili/Guest-List-Deploy.git
cd Guest-List-Deploy

# Copy and customize environment file
Copy-Item "environments\dev\terraform.tfvars" "environments\dev\terraform.tfvars.local"

# Edit the local file (use your preferred editor)
notepad "environments\dev\terraform.tfvars.local"

# Deploy using PowerShell script
.\deploy.ps1
```

### Method 2: Batch Script

```cmd
REM Clone the repository
git clone https://github.com/giligalili/Guest-List-Deploy.git
cd Guest-List-Deploy

REM Copy and customize environment file
copy "environments\dev\terraform.tfvars" "environments\dev\terraform.tfvars.local"

REM Edit the local file
notepad "environments\dev\terraform.tfvars.local"

REM Deploy using batch script
deploy.bat
```

### Method 3: Manual Commands

```powershell
# Navigate to terraform directory
cd terraform

# Initialize Terraform
terraform init

# Plan deployment
terraform plan -var-file="..\environments\dev\terraform.tfvars.local"

# Apply deployment
terraform apply -var-file="..\environments\dev\terraform.tfvars.local"
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

### Long Path Issues

**Problem:** "Path too long" errors

**Solution:**
```powershell
# Enable long paths (requires Administrator privileges)
New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name "LongPathsEnabled" -Value 1 -PropertyType DWORD -Force
```

### Terraform Provider Download Issues

**Problem:** Network issues downloading providers

**Solution:**
```powershell
# Set Terraform to use system proxy
$env:TF_CLI_CONFIG_FILE = "terraform.tfrc"

# Create terraform.tfrc file with proxy settings if needed
@"
provider_installation {
  network_mirror {
    url = "https://terraform-mirror.your-company.com/"
  }
}
"@ | Out-File -FilePath "terraform.tfrc" -Encoding UTF8
```

## 📝 Windows Environment Customization

### Create Windows-Specific tfvars

```powershell
# Create a Windows-specific configuration
$windowsConfig = @"
# Windows-specific Guest List Configuration
cluster_name         = "$env:USERNAME-guestlist-dev"
student_name        = "$env:USERNAME"
aws_region          = "us-west-2"
environment         = "dev"

# Windows-optimized settings
node_instance_type     = "t3.small"
node_desired_capacity  = 2
node_min_capacity      = 1  
node_max_capacity      = 3

availability_zones     = ["us-west-2a", "us-west-2b"]

common_tags = {
  Environment = "dev"
  Project     = "guest-list"
  Owner       = "$env:USERNAME"
  OS          = "Windows"
  Course      = "DevSecOps"
}
"@

$windowsConfig | Out-File -FilePath "environments\dev\terraform.tfvars.local" -Encoding UTF8
```

## 🔄 Windows-Specific Scripts

### PowerShell Helper Functions

Create a `helpers.ps1` file:

```powershell
# Guest List Helper Functions for Windows

function Get-GuestListStatus {
    kubectl get pods -n guestlist-dev
    kubectl get services -n guestlist-dev
}

function Test-GuestListAPI {
    $lb_host = terraform output -raw load_balancer_ip
    Write-Host "Testing API at: http://$lb_host"
    
    try {
        $response = Invoke-RestMethod -Uri "http://$lb_host/guests" -Method Get
        Write-Host "✅ API is responding!" -ForegroundColor Green
        return $response
    } catch {
        Write-Host "❌ API not responding: $_" -ForegroundColor Red
    }
}

function Add-TestGuest {
    param(
        [string]$firstName = "John",
        [string]$lastName = "Doe"
    )
    
    $lb_host = terraform output -raw load_balancer_ip
    $guestData = @{
        firstname = $firstName
        surname = $lastName
        quantity = "2"
        phone = "0541234567"
        email = "$firstName.$lastName@example.com"
        guest_id = "$($firstName.Substring(0,1))$($lastName.Substring(0,1))2025"
    } | ConvertTo-Json
    
    try {
        $response = Invoke-RestMethod -Uri "http://$lb_host/guests" -Method Post -Body $guestData -ContentType "application/json"
        Write-Host "✅ Guest added successfully!" -ForegroundColor Green
        return $response
    } catch {
        Write-Host "❌ Failed to add guest: $_" -ForegroundColor Red
    }
}

function Get-DeploymentCost {
    terraform output estimated_monthly_cost
}

function Watch-GuestListPods {
    kubectl get pods -n guestlist-dev -w
}

# Load functions
Write-Host "Guest List helper functions loaded!" -ForegroundColor Green
Write-Host "Available functions:"
Write-Host "  - Get-GuestListStatus"
Write-Host "  - Test-GuestListAPI" 
Write-Host "  - Add-TestGuest"
Write-Host "  - Get-DeploymentCost"
Write-Host "  - Watch-GuestListPods"
```

### Use Helper Functions

```powershell
# Load helper functions
. .\helpers.ps1

# Check deployment status
Get-GuestListStatus

# Test the API
Test-GuestListAPI

# Add a test guest
Add-TestGuest -firstName "Alice" -lastName "Smith"

# Check estimated costs
Get-DeploymentCost
```

## 🎯 Windows Development Workflow

1. **Setup Phase**
   ```powershell
   # One-time setup
   git clone https://github.com/giligalili/Guest-List-Deploy.git
   cd Guest-List-Deploy
   Copy-Item "environments\dev\terraform.tfvars" "environments\dev\terraform.tfvars.local"
   ```

2. **Development Phase**
   ```powershell
   # Deploy infrastructure
   .\deploy.ps1 -Environment dev
   
   # Load helpers
   . .\helpers.ps1
   
   # Test deployment
   Get-GuestListStatus
   Test-GuestListAPI
   ```

3. **Testing Phase**
   ```powershell
   # Scale for testing
   kubectl scale deployment guestlist-deployment --replicas=3 -n guestlist-dev
   
   # Monitor
   Watch-GuestListPods
   ```

4. **Cleanup Phase**
   ```powershell
   # Destroy resources
   .\deploy.ps1 -Destroy
   ```

---

## 🆘 Getting Help on Windows

### Common Windows Issues
- **Antivirus blocking**: Add terraform.exe to exclusions
- **Windows Defender**: May quarantine downloaded binaries
- **Corporate proxy**: Configure terraform and AWS CLI proxy settings
- **Firewall**: Ensure outbound HTTPS (443) access

### Resources
- [AWS CLI Windows Documentation](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2-windows.html)
- [Terraform Windows Installation](https://learn.hashicorp.com/tutorials/terraform/install-cli)
- [kubectl Windows Installation](https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/)

---

**💡 Pro Tips for Windows Users:**
- Use Windows Terminal for better experience
- Enable Developer Mode for better symlink support
- Use PowerShell 7+ for better performance
- Consider WSL2 for Linux-like experience
- Set up Git with proper line ending configuration

---

Made with ❤️ for Windows DevSecOps practitioners
