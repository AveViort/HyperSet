

# parsedate — Parse dates from ISO 8601, and guess the format

[![Linux Build Status](https://travis-ci.org/gaborcsardi/parsedate.svg?branch=master)](https://travis-ci.org/gaborcsardi/parsedate)
[![Windows build status](https://ci.appveyor.com/api/projects/status/github/gaborcsardi/parsedate?svg=true)](https://ci.appveyor.com/project/gaborcsardi/parsedate)
[![](http://www.r-pkg.org/badges/version/parsedate)](http://www.r-pkg.org/pkg/parsedate)
[![CRAN RStudio mirror downloads](http://cranlogs.r-pkg.org/badges/parsedate)](https://r-pkg.org/pkg/parsedate)
[![Coverage Status](https://img.shields.io/codecov/c/github/gaborcsardi/parsedate/master.svg)](https://codecov.io/github/gaborcsardi/parsedate?branch=master)

This R package has three functions for dealing with dates.

 * `parse_iso_8601` recognizes and parses all valid ISO
   8601 date and time formats. It can also be used as an ISO 8601
   validator.
 * `parse_date` can parse a date when you don't know
   which format it is in. First it tries all ISO 8601 formats.
   Then it tries git's versatile date parser. Lastly, it tries
   `as.POSIXct`.
 * `format_iso_8601` formats a date (and time) in
   specific ISO 8601 format.

## Parsing ISO 8601 dates

`parse_iso_8601` recognizes all valid ISO 8601 formats, and
gives an `NA` for invalid dates. Here are some examples

### Dates with missing fields


```r
library(parsedate)
```

```
## Loading required package: methods
```

```r
parse_iso_8601("2013-02-08 09")
```

```
## [1] "2013-02-08 09:00:00 UTC"
```

```r
parse_iso_8601("2013-02-08 09:30")
```

```
## [1] "2013-02-08 09:30:00 UTC"
```

### Separator between date and time


```r
parse_iso_8601("2013-02-08T09")
```

```
## [1] "2013-02-08 09:00:00 UTC"
```

```r
parse_iso_8601("2013-02-08T09:30")
```

```
## [1] "2013-02-08 09:30:00 UTC"
```

```r
parse_iso_8601("2013-02-08T09:30:26")
```

```
## [1] "2013-02-08 09:30:26 UTC"
```

### Fractional seconds, minutes, hours


```r
parse_iso_8601("2013-02-08T09:30:26.123")
```

```
## [1] "2013-02-08 09:30:26 UTC"
```

```r
parse_iso_8601("2013-02-08T09:30.5")
```

```
## [1] "2013-02-08 09:30:30 UTC"
```

```r
parse_iso_8601("2013-02-08T09,25")
```

```
## [1] "2013-02-08 09:15:00 UTC"
```

### Zulu time zone is UTC


```r
parse_iso_8601("2013-02-08T09:30:26Z")
```

```
## [1] "2013-02-08 09:30:26 UTC"
```

### ISO weeks are parsed properly


```r
parse_iso_8601("2013-W06-5")
```

```
## [1] "2013-02-08 UTC"
```

```r
parse_iso_8601("2013-W01-1")
```

```
## [1] "2012-12-31 UTC"
```

```r
parse_iso_8601("2009-W01-1")
```

```
## [1] "2008-12-29 UTC"
```

```r
parse_iso_8601("2009-W53-7")
```

```
## [1] "2010-01-03 UTC"
```

### Day of the year


```r
parse_iso_8601("2013-039")
```

```
## [1] "2013-02-08 UTC"
```

```r
parse_iso_8601("2013-039 09:30:26Z")
```

```
## [1] "2013-02-08 09:30:26 UTC"
```

## Guess the format of the date, and parse it

Sometimes one has to work with a large number of dates, in arbitrary
formats. It is of impossible to reliably guess the format of some
dates, because of ambiguity. But it is often not critical to get the
date exactly right in the ambiguous cases, and this is when the
`parse_date` function is useful. It tries a large number of formats,
here is the algorithm is uses:

 1. Try parsing dates using all valid ISO 8601 formats, by
    calling `parse_iso_8601`.
 2. If this fails, then try parsing them using the git
    date parser.
 3. If this fails, then try parsing them using `as.POSIXct`.
    (It is unlikely that this step will parse any dates that the
    first two steps couldn't, but it is still a logical fallback,
    to make sure that we can parse at least as many dates as
    `as.POSIXct`.

Here are some examples. The first ones are easy.


```r
parse_date("2014-12-12")
```

```
## [1] "2014-12-12 GMT"
```

```r
parse_date("04/15/99")
```

```
## [1] "1999-04-15 01:00:00 BST"
```

```r
parse_date("15/04/99")
```

```
## [1] "1999-04-15 01:00:00 BST"
```

### Ambiguous formats

The following formats are ambiguous and are parsed as _month/day/year_.


```r
parse_date("12/11/99")
```

```
## [1] "1999-12-11 GMT"
```

```r
parse_date("11/12/99")
```

```
## [1] "1999-11-12 GMT"
```

### Fill in the current date and time for missing fields


```r
parse_date("03/20")
```

```
## [1] "2017-03-20 GMT"
```

```r
parse_date("12")
```

```
## [1] "2017-03-12 GMT"
```

But not for this, because this is ISO 8601.


```r
parse_date("2014")
```

```
## [1] "2014-01-01 GMT"
```

## Formatting dates as ISO 8601

The `format_iso_8601` function formats a date (and time) in a fixed format
that is ISO 8601 valid, and can be used to compare dates as character
strings. It converts the date(s) to UTC.


```r
format_iso_8601(parse_iso_8601("2013-02-08"))
```

```
## [1] "2013-02-08T00:00:00+00:00"
```

```r
format_iso_8601(parse_iso_8601("2013-02-08 09:34:00"))
```

```
## [1] "2013-02-08T09:34:00+00:00"
```

```r
format_iso_8601(parse_iso_8601("2013-02-08 09:34:00+01:00"))
```

```
## [1] "2013-02-08T08:34:00+00:00"
```

```r
format_iso_8601(parse_iso_8601("2013-W06-5"))
```

```
## [1] "2013-02-08T00:00:00+00:00"
```

```r
format_iso_8601(parse_iso_8601("2013-039"))
```

```
## [1] "2013-02-08T00:00:00+00:00"
```
