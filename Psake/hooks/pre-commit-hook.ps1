
# import the psake Module
Import-Module -Name Psake -ErrorAction Stop
properties {
    $ProjectName = 'DellDeploy'
}

$branch = git rev-parse --abbrev-ref HEAD # get the current branch name
$ModulePath = Resolve-Path "$PSScriptRoot\..\..\$ProjectName"

# Task to validate, 
task -name validateBranchNotMaster -Description 'Branch Check task' -Action {
    assert ($branch -notLike '*Master') "Invalid branch push , Do not push to master branch from here."
}


task -Name ScriptAnalyze -Depends validateBranchNotMaster -Description 'ScriptAnalyze task' -action {
    Write-Host 'Starting Script Analyzer'
    try {
        $results = Invoke-ScriptAnalyzer -Path ..\..\$ProjectName
        $results
    }
    catch {
        Write-Error -Message $_
        exit 1
    }
     
    if ($results.Count -gt 0) {
        Write-Error "Analysis of your code threw $($results.Count) warnings or errors. Please go back and check your code."
        exit 1
    }
}


task -Name UnitTest -Depends ScriptAnalyze -Description 'Runs unit tests task.' -Action {
    Import-Module -name Pester
    Invoke-Pester -Path ..\..\Tests -EnableExit # run the Pester tests
}

task -Name Default -Depends UnitTest