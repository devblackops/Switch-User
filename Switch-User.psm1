#starts a new powershell console with specified credentials, similar to su(1) on UNIX

function Switch-User( [String] $username ) {
    if( !$username ) {
		#look up the built-in Administrator account using WMI.
		#the built-in administrator has a SID that starts with S-1-5 and ends with -500.

		$accts = get-wmiobject win32_useraccount

		foreach( $acct in $accts ) {
			if( $acct.SID -match '^S-1-5-.+-500$' ) {
				$username = $acct.Caption
				if( $username -match "[^\\]+$" ) {
					$username = $matches[0]
				}
				break
			}
		}
	}

	$credential = Get-ConsoleCredential( $username )
	$startinfo = new-object Diagnostics.ProcessStartInfo
	$startinfo.UseShellExecute = $false
	$startinfo.FileName = "$pshome\powershell.exe"
	$startinfo.UserName = $credential.UserName
	$startinfo.Password = $credential.Password
	$startinfo.WorkingDirectory = $pwd

	trap [ComponentModel.Win32Exception] {
		if( $_.Exception.NativeErrorCode -eq 267 ) {
			write-host "$pwd is an invalid directory for $username."
			write-host "Starting PowerShell in ${env:SystemRoot}\system32."
			$startinfo.WorkingDirectory = "${env:SystemRoot}\system32"
			$null = [Diagnostics.Process]::Start( $startinfo )
		} else {
			$_.Exception.Message
			$_.Exception.NativeErrorCode
		}

		continue
	}
	$null = [Diagnostics.Process]::Start( $startinfo )
}

#Generate a PSCredential object without creating a pop-up security dialog like
#the built-in get-credential cmdlet.
function Get-ConsoleCredential( [String] $username=$( read-host 'Username' ) ) {
	while( !($username) ) {
		$username = read-host 'Username'
	}

	$passwd = Read-Host -AsSecureString 'Password'
	new-object Management.Automation.PSCredential $username, $passwd
}

New-Alias -Name 'su' -Value 'Switch-User'
New-Alias -Name 'cred' -Value 'Get-ConsoleCredential'
