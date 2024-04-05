ARG RUBY=public.ecr.aws/sorah/ruby:3.2-bookworm
ARG RUBYDEV=public.ecr.aws/sorah/ruby:3.2-dev-bookworm
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

RUN apt-get update -qq && \
    apt-get install -y dumb-init && \
    rm -rf /var/apt/lists/*

WORKDIR /app

COPY . .
COPY --from=bundle /app/vendor /app/vendor
COPY --from=bundle /app/.bundle /app/.bundle
COPY --from=webpack /app/node_modules /app/node_modules

ENTRYPOINT ["/app/docker/entrypoint.sh"]
