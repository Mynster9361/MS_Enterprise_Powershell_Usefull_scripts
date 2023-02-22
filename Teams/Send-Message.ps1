param (
    $PublicAPIs = "https://api.publicapis.org/entries", # Public APIs URL just as an example
    $Teams_Connection_URI = "", # Insert your teams incomming webhook URI
    $color1 = 253,
    $color2 = 132,
    $color3 = 7
)

# Get the Public APIs
$PublicAPIs = Invoke-RestMethod -Uri $PublicAPIs -Method GET
# Select a random entri
$PublicAPIs = $PublicAPIs.entries | Select-Object -Index (Get-Random -Maximum $PublicAPIs.count)

$TeamsMessage = @"
<span style='color: rgb($color1,$color2,$color3); font-size: 20px'><strong> API:  </strong></span><br />
$($PublicAPIs.Description)<br />

<span style='color: rgb($color1,$color2,$color3); font-size: 15px'><strong> Description: </strong></span><br />
$($PublicAPIs.Description)<br />

<span style='color: rgb($color1,$color2,$color3); font-size: 15px'><strong> Auth: </strong></span><br />
$($PublicAPIs.Auth)<br />

<span style='color: rgb($color1,$color2,$color3); font-size: 15px'><strong> HTTPS: </strong></span><br />
$($PublicAPIs.HTTPS)<br />

<span style='color: rgb($color1,$color2,$color3); font-size: 15px'><strong> Cors: </strong></span><br />
$($PublicAPIs.Cors)<br />

<span style='color: rgb($color1,$color2,$color3); font-size: 15px'><strong> Link: </strong></span><br />
$($PublicAPIs.Link)<br />

<span style='color: rgb($color1,$color2,$color3); font-size: 15px'><strong> Category: </strong></span><br />
$($PublicAPIs.Category)<br />
"@

$JSONBody = [PSCustomObject][Ordered]@{
    "@type" = "MessageCard"
    "@context" = "<http://schema.org/extensions>"
    "summary" = "$mad"
    "themeColor" = '0078D7'
    "title" = ""
    "text" = "$mad"
}
$TeamMessageBody = ConvertTo-Json $JSONBody
Invoke-RestMethod -Uri $Teams_Connection_URI -Method Post -Body ([System.Text.Encoding]::UTF8.GetBytes($TeamMessageBody)) -ContentType 'application/json'