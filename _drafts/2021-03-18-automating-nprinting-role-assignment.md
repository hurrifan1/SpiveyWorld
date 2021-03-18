---
layout: post
title: Automating nPrinting role assignment
category: Learning
tags: Scripting Qlik-nPrinting PowerShell Qlik-CLI
---
MAN I had some trouble with this one. Another day, another grievance with nPrinting -- this time, it was assigning roles to users brought in via the AD connection. If you've ever had to contend with this before, you already know my pain: the Web Console gives you no easy way to assign roles in bulk -- you have to do it one at a time 😩. Unless...

**Fuck it, just gonna script it.**

It was pretty easy, too.

Okay, let's say we have a group of users in the **AgencyDevs** group to whom we want to assign the **On-Demand Reports** role. Here's the process for how we can do this programmatically:

## 1. Authenticate

```powershell
# Global
$root = "https://nprintdev:4993/api/v1"
$WebSession = New-Object Microsoft.PowerShell.Commands.WebRequestSession

# Authenticate
$uri = "$root/login/ntlm"

$token = Invoke-RestMethod -Uri $uri -WebSession $WebSession -UseDefaultCredentials
$cookies = $WebSession.Cookies.GetCookies($uri)
$xsrf_token = $($cookies | Where-Object {$_.Name -eq "NPWEBCONSOLE_XSRF-TOKEN"}).Value
```

When I wrote this script, I authenticated from a machine that was on the same network as the nPrinting server and was logged into the machine as the same domain user that I use for nPrinting, wherein I'm an admin, all of which made authenticating pretty seamless. The only tricky part was figuring out that I needed to get the token from the XSRF cookie for API calls.

## 2. API call function

```powershell
# function for subsequent calls
function Call-nPrint {
    
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Uri,
        [string]$Method = "GET",
        [string]$Body
    )

    [System.Uri]$uri = "$root/$Uri"

    $props = @{
    Uri = $uri.AbsoluteUri
    WebSession = $WebSession
    UseDefaultCredentials = $true
    Method = $Method
    }

    # $props = $propsDefault

    if ( $Method -eq "PUT" ) {
        $Headers = @{ "X-XSRF-TOKEN" = $xsrf_token }
        $props.Add("Headers", $Headers)
        $props.Add("ContentType", "application/json")
        $props.Add("Body", $Body)
    }

    $res = Invoke-RestMethod @props
    $res.data
}
```

This function is what I'll use to make the API calls to the nPrinting API. It defaults to using a `GET` method but has extra logic for when a `PUT` method is used for updating the user roles.

## 3. Find the ID for the **On-Demand Reports** role:

```powershell
# Get list of roles
$roles = Call-nPrint "roles"

# Select the "On-Demand Reports" roles
$roleID = $roles.items | ? {$_.name -Like "*demand*"} | select -ExpandProperty id
```

The `$roles` variable is getting the list of all of the available roles in nPrinting.

We only want the ID of the **On-Demand Reports** role, so we use the `Where-Object` cmdlet (I use its question mark alias **?**) to do a wildcard search for the roles with the word "demand," and then get the ID for the role that's returned, which we then keep in the `$roleID` variable.

## 4. Find the ID for the **AgencyDevs** group:

```powershell
# Get list of groups
$groups = Call-nPrint "groups"
$grpID = $groups.items[0].id
```

Here, the `$groups` variable will get the list of groups that we'll search in for "AgencyDevs."

When I wrote this script, there was only one group in nPrinting at that time, so I just needed to grab the first (and only) ID there using the `[0]` accessor to grab the first element of the groups array (arrays in PowerShell are zero-based indexed, meaning the first item in an array is `0`, the second item is `1`, etc.). The ID for **AgencyDevs** is then held in the `$grpID` variable.

## 5. Get the users in the **AgencyDevs** group:

```powershell
# Get users for that group
$users = Call-nPrint "groups/$grpID/users"
$user_list = $users.items
```

Now that we have our list of **AgencyDevs** users in the `$user_list` variable, we have everything we need to assign the new roles to these users.

## 6. Loop through the **AgencyDevs** users and assign each one the **On-Demand Reports** role:

```powershell
# Loop through users, assigning "On-Demand role"
foreach ($user in $user_list) {

    # Get list of current roles
    $usr_roles = Call-nPrint "users/$user/roles"

    # Add new role to that list
    $new_roles = $usr_roles.items += $roleID
    $new_roles = $new_roles | Get-Unique

    # Assign the updated roles list
    $body_text = $new_roles -join """, """
    $body = "[""$body_text""]"
    Call-nPrint "users/$user/roles" -Method "PUT" -Body $body
}
```

This will loop through each user in the **AgencyDevs** group, for each one:

- Get the current roles assigned to the user (as `$usr_roles` variable);
- Create a new array with the user's current roles but add in the ID for the **On-Demand Reports** role (as `$new_roles` variable);
- Make sure the new array of user's roles is unique, in case we are assigning the **On-Demand Reports** role to a user who already had it (using the `Get-Unique` cmdlet);
- Form the body of the `PUT` call we'll make to nPrinting to update the user's roles (using the `-join` operator and string interpolation to create the JSON format required).

## Takeaways

And there we go! We've successfully updated the users in the **AgencyDevs** group to be assigned with the **On-Demand Reports** role. Pretty easy stuff! This script could be easily adapted to be even more dynamic by making it so that a user could pass **Group** and **Role** parameters to the script for extremely fast role assignment.
