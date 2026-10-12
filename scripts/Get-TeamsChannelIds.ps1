[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$ChannelLink
)

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($ChannelLink)) {
    $ChannelLink = Read-Host 'Cole o link do canal do Microsoft Teams'
}

$urlMatch = [regex]::Match(
    $ChannelLink,
    'https://teams\.microsoft\.com/[^\s\]\)]+' ,
    [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
)

if (-not $urlMatch.Success) {
    throw 'Nenhuma URL válida do Microsoft Teams foi encontrada.'
}

# Accept raw URLs and links copied from Markdown-aware tools, where \& can
# appear before query-string parameters.
$normalizedLink = $urlMatch.Value.Trim().Replace('\&', '&')

try {
    $uri = [Uri]$normalizedLink
}
catch {
    throw "O link encontrado não é uma URI válida: $normalizedLink"
}

$segments = $uri.AbsolutePath.Trim('/') -split '/'
$channelMarkerIndex = -1

for ($index = 0; $index -lt $segments.Count; $index++) {
    if ($segments[$index] -in @('channel', 'team')) {
        $channelMarkerIndex = $index
        break
    }
}

if ($channelMarkerIndex -lt 0 -or ($channelMarkerIndex + 1) -ge $segments.Count) {
    throw 'Não foi possível localizar o Channel ID no caminho do link.'
}

$channelId = [Uri]::UnescapeDataString($segments[$channelMarkerIndex + 1])

$queryValues = @{}
foreach ($queryPair in ($uri.Query.TrimStart('?') -split '&')) {
    if ([string]::IsNullOrWhiteSpace($queryPair)) {
        continue
    }

    $parts = $queryPair -split '=', 2
    if ($parts.Count -eq 2) {
        $name = [Uri]::UnescapeDataString($parts[0])
        $value = [Uri]::UnescapeDataString($parts[1])
        $queryValues[$name] = $value
    }
}

$teamId = $queryValues['groupId']

if ([string]::IsNullOrWhiteSpace($teamId)) {
    throw 'Não foi possível localizar o Team ID no parâmetro groupId.'
}

if ([string]::IsNullOrWhiteSpace($channelId)) {
    throw 'O Channel ID extraído está vazio.'
}

Write-Host ''
Write-Host 'Valores para o ARM Template:' -ForegroundColor Cyan
Write-Host "Team ID:    $teamId" -ForegroundColor Green
Write-Host "Channel ID: $channelId" -ForegroundColor Green

[PSCustomObject]@{
    TeamId    = $teamId
    ChannelId = $channelId
}
