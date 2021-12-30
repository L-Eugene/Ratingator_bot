# Ratingator bot

## Description

Telegram bot for tracking "What? When? Where?" team tating on [rating site](https://rating.chgk.info/). 
It is built using AWS Serverless tools and can be easily deployed with SAM.

## Features

### Rating tracking

Once a week (schedule can be changed on deployment stage) bot is sending statistic message to chat.

To enable statistic tracking run `/watch 12345` command. 12345 here is team numeric id from rating site. To disable statistic tracking run `/unwatch`.

`/watch` and `/unwatch` commands can be disabled on deployment stage. In such case bot owner should add records to DynamoDB table on his own. Record should contain at least two attributes:
  - **ChatID**: id of chat in Telegram where statistics will be sent. Bot has to be the member of this chat.
  - **TeamID**: team numeric id on rating site

Example:
```json
{ "ChatID": 123456789, "TeamID": 88 }
```

**Limitation:** Bot will only track one team results for one chat. If you will run `/watch` several times with different team ids - only the last one will be used.

### Randomize

You can use `/random` command to cast the lot. Bot will parse command message for items separated by space or new line and will select one of them.

## Deployment

To deploy the bot you need to have AWS SAM CLI [configured](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-sam-cli-install.html).

Then perform next steps:
1. Clone this repo
1. Create `samconfig.toml` file (example can be used).
1. Update `sambonfig.toml` with your bot token and s3 bucket id
1. Run `sam build` to prepare package
1. Run `sam deploy` to start deployment. Deployment process will print API endpoint URL that can be used as WebHook if needed.
1. WebHook is needed for bot to accept commands from usees. You can enable WebHooks using example curl command printed by deployment process. 

## Author

Eugene Lapeko

## License

[MIT](LICENSE)
