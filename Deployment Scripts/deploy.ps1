# Guest List Deployment Script - PowerShell
# This script deploys the Guest List infrastructure to AWS EKS

param(
    [string]$Environment = "dev",
    [switch]$Destroy = $false,
    [switch]$Plan = $false,
    [switch]$Verbose = $false
)

Write-Host "🚀 Guest List Deployment Script" -ForegroundColor Green
Write-Host "=================================" -ForegroundColor Green

# Check if we're in the right directory
if (-not (Test-Path "terraform")) {
    Write-Error "❌ terraform directory not found. Please run this script from the project root."
    exit 1
}

# Validate environment
$validEnvironments = @("dev", "staging", "prod")
if ($Environment -notin $validEnvironments) {
    Write-Error "❌ Invalid environment. Must be one of: $($validEnvironments -join ', ')"
    exit 1
}

# Set environment file path
$envFile = "environments\$Environment\terraform.tfvars"
$envFileLocal = "environments\$Environment\terraform.tfvars.local"

if (-not (Test-Path $envFile)) {
    Write-Error "❌ Environment file not found: $envFile"
    exit 1
}

Write-Host "📁 Using environment: $Environment" -ForegroundColor Cyan

# Check if local override exists
if (Test-Path $envFileLocal) {
    Write-Host "📝 Using local override file: $envFileLocal" -ForegroundColor Yellow
    $tfVarsFile = $envFileLocal
} else {
    Write-Host "📝 Using environment file: $envFile" -ForegroundColor Blue
    Write-Host "💡 Tip: Copy to terraform.tfvars.local for local customization" -ForegroundColor Gray
    $tfVarsFile = $envFile
}

# Change to terraform directory
Push-Location terraform

try {
    # Check for required tools
    Write-Host "`n🔧 Checking prerequisites..." -ForegroundColor Yellow
    
    $tools = @(
        @{name="terraform"; command="terraform --version"},
        @{name="aws"; command="aws --version"},
        @{name="kubectl"; command="kubectl version --client"}
    )
    
    foreach ($tool in $tools) {
        try {
            $null = Invoke-Expression $tool.command
            Write-Host "✅ $($tool.name) is installed" -ForegroundColor Green
        } catch {
            Write-Error "❌ $($tool.name) is not installed or not in PATH"
            exit 1
        }
    }
    
    # Check AWS credentials
    try {
        $null = aws sts get-caller-identity
        Write-Host "✅ AWS credentials are configured" -ForegroundColor Green
    } catch {
        Write-Error "❌ AWS credentials not configured. Run 'aws configure'"
        exit 1
    }
    
    Write-Host "`n🏗️  Initializing Terraform..." -ForegroundColor Yellow
    terraform init
    if ($LASTEXITCODE -ne 0) {
        throw "Terraform init failed"
    }
    
    if ($Destroy) {
        Write-Host "`n🗑️  DESTROYING infrastructure..." -ForegroundColor Red
        Write-Host "⚠️  This will delete ALL resources!" -ForegroundColor Red
        $confirmation = Read-Host "Type 'yes' to confirm destruction"
        
        if ($confirmation -eq "yes") {
            $destroyArgs = @("destroy", "-var-file=../$tfVarsFile")
            if ($Verbose) { $destroyArgs += "-verbose" }
            
            & terraform @destroyArgs
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ Infrastructure destroyed successfully!" -ForegroundColor Green
            } else {
                Write-Error "❌ Destruction failed!"
            }
        } else {
            Write-Host "🚫 Destruction cancelled" -ForegroundColor Yellow
        }
        return
    }
    
    Write-Host "`n📋 Planning deployment..." -ForegroundColor Yellow
    $planArgs = @("plan", "-var-file=../$tfVarsFile")
    if ($Verbose) { $planArgs += "-verbose" }
    
    & terraform @planArgs
    if ($LASTEXITCODE -ne 0) {
        throw "Terraform plan failed"
    }
    
    if ($Plan) {
        Write-Host "`n✅ Plan completed successfully!" -ForegroundColor Green
        return
    }
    
    Write-Host "`n🚀 Applying deployment..." -ForegroundColor Yellow
    Write-Host "⏳ This may take 15-20 minutes for EKS cluster creation..." -ForegroundColor Gray
    
    $applyArgs = @("apply", "-var-file=../$tfVarsFile")
    if (-not $Verbose) { $applyArgs += "-auto-approve" }
    
    & terraform @applyArgs
    if ($LASTEXITCODE -ne 0) {
        throw "Terraform apply failed"
    }
    
    Write-Host "`n✅ Deployment completed successfully!" -ForegroundColor Green
    
    # Get outputs
    Write-Host "`n📊 Deployment Information:" -ForegroundColor Cyan
    terraform output -json | ConvertFrom-Json | ForEach-Object {
        $_.PSObject.Properties | ForEach-Object {
            Write-Host "$($_.Name): $($_.Value.value)" -ForegroundColor White
        }
    }
    
    # Configure kubectl
    Write-Host "`n🔧 Configuring kubectl..." -ForegroundColor Yellow
    $kubectlConfig = terraform output -raw kubectl_config
    if ($kubectlConfig) {
        Invoke-Expression $kubectlConfig
        Write-Host "✅ kubectl configured successfully!" -ForegroundColor Green
        
        # Test cluster connection
        Write-Host "`n🧪 Testing cluster connection..." -ForegroundColor Yellow
        kubectl get nodes
        kubectl get pods -n (terraform output -raw namespace)
    }
    
    Write-Host "`n🎉 Deployment Summary:" -ForegroundColor Green
    Write-Host "   Environment: $Environment" -ForegroundColor White
    Write-Host "   Cluster: $(terraform output -raw cluster_name)" -ForegroundColor White
    Write-Host "   Application URL: $(terraform output -raw application_url)" -ForegroundColor White
    Write-Host "   Estimated Cost: $(terraform output -json estimated_monthly_cost | ConvertFrom-Json | Select-Object -ExpandProperty total_estimate)" -ForegroundColor White
    
    Write-Host "`n📚 Next Steps:" -ForegroundColor Cyan
    Write-Host "   1. Test the API: curl $(terraform output -raw application_url)" -ForegroundColor White
    Write-Host "   2. Monitor costs in AWS Console" -ForegroundColor White
    Write-Host "   3. Scale if needed: kubectl scale deployment guestlist-deployment --replicas=3" -ForegroundColor White
    Write-Host "   4. Clean up when done: .\deploy.ps1 -Destroy" -ForegroundColor White
    
} catch {
    Write-Error "❌ Deployment failed: $_"
    exit 1
} finally {
    Pop-Location
}

Write-Host "`n🏁 Script completed!" -ForegroundColor Green
