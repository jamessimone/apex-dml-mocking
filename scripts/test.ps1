$DebugPreference = 'Continue'
$ErrorActionPreference = 'Stop'
# This is also the same script that runs on Github via the Github Action configured in .github/workflows - there, the
# DEVHUB_SFDX_URL.txt file is populated in a build step
$testInvocation = 'npx sfdx force:apex:test:run -s ApexDmlMockingSuite -r human -w 20 -d ./tests/apex'
$userAlias = 'apex-dml-mocking-scratch'

function Remove-Scratch-Org() {
  try {
    Write-Debug "Deleting scratch org ..."
    npx sfdx force:org:delete -p -u $userAlias
  } catch {
    Write-Debug "Scratch org deletion failed, continuing ..."
  }
}

function Start-Deploy() {
  Write-Debug "Deploying source ..."
  npx sfdx force:source:deploy -p force-app
  npx sfdx force:source:deploy -p example-app
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

  npx sfdx force:apex:execute -f scripts/validate-history-query.apex -u $userAlias
  Remove-Scratch-Org
}

Write-Debug "Starting build script"

# For local dev, store currently auth'd org to return to
# Also store test command shared between script branches, below
$scratchOrgAllotment = ((npx sfdx force:limits:api:display --json | ConvertFrom-Json).result | Where-Object -Property name -eq "DailyScratchOrgs").remaining

Write-Debug "Total remaining scratch orgs for the day: $scratchOrgAllotment"
Write-Debug "Test command to use: $testInvocation"

if($scratchOrgAllotment -gt 0) {
  try {
    Write-Debug "Beginning scratch org creation"
    # Create Scratch Org
    npx sfdx force:org:create -f config/project-scratch-def.json -a $userAlias -s -d 1
    npx sfdx config:set defaultusername=$userAlias
  } catch {
    # Do nothing, we'll just try to deploy to the Dev Hub instead
  }
}

Start-Deploy
Start-Tests

Write-Debug "Build + testing finished successfully"

