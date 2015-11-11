#starts a new powershell console with specified credentials, similar to su(1) on UNIX
function Switch-User {
    param(
      [string] $Username  
    )
    
	if( -not $Username ) {
		#look up the built-in Administrator account using WMI.
		#the built-in administrator has a SID that starts with S-1-5 and ends with -500.
		$accts = Get-WmiObject -Class win32_useraccount

		foreach( $acct in $accts ) {
			if( $acct.SID -match '^S-1-5-.+-500$' ) {
				$Username = $acct.Caption
				if( $Username -match "[^\\]+$" ) {
					$Username = $matches[0]
				}
				break
			}
		}
	}

	$credential = Get-ConsoleCredential -Username $Username
	$startInfo = New-Object -TypeName Diagnostics.ProcessStartInfo
	$startInfo.UseShellExecute = $false
	$startInfo.FileName = "$pshome\powershell.exe"
	$startInfo.UserName = $credential.UserName
	$startInfo.Password = $credential.Password
	$startInfo.WorkingDirectory = $pwd

	trap [ComponentModel.Win32Exception] {
		if( $_.Exception.NativeErrorCode -eq 267 ) {
			Write-Host -Object "$pwd is an invalid directory for $Username."
			Write-Host -Object "Starting PowerShell in ${env:SystemRoot}\system32."
			$startInfo.WorkingDirectory = "${env:SystemRoot}\system32"
			$null = [Diagnostics.Process]::Start( $startInfo )
		} else {
			$_.Exception.Message
			$_.Exception.NativeErrorCode
		}
		continue
	}
	$null = [Diagnostics.Process]::Start( $startInfo )
}

#Generate a PSCredential object without creating a pop-up security dialog like
#the built-in get-credential cmdlet.
function Get-ConsoleCredential {
    param(
        [string] $Username = ( Read-Host -Prompt 'Username' ) 
    )
    
	while ( -not $Username ) {
		$Username = Read-Host -Prompt 'Username'
	}

	$passwd = Read-Host -AsSecureString 'Password'
	$cred = New-Object Management.Automation.PSCredential $Username, $passwd
    return $cred
}

New-Alias -Name 'su' -Value 'Switch-User'
New-Alias -Name 'cred' -Value 'Get-ConsoleCredential'
