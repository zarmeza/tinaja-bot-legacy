FROM ruby:3.3.5-alpine

# Build dependencies
ARG BUILD_DEPS="build-base libsodium-dev"
RUN apk update && apk add --no-cache $BUILD_DEPS

WORKDIR /app

# App files
COPY . /app/

# Install gems.
RUN bundle install --jobs 4 --retry 3

CMD ["rake", "run"]
