
param( 
  [String[]]$filepaths,
  [String]$message="No description provided... ",
  [String]$repo="adobe/UST-Install-Scripts"
  )

  
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$token = $env:GITHUB_TOKEN

$releaseURL = "https://api.github.com/repos/$repo/releases?access_token=$token"

$ctag = (Invoke-RestMethod -Uri $releaseURL -Method 'Get')[0].tag_name
$prefix = $ctag.Substring(0,$ctag.LastIndexOf(".") + 1)
$version = [int] $ctag.Substring($ctag.LastIndexOf(".")+ 1) + 1

$body = '{' +
    '"tag_name": "' + $prefix + $version + '",' +
    '"target_commitish": "master",' +
    '"name": "' + $prefix + $version + '",' +
    '"body": "- ' + $message + '",' +
    '"draft": true,' +
    '"prerelease": false' +
'}'

$release = (Invoke-RestMethod -Uri $releaseURL -Method 'Post' -Body $body -Headers @{"Content-Type" = "application/json"})

foreach ($filepath in $filepaths) {

    $filepath = (Resolve-Path $filepath).path
    $filename = $filepath.Split("\")[-1]
    
    $uploadURL = "https://uploads.github.com/repos/$repo/releases/" + $release.id + "/assets?name=$filename&access_token=$token"
    Invoke-RestMethod -Uri $uploadURL -Method 'Post' -InFile $filepath -Headers @{"Content-Type" = "application/octet-stream"}

}



