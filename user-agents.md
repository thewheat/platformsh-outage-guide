# User agents

- With LLMs / AI agents or just DDoS there can be an influx of traffic from particular browser user agents
- Large influx of old user agents could be indicative of an issue
- To block by user agents refer to [`blocking-traffic.md`](./blocking-traffic.md)

## Parse User Agent string
- https://explore.whatismybrowser.com/useragents/parse/

## User agent version history
- [Chrome stable versions](https://chromereleases.googleblog.com/search/label/Stable%20updates)
- [Edge](https://learn.microsoft.com/en-us/deployedge/microsoft-edge-release-schedule)
- [Firefox](https://www.mozilla.org/en-US/firefox/releases/)
- [Safari](https://developer.apple.com/documentation/safari-release-notes)

## Latest User Agent By Browser
- [Chrome](https://www.whatismybrowser.com/guides/the-latest-user-agent/chrome)
- [Edge](https://www.whatismybrowser.com/guides/the-latest-user-agent/edge)
- [Firefox](https://www.whatismybrowser.com/guides/the-latest-user-agent/firefox)
- [Safari](https://www.whatismybrowser.com/guides/the-latest-user-agent/safari)

## Latest User Agent By Operating System
   - [Android](https://www.whatismybrowser.com/guides/the-latest-user-agent/android)
   - [ChromeOS](https://www.whatismybrowser.com/guides/the-latest-user-agent/chrome-os)
   - [iOS](https://www.whatismybrowser.com/guides/the-latest-user-agent/ios)
   - [macOS](https://www.whatismybrowser.com/guides/the-latest-user-agent/macos)
   - [Windows](https://www.whatismybrowser.com/guides/the-latest-user-agent/windows)


## Check user agent traffic trend


### [Grid] - User agents daily requests in the past 10 days 
```
cat access.log | grep -ia "$USER_AGENT_STRING" | awk '{print $4}' | cut -c1-12 | uniq -c | tail
```

### [DG2] - User agents daily requests in the past 10 days 
```
cat access.log | grep -ia "$USER_AGENT_STRING"  | wc -l
for i in {1..10};do zcat access.log.$i.gz | grep -ia "$USER_AGENT_STRING"  | wc -l;done
```
- Note that log rotation does not happen exactly at 00:00 UTC but usually happens just just after
- This typically means that each `access.log.*.gz` file will contain 2 date values - the main day itself and a short while before log rotation happens
- Thus the output below will typically contain 2 lines for each previous day. The smaller count cant typically be ignored as it would be only for a couple of minutes before log rotation happens
