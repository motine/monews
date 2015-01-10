# MoNews

- A server script which scraps sources news every night at the same time and get the top N articles (tagesschau offers a homepage sorted rss, hackernews (best) is sorted, reddit is sorted, medium monthly things are rated)
- convert these top N articles as RSS feed for each source
- import this in your favorite rss reader

**TODO** See notes in dayone...

Simply run `monews.rb`.

## Installation

* Needs Ruby >= 2.0.0p353.
* Run `bundle install`
* Copy `config.yaml.example` to `config.yaml` and adjust it.

### Docker

You can build the container via `docker build -t monews:latest .`. When running the container you need to give it a config folder with a `config.yaml` in it. You may copy `config.yaml.example` to `config.yaml` and use this folder. Now you can go ahead and run something like:

```bash
docker run --rm -t -v LOCAL_PATH_TO_CONFIG_FOLDER:/opt/monews/config -e "AWS_ACCESS_KEY_ID=..." -e "AWS_SECRET_ACCESS_KEY=..." -e "EC2_URL=https://END-POINT" monews:latest`
```

Note that you can find the service endpoints via the [Amazon documentation](http://docs.aws.amazon.com/general/latest/gr/rande.html#ec2_region).


### AWS

When setting up a machine manually which runs monews: Make sure the instance has the correct role so it can access the S3 storage. Also, you may delete the storage on termination and set the shutdown behaviour to terminate. And obviously, the launch script (`ec2boot.sh`) shall be added.

To start the instance from the console use the following:

    ec2-run-instances --instance-type t2.micro --instance-initiated-shutdown-behavior terminate --user-data-file ec2boot.sh -g everywhere -p monews ami-892fe1fe

You may need to install `brew install ec2-ami-tools ec2-api-tools` on a Mac first. Don't forget to set your bash environment with the proper access keys and region. The code above assumes you have a security group `everywhere` and a role which has access to s3 named `monews`. Also note, the specified AMI is only available at Ireland._

You will need to add the following policy to your bucket:

    {
      "Version": "2008-10-17",
      "Statement": [{
        "Sid": "AllowPublicRead",
        "Effect": "Allow",
        "Principal": { "AWS": "*" },
        "Action": ["s3:GetObject"],
        "Resource": ["arn:aws:s3:::monews/*" ]
      }]
    }

**TODO** recurring auto scale (see [here](http://alestic.com/2011/11/ec2-schedule-instance) for inspiration).

**TODO** Where to get the links to the bucket (directly at the file).

## Things left todo

* add setting to spec how often to refresh (e.g. only every 10 hours)
* check that the setting how often to pull in new data is obayed.

## Licence

MIT.