ARG RUBY=public.ecr.aws/sorah/ruby:3.2.3-bookworm
ARG RUBYDEV=public.ecr.aws/sorah/ruby:3.2.3-dev-bookworm
ARG NODE=public.ecr.aws/docker/library/node:lts-bookworm-slim

###
FROM $RUBYDEV as bundle

WORKDIR /app
COPY Gemfile Gemfile.lock .
RUN bundle config set --local deployment true && \
    bundle config set --local without test:development
RUN --mount=type=cache,target=/tmp/bundler-cache \
    BUNDLE_GLOBAL_GEM_CACHE=/tmp/bundler-cache \
    bundle install --retry=3

###
FROM $NODE as webpack

WORKDIR /app
COPY package.json package-lock.json .
RUN --mount=type=cache,target=/root/.npm \
    npm ci

COPY . .

RUN npm run build

###
FROM $RUBY

WORKDIR /app

COPY . .
COPY --from=bundle /app/vendor /app/vendor
COPY --from=webpack /app/node_modules /app/node_modules

RUN ls -al >&2 ; false
