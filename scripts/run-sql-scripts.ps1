<#
.SYNOPSIS
    Runs the SQL setup scripts against the database using Entra ID authentication.

.DESCRIPTION
    Discovers the SQL server from the resource group tagged with azd-env-name,
    then runs 001-create-tables.sql and 002-seed-data.sql in order.
    Uses the logged-in az CLI identity for Entra (AAD) token-based auth.

.PARAMETER ResourceGroupName
    Azure resource group containing the SQL server. If omitted, discovered via azd env.

.PARAMETER DatabaseName
    Database name. Defaults to 'sis-db'.
#>
param(
    [string]$ResourceGroupName,
    [string]$DatabaseName = 'sis-db'
)

$ErrorActionPreference = 'Stop'
$scriptRoot = $PSScriptRoot

# --- Resolve resource group from azd if not supplied ---
if (-not $ResourceGroupName) {
    $envName = (azd env get-value AZURE_ENV_NAME 2>$null)
    if (-not $envName) { throw "Could not determine azd environment name. Pass -ResourceGroupName explicitly." }
    $ResourceGroupName = "rg-$envName"
    Write-Host "Using resource group: $ResourceGroupName"
}

# --- Find the SQL server in the resource group ---
$servers = az sql server list --resource-group $ResourceGroupName --query "[].fullyQualifiedDomainName" -o tsv 2>$null
if (-not $servers) { throw "No SQL server found in resource group '$ResourceGroupName'." }
$sqlFqdn = ($servers -split "`n")[0].Trim()
Write-Host "SQL Server: $sqlFqdn"
Write-Host "Database:   $DatabaseName"

# --- Get an Entra ID access token for Azure SQL ---
$tokenResponse = az account get-access-token --resource https://database.windows.net/ --query accessToken -o tsv
if (-not $tokenResponse) { throw "Failed to acquire Entra ID token. Make sure you are logged in with 'az login'." }

# --- Grant the managed identity access to the database ---
Write-Host "`nGranting managed identity access to database..." -ForegroundColor Cyan
$miNames = az identity list --resource-group $ResourceGroupName --query "[].name" -o tsv 2>$null
foreach ($mi in ($miNames -split "`n" | Where-Object { $_.Trim() })) {
    $mi = $mi.Trim()
    $grantSql = @"
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = '$mi')
BEGIN
    CREATE USER [$mi] FROM EXTERNAL PROVIDER;
    ALTER ROLE db_datareader ADD MEMBER [$mi];
    ALTER ROLE db_datawriter ADD MEMBER [$mi];
    PRINT 'Created user and granted roles: $mi';
END
ELSE
    PRINT 'User already exists: $mi';
"@
    Write-Host "  Granting access for: $mi"
    Invoke-Sqlcmd `
        -ServerInstance $sqlFqdn `
        -Database $DatabaseName `
        -AccessToken $tokenResponse `
        -Query $grantSql `
        -QueryTimeout 60 `
        -ErrorAction Stop
}
Write-Host "  Done." -ForegroundColor Green

# --- Run each script in order ---
$scripts = @(
    Join-Path $scriptRoot '001-create-tables.sql'
    Join-Path $scriptRoot '002-seed-data.sql'
)

foreach ($sqlFile in $scripts) {
    if (-not (Test-Path $sqlFile)) {
        Write-Warning "Script not found, skipping: $sqlFile"
        continue
    }
    Write-Host "`nRunning: $(Split-Path $sqlFile -Leaf) ..." -ForegroundColor Cyan
    $sql = Get-Content $sqlFile -Raw

    # Use SqlServer module's Invoke-Sqlcmd with access token
    Invoke-Sqlcmd `
        -ServerInstance $sqlFqdn `
        -Database $DatabaseName `
        -AccessToken $tokenResponse `
        -Query $sql `
        -QueryTimeout 120 `
        -ErrorAction Stop

    Write-Host "  Done." -ForegroundColor Green
}

Write-Host "`nAll scripts completed successfully." -ForegroundColor Green
