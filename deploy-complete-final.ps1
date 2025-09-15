# Guest List Deployment Script - FINAL VERSION
# Complete script with UserName parameter, cost transparency, and all fixes

param(
    [string]$Environment = "dev",
    [string]$UserName = "",
    [switch]$Destroy = $false,
    [switch]$Plan = $false,
    [switch]$AutoApprove = $false
)

Write-Host "===================================================" -ForegroundColor Green
Write-Host "     GUEST LIST DEPLOYMENT SCRIPT - FINAL" -ForegroundColor Green
Write-Host "          Multi-Student DevSecOps Project" -ForegroundColor Green
Write-Host "===================================================" -ForegroundColor Green

# Check if we're in the right directory
if (-not (Test-Path "terraform")) {
    Write-Error "terraform directory not found. Please run this script from the project root directory."
    Write-Host "Current location: $(Get-Location)" -ForegroundColor Yellow
    Write-Host "Expected structure:" -ForegroundColor Yellow
    Write-Host "  Guest-List-Deploy/" -ForegroundColor Gray
    Write-Host "  ├── terraform/" -ForegroundColor Gray
    Write-Host "  ├── environments/" -ForegroundColor Gray
    Write-Host "  └── deploy.ps1" -ForegroundColor Gray
    exit 1
}

# Validate environment
$validEnvironments = @("dev", "staging", "prod")
if ($Environment -notin $validEnvironments) {
    Write-Error "Invalid environment. Must be one of: $($validEnvironments -join ', ')"
    exit 1
}

# Set file paths
$envFile = "environments\$Environment\terraform.tfvars"
$envFileLocal = "environments\$Environment\terraform.tfvars.local"

if (-not (Test-Path $envFile)) {
    Write-Error "Environment file not found: $envFile"
    Write-Host "Available environments:" -ForegroundColor Yellow
    Get-ChildItem "environments" -Directory | ForEach-Object { Write-Host "  - $($_.Name)" -ForegroundColor Gray }
    exit 1
}

Write-Host "Environment: $Environment" -ForegroundColor Cyan

# Handle UserName parameter - AUTOMATIC CONFIGURATION
if ($UserName -ne "") {
    Write-Host "Student: $UserName" -ForegroundColor Cyan
    
    $clusterName = "guestlist-$UserName-$Environment"
    
    Write-Host "Creating personalized configuration..." -ForegroundColor Yellow
    Write-Host "  Cluster: $clusterName" -ForegroundColor White
    Write-Host "  Student: $UserName" -ForegroundColor White
    
    # Read base configuration and customize for student
    $content = Get-Content $envFile
    $updatedContent = @()
    
    foreach ($line in $content) {
        if ($line -match '^cluster_name\s*=') {
            $updatedContent += "cluster_name         = `"$clusterName`""
        }
        elseif ($line -match '^student_name\s*=') {
            $updatedContent += "student_name        = `"$UserName`""
        }
        elseif ($line -match 'Owner\s*=') {
            $updatedContent += "    Owner       = `"$UserName`""
        }
        else {
            $updatedContent += $line
        }
    }
    
    # Write personalized configuration
    $updatedContent | Out-File -FilePath $envFileLocal -Encoding UTF8
    Write-Host "Created: $envFileLocal" -ForegroundColor Green
    
    $tfVarsFile = $envFileLocal
}
else {
    if (Test-Path $envFileLocal) {
        Write-Host "Using existing configuration: $envFileLocal" -ForegroundColor Yellow
        Write-Host "💡 Tip: Use -UserName parameter for automatic configuration" -ForegroundColor Gray
        $tfVarsFile = $envFileLocal
    }
    else {
        Write-Host "Using base configuration: $envFile" -ForegroundColor Blue
        Write-Host "💡 Tip: Use -UserName parameter for personalized deployment" -ForegroundColor Gray
        $tfVarsFile = $envFile
    }
}

# Display configuration summary
Write-Host ""
Write-Host "===================================================" -ForegroundColor Cyan
Write-Host "              CONFIGURATION SUMMARY" -ForegroundColor Cyan
Write-Host "===================================================" -ForegroundColor Cyan
if ($UserName -ne "") {
    Write-Host ("  👤 Student: " + $UserName) -ForegroundColor White
    Write-Host ("  🏷️  Cluster: " + $clusterName) -ForegroundColor White
}
Write-Host ("  🌍 Environment: " + $Environment) -ForegroundColor White
Write-Host ("  📄 Config File: " + $tfVarsFile) -ForegroundColor White

# Display cost information UPFRONT
Write-Host ""
Write-Host "===================================================" -ForegroundColor Yellow
Write-Host "               COST INFORMATION" -ForegroundColor Yellow
Write-Host "===================================================" -ForegroundColor Yellow
Write-Host "📊 ESTIMATED MONTHLY COSTS (US-WEST-2):" -ForegroundColor White
Write-Host ""
Write-Host "  💰 EKS Cluster (Control Plane):     ~`$72.00/month" -ForegroundColor White
Write-Host "  🖥️  EC2 Worker Nodes (2x t3.small):  ~`$30.40/month" -ForegroundColor White  
Write-Host "  🌐 NAT Gateway (Single AZ):         ~`$32.40/month" -ForegroundColor White
Write-Host "  ⚖️  Network Load Balancer:          ~`$16.20/month" -ForegroundColor White
Write-Host "  📡 Data Transfer & Storage:         ~`$2.00/month" -ForegroundColor White
Write-Host "     ────────────────────────────────────────────" -ForegroundColor Gray
Write-Host "  📈 TOTAL ESTIMATED COST:          ~`$153.00/month" -ForegroundColor Yellow
Write-Host ""
Write-Host "💡 COST REDUCTION OPTIONS:" -ForegroundColor Cyan
Write-Host "   • Use t3.micro instances:       Save ~`$15/month" -ForegroundColor Gray
Write-Host "   • Single node deployment:      Save ~`$15/month" -ForegroundColor Gray
Write-Host "   • Spot instances (70% off):    Save ~`$21/month" -ForegroundColor Gray
Write-Host "   • Deploy in us-east-1:         Save ~`$5/month" -ForegroundColor Gray
Write-Host ""
Write-Host "⚠️  IMPORTANT: AWS will charge you for these resources!" -ForegroundColor Red
Write-Host "    Remember to destroy when finished to stop charges." -ForegroundColor Red
Write-Host "===================================================" -ForegroundColor Yellow

# Check prerequisites
Write-Host ""
Write-Host "🔧 Checking prerequisites..." -ForegroundColor Yellow

# Check terraform
try {
    $terraformVersion = terraform --version | Select-String "Terraform v" | ForEach-Object { $_.ToString().Split(" ")[1] }
    Write-Host "  ✅ Terraform $terraformVersion installed" -ForegroundColor Green
}
catch {
    Write-Error "❌ Terraform is not installed or not in PATH"
    Write-Host "   Install from: https://www.terraform.io/downloads.html" -ForegroundColor Yellow
    exit 1
}

# Check AWS CLI
try {
    $awsVersion = aws --version 2>&1 | Select-String "aws-cli" | ForEach-Object { $_.ToString().Split(" ")[0] }
    Write-Host "  ✅ AWS CLI installed ($awsVersion)" -ForegroundColor Green
}
catch {
    Write-Error "❌ AWS CLI is not installed or not in PATH"
    Write-Host "   Install from: https://aws.amazon.com/cli/" -ForegroundColor Yellow
    exit 1
}

# Check kubectl with corrected version check
try {
    $null = kubectl version --client=true 2>$null
    Write-Host "  ✅ kubectl installed" -ForegroundColor Green
}
catch {
    try {
        # Fallback for older kubectl versions
        $null = kubectl version --client 2>$null
        Write-Host "  ✅ kubectl installed (legacy version)" -ForegroundColor Green
    }
    catch {
        Write-Error "❌ kubectl is not installed or not in PATH"
        Write-Host "   Install from: https://kubernetes.io/docs/tasks/tools/install-kubectl/" -ForegroundColor Yellow
        exit 1
    }
}

# Check AWS credentials with account info
try {
    $awsInfo = aws sts get-caller-identity | ConvertFrom-Json
    Write-Host "  ✅ AWS credentials configured" -ForegroundColor Green
    Write-Host ("    Account: " + $awsInfo.Account) -ForegroundColor Gray
    Write-Host ("    User: " + $awsInfo.Arn.Split('/')[-1]) -ForegroundColor Gray
    Write-Host ("    Region: " + (aws configure get region)) -ForegroundColor Gray
}
catch {
    Write-Error "❌ AWS credentials not configured"
    Write-Host "   Run: aws configure" -ForegroundColor Yellow
    Write-Host "   You need: Access Key ID, Secret Access Key, Region" -ForegroundColor Yellow
    exit 1
}

# Change to terraform directory
Push-Location terraform

try {
    # Initialize Terraform
    Write-Host ""
    Write-Host "🏗️ Initializing Terraform..." -ForegroundColor Yellow
    terraform init
    if ($LASTEXITCODE -ne 0) {
        throw "Terraform initialization failed"
    }
    
    # Handle destroy operation
    if ($Destroy) {
        Write-Host ""
        Write-Host "===================================================" -ForegroundColor Red
        Write-Host "              ⚠️  DESTROYING INFRASTRUCTURE" -ForegroundColor Red
        Write-Host "===================================================" -ForegroundColor Red
        Write-Host "🗑️  This will DELETE ALL AWS resources!" -ForegroundColor Red
        Write-Host "💰 This will STOP all charges for this deployment!" -ForegroundColor Yellow
        if ($UserName -ne "") {
            Write-Host ("👤 Destroying resources for student: " + $UserName) -ForegroundColor Red
            Write-Host ("🏷️  Cluster to destroy: " + $clusterName) -ForegroundColor Red
        }
        
        Write-Host ""
        $confirmation = Read-Host "⚠️  Type 'yes' to confirm DESTRUCTION of all resources"
        if ($confirmation -eq "yes") {
            Write-Host ""
            Write-Host "🗑️  Destroying infrastructure..." -ForegroundColor Red
            
            if ($AutoApprove) {
                terraform destroy -var-file="../$tfVarsFile" -auto-approve
            } else {
                terraform destroy -var-file="../$tfVarsFile"
            }
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host ""
                Write-Host "✅ Infrastructure destroyed successfully!" -ForegroundColor Green
                Write-Host "💰 All AWS charges for this deployment have STOPPED." -ForegroundColor Green
                if ($UserName -ne "") {
                    Write-Host ("🧹 All resources for student " + $UserName + " have been cleaned up.") -ForegroundColor Green
                }
                Write-Host ""
                Write-Host "🔍 Verify in AWS Console that all resources are gone:" -ForegroundColor Cyan
                Write-Host "   • EKS Clusters: https://console.aws.amazon.com/eks/" -ForegroundColor Gray
                Write-Host "   • EC2 Instances: https://console.aws.amazon.com/ec2/" -ForegroundColor Gray
                Write-Host "   • VPC: https://console.aws.amazon.com/vpc/" -ForegroundColor Gray
                Write-Host "   • Cost Dashboard: https://console.aws.amazon.com/billing/" -ForegroundColor Gray
            }
            else {
                Write-Error "❌ Destruction failed! Check AWS Console manually."
                Write-Host "   You may need to manually delete some resources." -ForegroundColor Yellow
            }
        }
        else {
            Write-Host "🚫 Destruction cancelled. No resources were deleted." -ForegroundColor Yellow
        }
        return
    }
    
    # Plan deployment
    Write-Host ""
    Write-Host "📋 Creating deployment plan..." -ForegroundColor Yellow
    Write-Host "   This shows exactly what resources will be created..." -ForegroundColor Gray
    Write-Host ""
    
    terraform plan -var-file="../$tfVarsFile"
    if ($LASTEXITCODE -ne 0) {
        throw "Terraform plan failed"
    }
    
    # If only planning, exit here
    if ($Plan) {
        Write-Host ""
        Write-Host "===================================================" -ForegroundColor Green
        Write-Host "                PLAN COMPLETED" -ForegroundColor Green
        Write-Host "===================================================" -ForegroundColor Green
        if ($UserName -ne "") {
            Write-Host ("📊 Resources planned for student: " + $UserName) -ForegroundColor Green
            Write-Host ("🏷️  Cluster name: " + $clusterName) -ForegroundColor Green
        }
        Write-Host "💰 Estimated monthly cost: ~`$153.00" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "📚 Next steps:" -ForegroundColor Cyan
        Write-Host "   To deploy: Remove -Plan flag and run again" -ForegroundColor White
        Write-Host ("   Command: .\deploy.ps1 -UserName `"$UserName`" -Environment $Environment") -ForegroundColor White
        return
    }
    
    # Final deployment confirmation
    Write-Host ""
    Write-Host "===================================================" -ForegroundColor Yellow
    Write-Host "              🚀 READY TO DEPLOY" -ForegroundColor Yellow
    Write-Host "===================================================" -ForegroundColor Yellow
    Write-Host "📊 This deployment will create AWS resources with:" -ForegroundColor White
    Write-Host "   💰 Monthly Cost: ~`$153.00" -ForegroundColor Yellow
    Write-Host "   ⏱️  Deployment Time: 15-20 minutes" -ForegroundColor White
    Write-Host "   🌍 Region: us-west-2" -ForegroundColor White
    if ($UserName -ne "") {
        Write-Host ("   👤 Student: " + $UserName) -ForegroundColor White
        Write-Host ("   🏷️  Cluster: " + $clusterName) -ForegroundColor White
    }
    Write-Host ""
    Write-Host "⚠️  IMPORTANT REMINDERS:" -ForegroundColor Red
    Write-Host "   • AWS will START CHARGING immediately when resources are created" -ForegroundColor Red
    Write-Host "   • EKS cluster takes 15-20 minutes to provision" -ForegroundColor Red
    Write-Host "   • Remember to DESTROY resources when done to stop charges" -ForegroundColor Red
    Write-Host "   • Monitor your AWS billing dashboard regularly" -ForegroundColor Red
    Write-Host "===================================================" -ForegroundColor Yellow
    
    if (-not $AutoApprove) {
        Write-Host ""
        $deployConfirm = Read-Host "🚀 Do you want to proceed with deployment? Type 'yes' to continue"
        if ($deployConfirm -ne "yes") {
            Write-Host "🚫 Deployment cancelled. No resources were created." -ForegroundColor Yellow
            return
        }
    }
    
    # Apply deployment
    Write-Host ""
    Write-Host "===================================================" -ForegroundColor Green
    Write-Host "              🚀 DEPLOYING INFRASTRUCTURE" -ForegroundColor Green
    Write-Host "===================================================" -ForegroundColor Green
    Write-Host "⏳ Starting deployment... (This will take 15-20 minutes)" -ForegroundColor Yellow
    Write-Host "💰 AWS charges will start as resources are created..." -ForegroundColor Yellow
    if ($UserName -ne "") {
        Write-Host ("👤 Deploying for student: " + $UserName) -ForegroundColor Cyan
    }
    Write-Host ""
    Write-Host "📊 Progress will be shown below..." -ForegroundColor Gray
    Write-Host ""
    
    if ($AutoApprove) {
        terraform apply -var-file="../$tfVarsFile" -auto-approve
    } else {
        terraform apply -var-file="../$tfVarsFile"
    }
    
    if ($LASTEXITCODE -ne 0) {
        throw "Terraform apply failed"
    }
    
    Write-Host ""
    Write-Host "===================================================" -ForegroundColor Green
    Write-Host "            ✅ DEPLOYMENT SUCCESSFUL!" -ForegroundColor Green
    Write-Host "===================================================" -ForegroundColor Green
    Write-Host "🎉 Infrastructure has been created successfully!" -ForegroundColor Green
    Write-Host "💰 AWS resources are now running and being charged." -ForegroundColor Yellow
    
    # Configure kubectl with better error handling
    Write-Host ""
    Write-Host "🔧 Configuring kubectl..." -ForegroundColor Yellow
    try {
        $kubectlCommand = terraform output -raw kubectl_config 2>$null
        if ($kubectlCommand -and $LASTEXITCODE -eq 0) {
            Invoke-Expression $kubectlCommand
            Write-Host "✅ kubectl configured successfully!" -ForegroundColor Green
            
            # Test cluster connection
            Write-Host ""
            Write-Host "🧪 Testing cluster connection..." -ForegroundColor Yellow
            $nodeCount = kubectl get nodes --no-headers 2>$null | Measure-Object | Select-Object -ExpandProperty Count
            if ($nodeCount -gt 0) {
                Write-Host "✅ Cluster connection successful! Found $nodeCount node(s)" -ForegroundColor Green
                kubectl get nodes
            } else {
                Write-Warning "⚠️  Cluster connection may be slow. Try again in a few minutes."
            }
            
            # Check application pods
            try {
                Write-Host ""
                Write-Host "🔍 Checking application status..." -ForegroundColor Yellow
                $namespace = terraform output -raw namespace 2>$null
                if ($namespace) {
                    kubectl get pods -n $namespace
                    Write-Host ""
                    Write-Host "📊 Service status:" -ForegroundColor Yellow
                    kubectl get services -n $namespace
                } else {
                    Write-Host "Application namespace: guestlist-dev" -ForegroundColor Gray
                    kubectl get pods -n guestlist-dev 2>$null
                    kubectl get services -n guestlist-dev 2>$null
                }
            }
            catch {
                Write-Warning "⚠️  Could not check application status. Cluster may still be initializing."
            }
        } else {
            Write-Warning "⚠️  Could not auto-configure kubectl. Use manual command below."
        }
    }
    catch {
        Write-Warning "⚠️  kubectl configuration failed. Use manual command below."
    }
    
    # Display comprehensive results
    Write-Host ""
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host "              📊 DEPLOYMENT SUMMARY" -ForegroundColor Cyan  
    Write-Host "===================================================" -ForegroundColor Cyan
    
    # Student and environment info
    $studentDisplay = if ($UserName) { $UserName } else { "Not specified" }
    Write-Host ("👤 Student: " + $studentDisplay) -ForegroundColor White
    Write-Host ("🌍 Environment: " + $Environment) -ForegroundColor White
    
    # Get outputs with error handling
    try {
        $clusterOutput = terraform output -raw cluster_name 2>$null
        if ($clusterOutput -and $LASTEXITCODE -eq 0) {
            Write-Host ("🏷️  Cluster: " + $clusterOutput) -ForegroundColor White
        } else {
            Write-Host ("🏷️  Cluster: " + $(if ($clusterName) { $clusterName } else { "Check terraform output" })) -ForegroundColor White
        }
        
        $appUrl = terraform output -raw application_url 2>$null
        if ($appUrl -and $LASTEXITCODE -eq 0 -and $appUrl -ne "pending - check load balancer status") {
            Write-Host ("🌐 Application URL: " + $appUrl) -ForegroundColor White
        } else {
            Write-Host "🌐 Application URL: Load balancer provisioning (check in 5-10 minutes)" -ForegroundColor Yellow
            Write-Host "   Get URL: kubectl get service guestlist-service -n guestlist-dev" -ForegroundColor Gray
        }
        
        Write-Host "💰 Estimated Monthly Cost: ~`$153.00" -ForegroundColor Yellow
        
        # Additional useful info
        Write-Host ""
        Write-Host "🔧 Management Commands:" -ForegroundColor Cyan
        Write-Host "   Configure kubectl: aws eks update-kubeconfig --region us-west-2 --name $($clusterOutput)" -ForegroundColor Gray
        Write-Host "   Check nodes:       kubectl get nodes" -ForegroundColor Gray
        Write-Host "   Check pods:        kubectl get pods -n guestlist-dev" -ForegroundColor Gray
        Write-Host "   View logs:         kubectl logs -l app=guestlist -n guestlist-dev" -ForegroundColor Gray
        Write-Host "   Get service URL:   kubectl get service guestlist-service -n guestlist-dev" -ForegroundColor Gray
    }
    catch {
        Write-Host "💡 For detailed information, run: terraform output" -ForegroundColor Gray
    }
    
    Write-Host ""
    Write-Host "===================================================" -ForegroundColor Green
    Write-Host "                📚 NEXT STEPS" -ForegroundColor Green
    Write-Host "===================================================" -ForegroundColor Green
    Write-Host "1. 🧪 Test your API:" -ForegroundColor White
    Write-Host "   • Wait 5-10 minutes for load balancer to be ready" -ForegroundColor Gray
    Write-Host "   • Get URL: kubectl get service guestlist-service -n guestlist-dev" -ForegroundColor Gray
    Write-Host "   • Test: curl http://[LOAD-BALANCER-URL]/guests" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. 📊 Monitor your deployment:" -ForegroundColor White
    Write-Host "   • AWS Console: https://console.aws.amazon.com/eks/" -ForegroundColor Gray
    Write-Host "   • Billing: https://console.aws.amazon.com/billing/" -ForegroundColor Gray
    Write-Host "   • Use Lens: Connect to your cluster for GUI management" -ForegroundColor Gray
    Write-Host ""
    Write-Host "3. 🔧 Scale if needed:" -ForegroundColor White
    Write-Host "   • kubectl scale deployment guestlist-deployment --replicas=3 -n guestlist-dev" -ForegroundColor Gray
    Write-Host ""
    Write-Host "4. 💰 IMPORTANT - Cleanup when done:" -ForegroundColor Yellow
    if ($UserName -ne "") {
        Write-Host ("   .\deploy.ps1 -UserName `"" + $UserName + "`" -Environment " + $Environment + " -Destroy") -ForegroundColor Red
    }
    else {
        Write-Host ("   .\deploy.ps1 -Environment " + $Environment + " -Destroy") -ForegroundColor Red
    }
    Write-Host ""
    Write-Host "💡 Pro Tips:" -ForegroundColor Cyan
    Write-Host "   • Set up AWS billing alerts to monitor costs" -ForegroundColor White
    Write-Host "   • Destroy resources daily if not actively using" -ForegroundColor White
    Write-Host "   • Use 'kubectl get all -n guestlist-dev' to see all resources" -ForegroundColor White
    Write-Host "   • Check pod logs if API doesn't respond: kubectl logs -l app=guestlist -n guestlist-dev" -ForegroundColor White
    
}
catch {
    Write-Host ""
    Write-Host "===================================================" -ForegroundColor Red
    Write-Host "               ❌ DEPLOYMENT FAILED" -ForegroundColor Red
    Write-Host "===================================================" -ForegroundColor Red
    Write-Error "Deployment failed: $_"
    
    Write-Host ""
    Write-Host "🔧 Troubleshooting steps:" -ForegroundColor Yellow
    Write-Host "1. Check AWS credentials: aws sts get-caller-identity" -ForegroundColor White
    Write-Host "2. Check AWS quotas: https://console.aws.amazon.com/servicequotas/" -ForegroundColor White
    Write-Host "3. Try a different region in your terraform.tfvars file" -ForegroundColor White
    Write-Host "4. Clean up any partial resources: terraform destroy" -ForegroundColor White
    Write-Host ""
    Write-Host "🆘 If resources were partially created:" -ForegroundColor Yellow
    Write-Host "   Run: terraform destroy -var-file=`"../$tfVarsFile`"" -ForegroundColor Red
    Write-Host "   This will clean up any AWS resources that were created" -ForegroundColor Yellow
    
    exit 1
}
finally {
    Pop-Location
}

Write-Host ""
Write-Host "===================================================" -ForegroundColor Green
Write-Host "               🎉 SCRIPT COMPLETED!" -ForegroundColor Green
Write-Host "===================================================" -ForegroundColor Green
