# Deployment Method Comparison

Choose the best deployment method for your operating system and preferences:

## 📊 Comparison Table

| Feature | Linux/Mac Shell | Windows PowerShell | Windows Batch | Manual Terraform |
|---------|----------------|-------------------|---------------|------------------|
| **OS Support** | ✅ Linux/Mac/WSL | ✅ Windows 10/11 | ✅ All Windows | ✅ Cross-platform |
| **Prerequisites** | bash, curl | PowerShell 5.1+ | Command Prompt | None extra |
| **Color Output** | ✅ Yes | ✅ Yes | ⚠️ Limited | ❌ No |
| **Error Handling** | ✅ Advanced | ✅ Advanced | ✅ Basic | ⚠️ Manual |
| **Progress Indicators** | ✅ Yes | ✅ Yes | ✅ Basic | ❌ No |
| **Parameter Support** | ✅ Environment vars | ✅ Named parameters | ✅ Environment vars | ✅ tfvars |
| **Auto-cleanup** | ✅ Yes | ✅ Yes | ✅ Yes | ⚠️ Manual |
| **Validation** | ✅ Full | ✅ Full | ✅ Basic | ⚠️ Manual |
| **User Experience** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐ |

## 🚀 Recommended Approaches

### **For Windows Users:**
1. **PowerShell Script** (`deploy.ps1`) - Best experience
2. **Batch Script** (`deploy.bat`) - Simple alternative
3. **Windows Subsystem for Linux** - Use Linux script

### **For Linux/Mac Users:**
1. **Bash Script** (`deploy.sh`) - Optimal experience
2. **Manual Terraform** - Full control

### **For CI/CD Pipelines:**
1. **Manual Terraform commands** - Most reliable
2. **Containerized deployment** - Consistent environment

## 📋 Quick Command Reference

### Windows PowerShell:
```powershell
# Deploy
.\deploy.ps1 -StudentName "YourName" -AwsRegion "us-west-2"

# Status  
.\deploy.ps1 status

# Destroy
.\deploy.ps1 destroy
```

### Windows Command Prompt:
```cmd
REM Set your name
set STUDENT_NAME=YourName

REM Deploy
deploy.bat

REM Destroy
deploy.bat destroy
```

### Linux/Mac:
```bash
# Deploy
export STUDENT_NAME="YourName"
./deploy.sh

# Destroy  
./deploy.sh destroy
```

### Manual Terraform:
```bash
# Create config
cp terraform.tfvars terraform.tfvars.local
# Edit terraform.tfvars.local

# Deploy
terraform init
terraform plan -var-file="terraform.tfvars.local"
terraform apply -var-file="terraform.tfvars.local"

# Destroy
terraform destroy -var-file="terraform.tfvars.local"
```

## ⚡ Performance Notes

- **Cluster creation**: 15-20 minutes regardless of method
- **Script overhead**: < 30 seconds
- **Windows PowerShell**: Faster than batch for complex operations
- **Linux/Mac bash**: Fastest script execution
- **Manual**: No overhead, maximum control

## 🔧 Troubleshooting by Platform

### Windows Common Issues:
- **PowerShell execution policy** → Run as Administrator
- **Long paths** → Enable in Windows settings
- **SSL issues** → Update PowerShell/Windows

### Linux/Mac Common Issues:
- **Permission denied** → `chmod +x deploy.sh`
- **Missing tools** → Use package manager (brew/apt/yum)
- **AWS credentials** → Check `~/.aws/credentials`

### Universal Issues:
- **Terraform timeout** → Wait longer, check AWS Console
- **kubectl connection** → Verify cluster exists and config is updated
- **Cost concerns** → Monitor billing, use `destroy` when done

Choose the method that best fits your environment and comfort level!
