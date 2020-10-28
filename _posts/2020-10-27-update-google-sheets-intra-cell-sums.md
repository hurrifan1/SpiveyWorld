---
layout: post
title: Google Sheets intra-cell sums
category: Miscellaneous
tags: Scripting Google-Sheets
---
If this pandemic has done anything to me, it's made me want to travel a **lot** more than I ever have before. These past few months of restlessness culminated in a trip to Yosemite and Joshua Tree National Parks in California with a few friends, a repreive that allowed for a socially-distanced adventure and a pinch of serenity during a period of our lives that is anyting but.

Planning the trip required an indispensible tool for collaboratively creating our itinerary: Google Sheets, a trusty mainstay of I'm-not-fuckin-paying-for-Office-365 web tool aficionados.

## The Problem
While building out our itinerary in Google Sheets, I wanted to sum up the cost estimates for each leg of the journey (each leg occupied a row in the sheet), but I didn't want to break out each expense item on individual rows in a new sheet -- I just wanted to use a sum formula *within* a single cell, where I'd have all my expenses, like so:

![Screenshot of the problem cell](/assets/img/2020-10-27-update-google-sheets-intra-cell-sums-screenshot-1.png)

Turns out, you can't just use the `Sum()` formula to sum up numbers in a single cell. But after activating a few neglected ridges in my brain, I have a solution...

## The Solution
I ended up with a formula that can be tweaked to accomodate finding numbers in your cell after stripping out characters that match a particular pattern:

![Screenshot of the problem cell](/assets/img/2020-10-27-update-google-sheets-intra-cell-sums-screenshot-2.png)

Here's the formula written out:
```
=ArrayFormula(Sum(Split(RegexReplace(A1, "[^,0-9]+", ""), ",")))
```

And here's the forumla broken out:

```
=ArrayFormula(                                                          )
               Sum(                                                   )
                    Split(                                    , "," )
                           RegexReplace( A1, "[^,0-9]+", "" )
```

Here's an explainer for each function and a link to the docs:
- `ArrayFormula()`
  - This function is being used to here because we need to use the `Sum()` function over the array of numbers that result from the use of the `Split()` function, described below.
  - [Docs](https://support.google.com/docs/answer/3093275?hl=en)
- `Sum()`
  - This function will sum all of the numbers that we find in the cell after removing non-numbers that match a pattern we specify using the `RegexReplace()` function, described below.
  - [Docs](https://support.google.com/docs/answer/3093669?hl=en)
- `Split()`
  - This function will split the cell's numbers into an array, which would *normally* result in the numbers being split into new cells, but the `ArrayFormula()` function will allow us to use the `Sum()` function to get a **single result** rather than **multiple new cells**.
  - The function, as I wrote it, will split out the numbers wherever there is a comma.
  - [Docs](https://support.google.com/docs/answer/3094136?hl=en)
- `RegexReplace()`
  - This function uses [regular expressions](https://www.oreilly.com/library/view/introducing-regular-expressions/9781449338879/ch01.html) to narrow in on the non-numbers that we don't want/cannot sum up and then gets rid of them.
  - This function basically says "find any characters that aren't numbers or commas and replace them with nothing."
  - [Docs](https://support.google.com/docs/answer/3098245?hl=en)

So, using our example from above, this is what is happening:

Our original cell value:

|                    A1                    |
|:----------------------------------------:|
| ONE WAY: Jason ($140), Owen ($157) + BAG |

1. `REGEXREPLACE(A1, "[^,0-9]+", "")`
  - "Replace all the characters that aren't numbers or commas and replace them with nothing."
  - **What it changes:**

|                    A1                    |
|:----------------------------------------:|
| ~~ONE WAY: Jason ($~~140~~)~~,~~Owen ($~~157~~) + BAG~~  |

  - **Result:**

|    A1   |
|:-------:|
| 140,157 |

2. `Split( ... , ",")`
  - "Split the cell's numbers into a comma-separated array."
  - **Result:**

|  A1 |  A2 |
|:---:|:---:|
| 140 | 157 |

3. `ArrayFormula( Sum( ... ) )`
  - "Sum the cells in the array created by the `Split()` function."
  - **Result:**
  
|  A1 |
|:---:|
| 297 |

## Final Thoughts
Damn, I'm glad this worked.