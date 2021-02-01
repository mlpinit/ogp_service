# OGP service

## Usage instructions

Note: There is a postman collection included in the tar file if you prefer using
postman.

Here are some example requests:

- POST request example # returns { 'id': "uuid" } or error

```
curl -X POST \
  'http://marius.pop.hiring.keywee.io/stories?url=https://ogp.me/' \
  -H 'cache-control: no-cache'
```

- GET request example # returns parsed OGP tags or error

Note: Replace id with id received from the request above

```
curl -X GET \
  http://marius.pop.hiring.keywee.io/0e537896-d1ad-4add-83b3-633389624b32 \
  -H 'cache-control: no-cache'
```

## Functionality

The Object Type tags mentioned [here](https://ogp.me/#type_music) and below,
have not been scraped. Only "og:" prefixed tags are scraped at this time but the
pattern can be easily extended for other tags.

## Development Setup instructions

- install and start redis
- install ruby 2.7.2
- run: bundle install
- run: bundle exec puma -C config/puma.rb

## Start puma server on provided server

RACK_ENV=production bundle exec puma -C config/puma.rb --bind unix:///tmp/puma.sock

## Run tests

bundle exec rspec --format documentation

## Other thoughts and considerations

Redis was used for the purpose of this exercise as an in memory data store and
to satisfy the single scraping constraint. The assumption was that only one
Redis instance would be running that would handle race conditions from the puma
servers. A persistent NoSQL data store would likely be preferable for the long
term storage.

There's an argument to be made against the additional complexity added by
handling race conditions to ensure the single scrape requirement is satisfied.
