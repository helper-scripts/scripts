param (
    [Parameter(Mandatory)][string]$URL,
    [Parameter(Mandatory)][string]$PAT,
    [Parameter(Mandatory)][string]$POOL
)

# $URL = 'https://dev.azure.com/allymeer-hossen/'
# $PAT = 'pizo3qutl3xon7rppur7kxuuj6kbfin5fc7cxhu6exhdailn6hwq'
# $POOL = 'test'
$AGENT = Hostname

#test if an old installation exists, if so, delete the folder
if (test-path "c:\agent")
{
    Remove-Item -Path "c:\agent" -Force -Confirm:$false -Recurse
}

#create a new folder
new-item -ItemType Directory -Force -Path "c:\agent"
set-location "c:\agent"

$env:VSTS_AGENT_HTTPTRACE = $true

#github requires tls 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

#get the latest build agent version
$wr = Invoke-WebRequest https://api.github.com/repos/Microsoft/azure-pipelines-agent/releases/latest -UseBasicParsing
$tag = ($wr | ConvertFrom-Json)[0].tag_name
$tag = $tag.Substring(1)

#write-host "$tag is the latest version"
#build the url
$download = "https://vstsagentpackage.azureedge.net/agent/$tag/vsts-agent-win-x64-$tag.zip"
#download the agent
Invoke-WebRequest $download -Out vsts-agent.zip

#expand the zip
Expand-Archive -Path vsts-agent.zip -DestinationPath $PWD

#run the config script of the build agent
.\config.cmd --unattended --url "$URL" --auth pat --token "$PAT" --pool "$POOL" --agent "$AGENT" --acceptTeeEula --runAsService

#exit
Stop-Transcript
exit 0