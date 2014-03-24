# guildbook

LDAP-based address book interface

## deployment

```
$ bundle install --deployment
$ RACK_ENV=production bundle exec rake assets:precompile
$ bundle exec rackup -E production
```
