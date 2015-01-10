# MoNews

## Idea
This server script scrapes news sources every night at the same time to get the top N articles. RSS feeds like tagesschau offer sorted rss (by importance). Also hackernews (best) is sorted, reddit is sorted and medium monthly things are rated by importance.
I take snapshots of these sources and put these top N articles as individual RSS feeds on S3.
This can then be used to import in your favorite RSS reader and have a curated news feed.

## Installation

* Needs Ruby >= 2.0.0p353.
* Run `bundle install`
* Copy `config.yaml.example` to `config.yaml` and adjust it.

## Run locally

Simply run `monews.rb` and the result will show up in rss. Or, use `s3_wrapper.sh` to download from S3, run monews and then upload the results back up to S3.

## Docker

You can build the container via `docker build -t monews:latest .`. When running the container you need to give it a config folder with a `config.yaml` in it. You may copy `config.yaml.example` to `config.yaml` and use this folder. Now you can go ahead and run something like:

```bash
docker run --rm -t -v LOCAL_PATH_TO_CONFIG_FOLDER:/opt/monews/config -e "AWS_ACCESS_KEY_ID=..." -e "AWS_SECRET_ACCESS_KEY=..." -e "EC2_URL=https://END-POINT" monews:latest
```

Note that you can find the service endpoints via the [Amazon documentation](http://docs.aws.amazon.com/general/latest/gr/rande.html#ec2_region).

## Things left todo

* Improve README (see notes in dayone and add images)...
* add setting to spec how often to refresh (e.g. only every 10 hours)
* check that the setting how often to pull in new data is obeyed.

## Licence

MIT.