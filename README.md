# TinajaBot

A bot for TINAJA Ingeniería Discord server.

## Install dependencies
```sh
bundle install
```
Create a new `.env` file using `.env.sample` as a template to set the required credentials.

## Run the bot
```sh
rake run
```

## Docker
You can build a docker image of the project by running:

```
docker build . -t tinaja-bot:latest
```

Then run it like this:

```
docker run \
--env TOKEN=<YOUR TOKEN> \
--env CLIENT_ID=<YOUR CLIENT ID> \
tinaja-bot
```
