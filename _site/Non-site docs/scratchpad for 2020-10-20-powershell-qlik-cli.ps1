# Connect to the https://ccg.us.qlikcloud.com/ tenant:
qlik context init

// Use my API key:
$TenantKey = Get-Item -Path Env:CGG_Qlik_KEY_OCT20

// 
qlik item ls --limit 99 | ConvertFrom-Json | Select-Object name

qlik item ls --help

qlik space ls | ConvertFrom-Json | Select-Object name

qlik status

qlik app --help

qlik app 

qlik space ls `
| ConvertFrom-Json -AsHashtable `
| Select-Object -ExpandProperty meta

qlik space ls `
| ConvertFrom-Json -AsHashtable `
| Select-Object -ExpandProperty meta `
| Select-Object -ExpandProperty actions `
| Where-Object 


qlik space ls `
| ConvertFrom-Json -AsHashtable `
| Select-Object -ExpandProperty meta `
| Where-Object { $_.actions -Contains "create" -and $_.assignableRoles -contains "facilitator" }

qlik item ls --limit 99 `
    | ConvertFrom-Json `
    | Select-Object name, resourceID, updatedAt `
    | Format-Table `
    | Out-String -Width 200 `
    | Set-Clipboard

qlik user count

qlik user ls --help

qlik user me | ConvertFrom-Json | Select-Object name, id

qlik item ls `
    | ConvertFrom-Json `
    | Select-Object name, resourceID, updatedAt, ownerId, resourceType `
    | Where-Object ownerId -eq $myID `
    | Format-Table `
    | Out-String -Width 200 `
    | Set-Clipboard


qlik app get ceceb622-4de8-43df-863b-71bb087a5f60 `
    | ConvertFrom-Json -AsHashtable `
    | Select-Object -ExpandProperty attributes

qlik app meta -a ceceb622-4de8-43df-863b-71bb087a5f60 `
    | Format-Table `
    | Out-String -Width 200 `
    | Set-Clipboard


qlik app get 140e4026-7a54-429d-bcdf-de0b12527b6c `
    | ConvertFrom-Json -AsHashtable `
    | Select-Object -ExpandProperty attributes

qlik app object ls -a 140e4026-7a54-429d-bcdf-de0b12527b6c --json `
    | ConvertFrom-Json `
    | Where-Object qType -eq "sheet"
    | Format-Table `
    | Out-String -Width 200 `
    | Set-Clipboard

qlik app get 140e4026-7a54-429d-bcdf-de0b12527b6c --raw