# Rocky9_alert_script
Get your Telegram bot and account ready. You can get notifications through this script if you have ssh login or logout on your Rocky 9 OS server, or if you enter the cmd command.

If you run a script and get a ssh notification but not a cmd command notification, try running the command below.
```bash
source /etc/profile
systemctl restart rsyslog
```
