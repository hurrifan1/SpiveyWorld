---
layout: post
title: Learning PowerShell by using Qlik CLI
category: Learning
tags: Scripting Qlik-Sense PowerShell Qlik-SaaS
---
The more I use Qlik Sense, the more I realize that the real power of it comes from the use of its APIs under the hood. While the QMC is a powerful admin console, the ability to write programs using the Qlik Sense API can push the boundaries of what's possible with Qlik. I recently had a project where I needed to save all of the apps and data connections in a client's environment so that we could un- and then re-install Qlik to complete a network update. Turns out that a great way to accomplish this with the Qlik APIs is to script it out using the Qlik CLI tool in PowerShell.

This post will look at using the script to accomplish various tasks and ultimately automate certain tasks in the Qlik SaaS emvironment.

## Connect and view content
The first thing I'll look at is connecting to the tenant and pulling some basic info about the environment and the apps therein.

Here's the script we can use to check the status of our connection to the SaaS tenant:
```powershell
PS> qlik status
```

We get a result indicating which tenant we've successfully connected to:
```powershell
Connected without app to  https://ccg.us.qlikcloud.com/api/
```

Now, we'll get a list of the spaces in our tenant. If you're not yet familiar with the concept of spaces in Qlik SaaS, just think of them as the loose equivalent of streams. 
```powershell
PS> qlik space ls
```

Our result is a JSON object with some information about the space(s) in the tenant. As you can see, this returns the one space that I have, called Sandbox:
```json
[
  {
    "createdAt": "2020-05-21T17:48:48.575Z",
    "createdBy": "xHBiYWxYDYdEh5vprEts5wXNWkLc9wQL",
    "description": "",
    "id": "5ec6bf00bb2feb0001b803ae",
    "meta": {
      "actions": [
        "read",
        "create",
        "update",
        "delete"
      ],
      "assignableRoles": [
        "consumer",
        "facilitator",
        "producer"
      ],
      "roles": []
    },
    "name": "Sandbox",
    "ownerId": "xHBiYWxYDYdEh5vprEts5wXNWkLc9wQL",
    "tenantId": "FWhiuULapeVa1PbDYp19hAMY5sRYlRtV",
    "type": "shared",
    "updatedAt": "2020-05-21T17:48:48.575Z"
  }
]
```

Note that this will only return the spaces that the current user is allowed to see. Remember that I, the current user in this case, am identified by Qlik by the API key I used with the `qlik context init` command.

Now this is great that we have this info, but what if I need to use this as a PowerShell object and use specific property values? What I'll do is parse the JSON:

Script:
```powershell
PS> qlik space ls | ConvertFrom-Json
```

Our result :
```powershell
createdAt   : 5/21/2020 5:48:48 PM
createdBy   : xHBiYWxYDYdEh5vprEts5wXNWkLc9wQL
description : 
id          : 5ec6bf00bb2feb0001b803ae
meta        : @{actions=System.Object[]; assignableRoles=System.Object[]; 
              roles=System.Object[]}
name        : Sandbox
ownerId     : xHBiYWxYDYdEh5vprEts5wXNWkLc9wQL
tenantId    : FWhiuULapeVa1PbDYp19hAMY5sRYlRtV
type        : shared
updatedAt   : 5/21/2020 5:48:48 PM
```

Now we may want to investigate the meta information for this space. We'll format the result as a hashtable and then expand the meta property:
```powershell
PS> qlik space ls `
    | ConvertFrom-Json -AsHashtable `
    | Select-Object -ExpandProperty meta
```

Now we're able to see what's going on under the hood for the meta property:
```powershell
Name                           Value
----                           -----
assignableRoles                {consumer, facilitator, producer}
roles                          {}
actions                        {read, create, update, delete}
```

This would allow us to filter to the spaces where I have specific roles or CRUD permissions -- this particular case isn't a great example because I only have one space, but I could nevertheless use this script chunk here to narrow in on a set of spaces:
```powershell
qlik space ls `
    | ConvertFrom-Json -AsHashtable `
    | Select-Object -ExpandProperty meta `
    | Where-Object { $_.actions -Contains "create" -and $_.assignableRoles -contains "facilitator" }
```

This would give me the same result as above, so let's shift to investigating apps within this space.

We'll first look at all the apps in our tenant:
Script:
```powershell
PS> qlik app ls
```

Result:
```powershell
ID                                       NAME
92d138ad-bbd6-4a56-a4c0-56dcfd1eec9b     TD Test
c8ff2e05-b776-4d82-8dad-1557feff36e9     Copy - TD Test
fbe935c0-a25c-4ca3-96ee-28a46e7a7b11     App example
140e4026-7a54-429d-bcdf-de0b12527b6c     City of Chicago Crime Incidents(1)
363a6102-06d4-4dda-9a06-3e1e0505752b     CloudSuite Industrial QC Dashboard
f6bce78e-7317-45fa-beb5-d61756d100cb     FL DFS-OIR
eb6d1153-5b51-4839-b50d-8394cc1d6083     CSI Sales Management
70017745-0b30-4754-b4b6-70da06157c9f     CloudSuite Industrial Financial Dashboard
701fe706-48f4-4ae6-9e8a-b8e016ca8bdd     Base64
db92c8c2-803e-46b8-b23c-803b262d07f5     Copy - RV Sales
b9bf8d51-2f33-4c06-97b0-50b7cc8fcb09     RV Sales
225fe796-1a86-4637-b886-6deb563d7a22     2020_0915 1351 COPY - Sea Turtle Data
95cd99b6-da8b-4e7f-8a49-9a0f8b301592     Validation scripts
71e6a105-9a80-4dc0-adeb-b26735f4fc16     Mass Corrections
3563d3c8-5610-4d01-8fea-4bbe79dd7cff     JC Timesheet
17d07b85-329b-464e-90f3-b55f02e4a093     Copy - Industrial Commission of Arizona
791ea0d4-fa76-4841-ae29-d3ab669e6bcb     Copy - Industrial Commission of Arizona
f0f6d922-211c-4124-bf6f-2b28ad668b3b     MA DFML
2358a920-e03a-4a69-8d8d-1dc63cc603b2     meck
cb7361cf-1011-4ac4-9b95-c5d5300dee6c     Test out modal
68c49f80-008a-44f6-8682-bc960ab8a5e7     Industrial Commission of Arizona
686822f5-b2e7-44b1-83b0-a55061d37eb6     Children Service's Council
1c7928e8-1c91-4fef-8ebb-0181b1c3fc23     Section Access demo
ce070e6b-c540-4587-bf18-e2ebcb70a79a     Florida Appropriations mashup app
1e26c069-fea3-4b03-99de-450caf403da0     Copy - Florida Appropriations
9407bc39-9f2e-4086-ba5f-7a5a4ea0a5af     Copy - Demo app spivey (with dummy data and dates)
6e461a6b-fe4b-4701-8145-6522aa68ed38     Demo app spivey (with dummy data and dates)
7ad88c10-4407-4787-a7a6-16d553af7bf3     __Top 10 Viz Tips QlikWorld 2020
878c7f89-f2bf-492c-9cb3-5b889e4b5d6d     always testing
7ed30cec-e492-49c9-b42e-6a5e496f2d5e     Missing Date App
```

This is a fine list (damn fine!) but we need, like, *way* more info. Let's use a different command:
```powershell
qlik item ls
```

This gives us a TON of info, way more than we really need. Here's a preview, showing the last JSON item returned when I ran this:
```json
[
  {
    "name": "weather app",
    "ownerId": "xHBiYWxYDYdEh5vprEts5wXNWkLc9wQL",
    "resourceAttributes": {
      "_resourcetype": "app",
      "createdDate": "2020-06-25T21:46:37.725Z",
      "description": "",
      "dynamicColor": "",
      "hasSectionAccess": false,
      "id": "2273a265-9c42-4fde-9976-a67dfd646618",
      "lastReloadTime": "",
      "modifiedDate": "2020-06-25T21:46:44.670Z",
      "name": "weather app",
      "originAppId": "",
      "owner": "auth0|555de13f-517a-4462-a105-4f0ad46d5fd8",
      "ownerId": "xHBiYWxYDYdEh5vprEts5wXNWkLc9wQL",
      "publishTime": "",
      "published": false,
      "spaceId": "",
      "thumbnail": ""
    },
    "resourceCreatedAt": "2020-06-25T21:46:37Z",
    "resourceCustomAttributes": null,
    "resourceId": "2273a265-9c42-4fde-9976-a67dfd646618",
    "resourceReloadEndTime": "",
    "resourceReloadStatus": "",
    "resourceSubType": "",
    "resourceType": "app",
    "resourceUpdatedAt": "2020-06-25T21:46:44Z",
    "tenantId": "FWhiuULapeVa1PbDYp19hAMY5sRYlRtV",
    "updatedAt": "2020-06-25T21:46:44Z",
    "updaterId": "xHBiYWxYDYdEh5vprEts5wXNWkLc9wQL"
  }
]
```

We can make this more useable, as well as more focused, like so:
```powershell
qlik item ls --limit 99 `
    | ConvertFrom-Json `
    | Select-Object name, resourceID, updatedAt `
    | Format-Table
```

This will give us a nice table with just a few key properties...here's a sample of what came back from my environment:
```powershell
name                                               resourceId                           updatedAt
----                                               ----------                           ---------
Sample data app                                    1f804e54-7ef8-44d8-a2ea-1ccec2372de3 5/6/2020 6:51:34 PM
Sandbox1                                           ceceb622-4de8-43df-863b-71bb087a5f60 7/14/2020 1:31:22 PM
Section Access demo                                1c7928e8-1c91-4fef-8ebb-0181b1c3fc23 8/27/2020 2:19:05 PM
App example                                        fbe935c0-a25c-4ca3-96ee-28a46e7a7b11 10/14/2020 1:35:11 AM
Base64                                             701fe706-48f4-4ae6-9e8a-b8e016ca8bdd 10/7/2020 11:03:22 PM
Mass Corrections                                   71e6a105-9a80-4dc0-adeb-b26735f4fc16 10/1/2020 2:25:59 PM
Validation scripts                                 95cd99b6-da8b-4e7f-8a49-9a0f8b301592 10/1/2020 6:02:14 PM
RV Sales                                           b9bf8d51-2f33-4c06-97b0-50b7cc8fcb09 10/6/2020 1:01:42 AM
City of Chicago Crime Incidents(1)                 140e4026-7a54-429d-bcdf-de0b12527b6c 10/9/2020 3:09:40 PM
Copy - TD Test                                     c8ff2e05-b776-4d82-8dad-1557feff36e9 10/20/2020 8:05:41 PM
```

Now hold on...which of these apps are mine? I see an ownerId but I have no idea what my ID is. Let's look that up:
```powershell
$myID = qlik user me | ConvertFrom-Json | Select-Object -ExpandProperty id
```

With that, I can now filter to only my apps:
```powershell
qlik item ls `
    | ConvertFrom-Json `
    | Select-Object name, resourceID, updatedAt, ownerId, resourceType `
    | Where-Object ownerId -eq $myID `
    | Format-Table
```

Here's my result:
```powershell

name          resourceId                           updatedAt             ownerId                          resourceType
----          ----------                           ---------             -------                          ------------
Sandbox1      ceceb622-4de8-43df-863b-71bb087a5f60 7/14/2020 1:31:22 PM  xHBiYWxYDYdEh5vprEts5wXNWkLc9wQL app
D-PLACE app 1 356a3015-eb01-49f7-b94a-2a028ee255c8 5/23/2020 12:23:30 AM xHBiYWxYDYdEh5vprEts5wXNWkLc9wQL app
New apps      6003f260-ea84-435d-8afa-99ed04a14ead 6/25/2020 4:23:56 PM  xHBiYWxYDYdEh5vprEts5wXNWkLc9wQL app
weather app   2273a265-9c42-4fde-9976-a67dfd646618 6/25/2020 9:46:44 PM  xHBiYWxYDYdEh5vprEts5wXNWkLc9wQL app
```




# NOTE TO SELF:
Go along with:
- importing the Chicago crime app or some other app
- investigating some of the data
- setting a reload schedule





Now, I want to go back and investigate the app called City of Chicago Crime Incidents(1):
```powershell
qlik app get 140e4026-7a54-429d-bcdf-de0b12527b6c `
    | ConvertFrom-Json -AsHashtable `
    | Select-Object -ExpandProperty attributes
```

This script gives us some metadata information as shown here:
```powershell
Name                           Value
----                           -----
ownerId                        DFE7j7ZuBPLTpoMmgCTeW_DJXS-xJMZP
lastReloadTime                 10/8/2020 3:54:40 AM
hasSectionAccess               False
modifiedDate                   10/9/2020 3:09:35 PM
publishTime                    
encrypted                      True
id                             140e4026-7a54-429d-bcdf-de0b12527b6c
originAppId                    
owner                          auth0|a08D000001L9qdIIAR
custom                         {}
name                           City of Chicago Crime Incidents(1)
description                    
createdDate                    10/9/2020 3:09:35 PM
published                      False
thumbnail                      
dynamicColor                   
_resourcetype                  app
```

Note that this app was not one that I own. What if I were in a scenario where the developer who created this app forgot to publish some important sheets and is now on vacation. I need those sheets to be published for this demo tomorrow! First, let's confirm that the app's sheets are indeed unpublished:
```powershell

```


