# Ratingator bot

## Description

Telegram bot for tracking intellectual games team rating on [rating site](https://rating.chgk.info/). 
It is built using AWS Serverless tools and can be easily deployed with SAM.

## Features

### Rating tracking

Once a week (schedule can be changed on deployment stage) bot is sending statistic message to chat.

To enable statistic tracking run `/watch 12345` command. 12345 here is team numeric id from rating site. To disable statistic tracking run `/unwatch`.

`/watch` and `/unwatch` commands can be disabled on deployment stage. In such case bot owner should add records to DynamoDB table on his own. Record should contain at least two attributes:
  - `chat_id`: id of chat in Telegram where statistics will be sent. Bot has to be the member of this chat.
  - `team_id`: team numeric id on rating site

Example:
```json
{ "chat_id": 123456789, "team_id": 88 }
```

**Limitation:** Bot will only track one team results for one chat. If you will run `/watch` several times with different team ids - only the last one will be used.

### Znatoki.info

Bot cat get game announces from [znatoki.info](https://znatoki.info) website. In that case it will check the site rss once a week (schedule can be changed on deployment stage)
and create a poll with the list of announced games so team players can let everyone know what games they are going to attend.

Can be enabled with `/znatoki_on` command and disabled with `/znatoki_off` command.

By default the poll will contain all game definitions from the site and "Can not attend" option. 
If you want other options to be appended to your polls, you can use `/extra_poll_options` command.

### Venues

Bot can track venues and send brief data about upcoming games. Information is sent once a day for games that are planned for that day.
To enable the feature use `/venue 1234` command where 1234 is venue numeric id from rating site. There is no limit on the number of venues monitored by one team.
To disable venue monitoring use `/venue_unwatch_1234` command.
Running `/venue` command will show the list of venues you are already monitoring and instructions to manage their list.

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

### Template parameters

Template accepts 3 parameters:

1. `TelegramBotToken` - secret token you get from BotFather
1. `KeepTokensSecret` - flag to choose whether you want AWS to keep your token in SecretsManager or as environment variable. Values: `true`/`false`
1. `AllowSelfRegistration` - flag to choose if we want to allow users to enable team tracking manually with `/watch` command. Values: `true`/`false`

## Author

Eugene Lapeko

## License

[MIT](LICENSE)
