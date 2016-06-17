# Introduction to Pester - viewpoint of an ITPro
Pester is a unit testing framework. 
To show the value to the ITPro about the use case of Pester, this session will focus on how Pester can be used in Infrastructure realm.

## Download Pester
Download Pester from PowerShell gallery

```PowerShell
Install-Module -Name Pester -Scope CurrentUser 
```

## Starting - create a fixture
Skeletal for starting with Pester.

```PowerShell
New-Fixture -Path . -Name HelloPSBUG
```

Pester tests live inside the .Tests.ps1 file.
Initial test template

```PowerShell
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Describe "HelloPSBUG" {
    It "does something useful" {
        $true | Should Be $false
    }
}
```


### Describe
- **Named** logical boundary/ container to test a function (or functionality).
- Creates a scope for mocking & test drive.
- Use tags for invoking similar tests.

```PowerShell
Describe 'HelloPSBUG' -Tags WebSiteTest {
    $Service = Get-Service -Name wwwsvc

    It 'Should be running' {
        $service.Status | Should be 'Running'
    }
}
```
### Context 
- Optional container to group tests.
- Creates its own mocking scope too.

```PowerShell
Describe 'HelloPSBUG' -Tags WebSiteTest {
    
    Context 'Web service tests' {
        # tests to check if the service is up and running        
    }

    Context 'File tests' {
        # tests to check if the index.html & default.html are present   
    }

    Context 'Role tests' {
        # tests to check if the required roles are installed
    }
}
```

## It
- This is where you assert, encloses tests.
- Does not create a mock scope.

```PowerShell
Describe 'HelloPSBUG' -Tags WebSiteTest {
    $Service = Get-Service -Name wwwsvc
    
    Context 'Web service tests' {
        
        It 'Should be running the www service' {
            $service.Status | Should be 'Running'
        }
    }

    Context 'File tests' {
        It 'Should have an index.html' {
            Test-Path -Path "$env:SystemDrive\InetPub\
        }
    }

    Context 'Role tests' {
        $RequiredFeatures = @(' Web-Server',' Web-WebServer'.'web-default-doc','Web-ASP-Net')
        foreach ($feature in $RequiredFeatures) {
            $featureObject = Get-WindowsFeature -Name $feature
            It "Should have the $($Feature.Name) installed" {
                $featureObject.Installed | Should be $True
            }
        }
    }
}
```
## Head back to Unit testing
All the above tests have been integration tests.

What if you are writing a function which creates a new website (installs features & does required config). 
You want to test it in your local machine rather than a server. Since your machine will never have the required features, you can only test the logic of your function.

For example - logic demands that if the required features are not installed, install them.

```PowerShell
Function Install-WebServerFeature {
    param($Features)
    foreach($feature in $Features){
        $FeatureInstalled = Get-WindowsFeature -Name $feature | Select -ExpandProperty Installed
        if ($FeatureInstalled){
            # Do nothing
        }
        else{
            # install the feature
            Install-WindowsFeature -Name $feature
        }
    }
}
```

How do you test the logic of above code on a machine running Windows 7 ?

## Enter Mocking

The idea behing unit tests is that they should be independent of the underlying system and should be very fast to run.
You will need to mock the missing cmdlet in the above.

```PowerShell
Describe 'Install-WebServerFeature' -Tag UnitTest {

    Context 'If the feature is not installed' {
        # Arrange
        Mock -CommandName Get-WindowsFeature -MockWith {[pscustomobject]@{Installed=$False}}
        Mock -CommandName Install-WindowsFeature -MockWith {}

        # Act
        Install-WebServerFeature -Features web-webserver
        
        # Assert
        It 'Should call Get-WindowsFeature to query if the feature is installed' {
            Assert-MockCalled -CommandName Get-WindowsFeature -Times 1 -Exactly
        }

        It 'Should not call Install-WindowsFeature to install the feature' {
            Assert-MockCalled -CommandName Install-WindowsFeature -Times 1 -Exactly
        }

    }
}
```


## Pester in Release pipeline

Pester can take two places in the release pipeline. 

  1. Build --> run unit tests to verify that nothing broke in the latest commit.
  2. Test --> Run integration & acceptance tests to verify that the PS module as a whole is working.
  

Pester is CI ready
- Invoke-Pester with -EnableExit switch to let the CI know that the tests failed.
- Pester.bat placed in the \bin directory to be used in CI servers (without worrying about execution policy).
- Pester can generate NUnit style results artifcats which most of the CI servers already have plugins to consume it. 

## Anatomy

Credits - https://www.simple-talk.com/sysadmin/powershell/practical-powershell-unit-testing-getting-started/

```
<file-preamble>
InModuleScope <module-name> {
    <module-preamble>
    Describe <test-name> {
        <one-time-describe-initialization>
        BeforeEach {
            <per-test-initialization>
        }
        AfterEach {
            <per-test-cleanup>
        }
        Context <context-description> {
            <one-time-context-initialization>
            It <test-description> {
                <test-code>
            }
            . . .
            It <test-description> {
                <test-code>
            }
            BeforeEach {
                <per-test-initialization>
            }
            AfterEach {
                <per-test-cleanup>
            }
        }
        . . .
        Context <context-description> {
            It <test-description> {
                <test-code>
            }
        }
    }
    . . .
    Describe <test-name> {
        Context <context-description> {
            It <test-description> {
                <test-code>
            }
        }
    }
}
 
```
