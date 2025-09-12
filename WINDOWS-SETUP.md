# Windows Setup Guide - Guest List API EKS Deployment

This guide provides Windows-specific instructions for deploying your Guest List API to Amazon EKS.

## 📋 Prerequisites for Windows

### 1️⃣ Install Required Tools

#### **Option A: Using Chocolatey (Recommended)**
First, install Chocolatey package manager:
```powershell
# Run as Administrator in PowerShell
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
```

Then install the tools:
```powershell
# Install all required tools
choco install awscli terraform kubernetes-cli -y
```

#### **Option B: Manual Installation**

**AWS CLI v2:**
1. Download from: https://aws.amazon.com/cli/
2. Run the installer: `AWSCLIV2.msi`
3. Verify: `aws --version`

**Terraform:**
1. Download from: https://www.terraform.io/downloads.html
2. Extract `terraform.exe` to a folder in your PATH (e.g., `C:\Windows\System32\`)
3. Verify: `terraform version`

**kubectl:**
1. Download from: https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/
2. Or use: `curl -LO "https://dl.k8s.io/release/v1.28.0/bin/windows/amd64/kubectl.exe"`
3. Add to PATH
4. Verify: `kubectl version --client`

#### **Option C: Using Scoop**
```powershell
# Install Scoop first
iwr -useb get.scoop.sh | iex

# Install tools
scoop bucket add main
scoop install aws terraform kubectl
```

### 2️⃣ Configure AWS Credentials
```cmd
aws configure
```
Enter your:
- Access Key ID
- Secret Access Key  
- Default region (e.g., `us-west-2`)
- Output format (`json`)

### 3️⃣ Set PowerShell Execution Policy
```powershell
# Run as Administrator
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine
```

---

## 🚀 Windows Deployment Options

### **Option 1: PowerShell Script (Recommended)**

```powershell
# Navigate to your project directory
cd C:\path\to\your\terraform\files

# Run the deployment
.\deploy.ps1

# Or with parameters
.\deploy.ps1 -StudentName "YourName" -AwsRegion "us-west-2"

# Other commands
.\deploy.ps1 destroy
.\deploy.ps1 status
```

### **Option 2: Command Prompt (Batch)**

```cmd
# Navigate to your project directory
cd C:\path\to\your\terraform\files

# Run the deployment
deploy.bat

# Other commands
deploy.bat destroy
deploy.bat status
```

### **Option 3: Manual Commands**

```cmd
# Set environment variables
set STUDENT_NAME=YourName
set CLUSTER_NAME=guestlist-yourname
set AWS_REGION=us-west-2

# Create tfvars file manually (see terraform.tfvars template)
copy terraform.tfvars terraform.tfvars.local
# Edit terraform.tfvars.local with your values

# Deploy
terraform init
terraform plan -var-file="terraform.tfvars.local"
terraform apply -var-file="terraform.tfvars.local"

# Configure kubectl
aws eks update-kubeconfig --region us-west-2 --name guestlist-yourname

# Test
kubectl get nodes
kubectl get pods -n guestlist-dev
```

---

## 🛠️ Windows-Specific Features

### **PowerShell Script Features:**
- ✅ Color-coded output
- ✅ Error handling with detailed messages
- ✅ Parameter support
- ✅ Automatic environment setup
- ✅ Windows PowerShell & PowerShell Core compatible
- ✅ Progress indicators

### **Batch Script Features:**
- ✅ Works in Command Prompt
- ✅ No PowerShell requirements
- ✅ Simple deployment flow
- ✅ Environment variable support

---

## 💻 PowerShell Usage Examples

### **Basic Deployment:**
```powershell
# Simple deployment with prompts
.\deploy.ps1

# Deploy with parameters
.\deploy.ps1 -StudentName "John Doe" -AwsRegion "us-east-1"

# Deploy to different environment
.\deploy.ps1 -Environment "staging" -StudentName "John"
```

### **Advanced Usage:**
```powershell
# Deploy with all parameters
.\deploy.ps1 deploy `
    -StudentName "John Doe" `
    -ClusterName "my-custom-cluster" `
    -AwsRegion "eu-west-1" `
    -Environment "prod"

# Check status
.\deploy.ps1 status

# Clean up
.\deploy.ps1 destroy
```

---

## 🧪 Testing Your API (Windows)

### **Using PowerShell:**
```powershell
# Get the load balancer URL
$LB_HOST = terraform output -raw load_balancer_ip

# Test the API
Invoke-WebRequest "http://$LB_HOST/guests" -UseBasicParsing

# Add a guest (POST request)
$body = @{
    firstname = "John"
    surname = "Doe"
    quantity = "2" 
    phone = "0541234567"
    email = "john@example.com"
    id = "JD2025"
} | ConvertTo-Json

Invoke-WebRequest "http://$LB_HOST/guests" -Method POST -Body $body -ContentType "application/json" -UseBasicParsing
```

### **Using curl (if installed):**
```cmd
REM Get all guests
curl http://[LB_HOST]/guests

REM Add a guest
curl -X POST http://[LB_HOST]/guests ^
  -H "Content-Type: application/json" ^
  -d "{\"firstname\":\"John\",\"surname\":\"Doe\",\"quantity\":\"2\",\"phone\":\"0541234567\",\"email\":\"john@example.com\",\"id\":\"JD2025\"}"
```

---

## 🐛 Windows-Specific Troubleshooting

### **Common Issues:**

**1. PowerShell Execution Policy Error:**
```powershell
# Fix: Run as Administrator
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine
```

**2. AWS CLI Not Found:**
```cmd
# Add AWS CLI to PATH or reinstall
set PATH=%PATH%;C:\Program Files\Amazon\AWSCLIV2\
```

**3. Terraform Not Found:**
```cmd
# Download terraform.exe and add to PATH
# Or use chocolatey: choco install terraform
```

**4. Long Path Issues:**
```cmd
# Enable long paths in Windows 10/11
# Run as Administrator:
reg add HKLM\SYSTEM\CurrentControlSet\Control\FileSystem /v LongPathsEnabled /t REG_DWORD /d 1
```

**5. SSL Certificate Issues:**
```powershell
# If you get SSL errors
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
```

**6. kubectl Not Working:**
```cmd
# Ensure kubectl config is correct
kubectl config current-context
aws eks update-kubeconfig --region us-west-2 --name your-cluster-name
```

---

## 📁 File Structure for Windows

```
C:\YourProject\
├── main.tf                    # Core infrastructure
├── eks.tf                     # EKS cluster config
├── kubernetes.tf              # K8s deployments
├── variables.tf               # Variable definitions
├── outputs.tf                 # Output values
├── terraform.tfvars           # Template variables
├── terraform.tfvars.local     # Your customized variables
├── deploy.ps1                 # PowerShell deployment script
├── deploy.bat                 # Batch deployment script
├── deploy.sh                  # Linux/Mac script (if needed)
├── README.md                  # General instructions
└── WINDOWS-SETUP.md           # This file
```

---

## 🔧 Environment Variables (Windows)

### **Set via PowerShell:**
```powershell
$env:STUDENT_NAME = "Your Name"
$env:AWS_REGION = "us-west-2"
$env:CLUSTER_NAME = "guestlist-yourname"
$env:ENVIRONMENT = "dev"
```

### **Set via Command Prompt:**
```cmd
set STUDENT_NAME=Your Name
set AWS_REGION=us-west-2
set CLUSTER_NAME=guestlist-yourname
set ENVIRONMENT=dev
```

### **Set Permanently (User Level):**
```cmd
setx STUDENT_NAME "Your Name"
setx AWS_REGION "us-west-2"
```

---

## 💰 Cost Management on Windows

Monitor your AWS costs using:
1. **AWS Console**: https://console.aws.amazon.com/billing/
2. **AWS CLI**: `aws ce get-cost-and-usage --time-period Start=2024-01-01,End=2024-01-31 --granularity MONTHLY --metrics BlendedCost`
3. **PowerShell**: Use AWS PowerShell modules for cost monitoring

**Always remember to clean up:**
```powershell
.\deploy.ps1 destroy
```

---

## 🎯 Quick Start for Windows Users

1. **Install tools** (choose one method above)
2. **Configure AWS**: `aws configure`
3. **Download terraform files** to a folder
4. **Open PowerShell as Administrator**
5. **Navigate to folder**: `cd C:\path\to\terraform\files`
6. **Run deployment**: `.\deploy.ps1`
7. **Follow prompts** and wait 15-20 minutes
8. **Test your API** when complete
9. **Clean up when done**: `.\deploy.ps1 destroy`

That's it! Your Guest List API will be running on AWS EKS, accessible from anywhere on the internet.
