# guildbook

LDAP-based address book interface

## development

```shell
bundle install
npm install
npx webpack-dev-server --port=8080 &
WEBPACK_DEV_SERVER_URL=http://localhost:8080/assets/ bundle exec rackup --port=9292 &
```


## deployment

```shell
bundle install --deployment
npm install --only=production
npm run-script build
bundle exec rackup -E production
```
