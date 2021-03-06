# Copyright (c) 2016 Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT License (MIT)

function New-RsWebServiceProxy
{
    <#
        .SYNOPSIS
            This script creates a web service proxy object to the Reporting Services SOAP endpoint.
        
        .DESCRIPTION
            This script creates a web service proxy object to the Reporting Services SOAP endpoint associated to the Report Server URI specified by the user.
    
            By default, this function uses the connection values set by Connect-RsReportingServer.
            The defaults without ever calling Connect-RsReportingServer are:
            - ReportServerUri: http://localhost/reportserver/
            - Credential: Current User
        
        .PARAMETER ReportServerUri
            Specify the Report Server URL to your SQL Server Reporting Services Instance.
            By Default, this parameter uses the uri specified by the Connect-RsReportingServer function.
        
        .PARAMETER Credential
            Specify the Credential to use when connecting to your SQL Server Reporting Services Instance.
            By Default, this parameter uses the credentials (if any) specified by the Connect-RsReportingServer function.
        
        .EXAMPLE
            New-RsWebServiceProxy
            Description
            -----------
            This command will create and return a web service proxy to the default server using default credentials.
        
        .EXAMPLE
            New-RsWebServiceProxy -ReportServerUri http://myserver/reportserver_sql2012
            Description
            -----------
            This command will create and return a web service proxy to the Report Server located at http://myserver/reportserver_sql2012 using current user's credentials.
        
        .EXAMPLE
            New-RsWebServiceProxy -Credential 'CaptainAwesome'
            Description
            -----------
            This command will create and return a web service proxy to the Report Server located at http://localhost/reportserver using CaptainAwesome's credentials.
    #>

    [cmdletbinding()]
    param
    (
        [string]
        $ReportServerUri = ([Microsoft.ReportingServicesTools.ConnectionHost]::ReportServerUri),
        
        [Alias('Credentials')]
        [AllowNull()]
        [System.Management.Automation.PSCredential]
        $Credential = ([Microsoft.ReportingServicesTools.ConnectionHost]::Credential)
    )
    
    #region If we did not specify a connection parameter, use a default connection
    if (-not ($PSBoundParameters.ContainsKey("ReportServerUri") -or $PSBoundParameters.ContainsKey("Credential")))
    {
        if ([Microsoft.ReportingServicesTools.ConnectionHost]::Proxy)
        {
            return ([Microsoft.ReportingServicesTools.ConnectionHost]::Proxy)
        }
        else
        {
            try
            {
                $proxy = New-RsWebServiceProxy -ReportServerUri ([Microsoft.ReportingServicesTools.ConnectionHost]::ReportServerUri) -Credential ([Microsoft.ReportingServicesTools.ConnectionHost]::Credential) -ErrorAction Stop
                [Microsoft.ReportingServicesTools.ConnectionHost]::Proxy = $proxy
                return $proxy
            }
            catch
            {
                throw (New-Object System.Exception("Failed to establish proxy connection to $([Microsoft.ReportingServicesTools.ConnectionHost]::ReportServerUri) : $($_.Exception.Message)", $_.Exception))
            }
        }
    }
    #endregion If we did not specify a connection parameter, use a default connection

    #region Build explicitly required proxy object
    # forming the full URL to the SOAP Proxy of ReportServerUri 
    if ($ReportServerUri -notlike '*/') 
    {
        $ReportServerUri = $ReportServerUri + '/'
    }
    $reportServerUriObject = New-Object System.Uri($ReportServerUri)
    $soapEndpointUriObject = New-Object System.Uri($reportServerUriObject, 'ReportService2010.asmx')
    $ReportServerUri = $soapEndPointUriObject.ToString()
    
    # creating proxy either using specified credentials or default credentials
    try
    {
        if ($Credential)
        {
            New-WebServiceProxy -Uri $ReportServerUri -Credential $Credential -ErrorAction Stop
        }
        else
        {
            New-WebServiceProxy -Uri $ReportServerUri -UseDefaultCredential -ErrorAction Stop
        }
    }
    catch
    {
        throw (New-Object System.Exception("Failed to establish proxy connection to $ReportServerUri : $($_.Exception.Message)", $_.Exception))
    }
    #endregion Build explicitly required proxy object
}
