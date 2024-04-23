Add-Type -AssemblyName System.Web
Function Invoke-Nxql {
	<#
	.SYNOPSIS
	Sends an NXQL query to a Nexthink engine.

	.DESCRIPTION
	 Sends an NXQL query to the Web API of Nexthink Engine as HTTP GET using HTTPS.
	 
	.PARAMETER ServerName
	 Nexthink Engine name or IP address.

	.PARAMETER PortNumber
	Port number of the Web API (default 1671).

	.PARAMETER UserName
	User name of the Finder account under which the query is executed.

	.PARAMETER UserPassword
	User password of the Finder account under which the query is executed.

	.PARAMETER NxqlQuery
	NXQL query.

	.PARAMETER FirstParamter
	Value of %1 in the NXQL query.

	.PARAMETER SecondParamter
	Value of %2 in the NXQL query.

	.PARAMETER OuputFormat
	NXQL query output format i.e. csv, xml, html, json (default csv).

	.PARAMETER Platforms
	Platforms on which the query applies i.e. windows, mac_os, mobile (default windows).
	
	.EXAMPLE
	Invoke-Nxql -ServerName 176.31.63.200 -UserName "admin" -UserPassword "admin" 
	-Platforms=windows,mac_os -NxqlQuery "(select (name) (from device))"
	#>
	Param(
		[Parameter(Mandatory=$true)]
		[string]$ServerName,
		[Parameter(Mandatory=$true)]
		[string]$UserName,
		[Parameter(Mandatory=$true)]
		[SecureString]$UserPassword,
		[Parameter(Mandatory=$true)]
		[string]$Query,
		[Parameter(Mandatory=$false)]
		[int]$PortNumber = 443,
		[Parameter(Mandatory=$false)]
		[string]$OuputFormat = "csv",
		[Parameter(Mandatory=$false)]
		[string[]]$Platforms = "windows",
		[Parameter(Mandatory=$false)]
		[string]$FirstParameter,
		[Parameter(Mandatory=$false)]
		[string]$SecondParameter
	)
	$PlaformsString = ""
	Foreach ($platform in $Platforms) {
	    $PlaformsString += "&platform={0}" -f $platform
	}
	$EncodedNxqlQuery = [System.Web.HttpUtility]::UrlEncode($Query)
	$Url = "https://{0}:{1}/2/query?query={2}&format={3}{4}" -f $ServerName,$PortNumber,$EncodedNxqlQuery,$OuputFormat,$PlaformsString
	if ($FirstParameter) { 
		$EncodedFirstParameter = [System.Web.HttpUtility]::UrlEncode($FirstParameter)
		$Url = "{0}&p1={1}" -f $Url,$EncodedFirstParameter
	}
	if ($SecondParameter) { 
		$EncodedSecondParameter = [System.Web.HttpUtility]::UrlEncode($SecondParameter)
		$Url = "{0}&p2={1}" -f $Url,$EncodedSecondParameter
	}
	echo $Url
	try
    {
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12 -bor [System.Net.SecurityProtocolType]::Tls11
	    [Net.ServicePointManager]::ServerCertificateValidationCallback = {$true} 
	    $webclient = New-Object system.net.webclient
	    $webclient.Credentials = New-Object System.Net.NetworkCredential($UserName, $UserPassword)
        $webclient.DownloadString($Url)
    }
    catch
    {
        Write-Host $Error[0].Exception.Message
    }
}; Set-Alias inxql Invoke-Nxql  

