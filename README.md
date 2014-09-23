# MoNews

- A server script which scraps sources news every night at the same time and get the top N articles (tagesschau offers a homepage sorted rss, hackernews (best) is sorted, reddit is sorted, medium monthly things are rated)
- convert these top N articles as RSS feed for each source
- import this in your favorite rss reader

    TODO See notes in dayone...

## Installation

* Needs Ruby >= 2.0.0p353.
* Run `bundle install`
* Copy `config.yaml.example` to `config.yaml` and adjust it.

## Things left todo

* add setting to spec how often to refresh (e.g. only every 10 hours)
* check that the setting how often to pull in new data is obayed.


