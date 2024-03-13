$DebugPreference = 'Continue'
$ErrorActionPreference = 'Stop'
# This is also the same script that runs on Github via the Github Action configured in .github/workflows - there, the
# DEVHUB_SFDX_URL.txt file is populated in a build step
$testInvocation = 'npx sf apex run test -s ApexDmlMockingSuite -r human -w 20 -d ./tests/apex'
$userAlias = 'apex-dml-mocking-scratch'

function Remove-Scratch-Org() {
  try {
    Write-Debug "Deleting scratch org ..."
    npx sf org delete scratch --no-prompt -o $userAlias
  } catch {
    Write-Debug "Scratch org deletion failed, continuing ..."
  }
}

function Start-Deploy() {
  Write-Debug "Deploying source ..."
  npx sf project deploy start --source-dir force-app
  npx sf project deploy start --source-dir example-app
}

function Start-Tests() {
  Write-Debug "Starting test run ..."
  Invoke-Expression $testInvocation
  $testRunId = Get-Content tests/apex/test-run-id.txt
  $specificTestRunJson = Get-Content "tests/apex/test-result-$testRunId.json" | ConvertFrom-Json
  $testFailure = $false
  if ($specificTestRunJson.summary.outcome -eq "Failed") {
    $testFailure = $true
  }

  if ($true -eq $testFailure) {
    Remove-Scratch-Org
    throw 'Test run failure!'
  }

  npx sf apex run -f scripts/validate-history-query.apex -o $userAlias
  Remove-Scratch-Org
}

Write-Debug "Starting build script"

# For local dev, store currently auth'd org to return to
# Also store test command shared between script branches, below
$scratchOrgAllotment = ((npx sf org list limits --json | ConvertFrom-Json).result | Where-Object -Property name -eq "DailyScratchOrgs").remaining

Write-Debug "Total remaining scratch orgs for the day: $scratchOrgAllotment"
Write-Debug "Test command to use: $testInvocation"

if($scratchOrgAllotment -gt 0) {
  try {
    Write-Debug "Beginning scratch org creation"
    # Create Scratch Org
    npx sf org create scratch --definition-file config/project-scratch-def.json --alias $userAlias --set-default --duration-days
    npx sf config set target-org $userAlias
  } catch {
    # Do nothing, we'll just try to deploy to the Dev Hub instead
  }
}

Start-Deploy
Start-Tests

Write-Debug "Build + testing finished successfully"

