# guildbook

LDAP-based address book interface

## development

```shell
bundle install
npm install
export WEBPACK_DEV_SERVER_URL=http://localhost:8080/assets/
npm run-script serve -- --port=8080 &
bundle exec rackup --port=9292 &
```

## deployment

```shell
bundle install --deployment
npm install --only=production
npm run-script build
bundle exec rackup -E production
```
