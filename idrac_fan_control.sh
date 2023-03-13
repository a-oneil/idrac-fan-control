#!/bin/sh

# iDrac
IDRACIP="192.168.1.2"
IDRACUSER='root'
IDRACPASSWORD='password123'

# Slack
BOT_NAME='R510 Temp Warning'
CHANNEL='#general'
WEBHOOKURL='https://hooks.slack.com/services/G01HS3QW1F6B/v11R2WSCAV6/agiKDCXMbcDbDZTCVCGMtWW7'

# Temp control
STATICSPEEDBASE16="0xa" # https://www.hexadecimaldictionary.com/hexadecimal/0x1a/
SENSORNAME="Ambient"
TEMPTHRESHOLD="32"

CURRENT_AMBIENT_TEMP=$(ipmitool -I lanplus -H $IDRACIP -U $IDRACUSER -P $IDRACPASSWORD sdr type temperature | grep $SENSORNAME | cut -d"|" -f5 | cut -d" " -f2 | grep -v "Disabled")

echo ""
echo "The Current Ambient Temperature is $CURRENT_AMBIENT_TEMP°C"

if [ $CURRENT_AMBIENT_TEMP -gt $TEMPTHRESHOLD ]
        then
                echo "Disabling Static Fanspeed"
                # Disable manual fan control
                ipmitool -I lanplus -H $IDRACIP -U $IDRACUSER -P $IDRACPASSWORD raw 0x30 0x30 0x01 0x01
                curl -X POST --data-urlencode "payload={\"channel\": \"$CHANNEL\", \"username\": \"$BOT_NAME\", \"text\": \"Disabling Static Fanspeed! The current temp is $CURRENT_AMBIENT_TEMP°C.\", \"icon_emoji\": \":fire:\"}" $WEBHOOKURL
        else
                echo "Setting Static Fanspeed"
                # Enable manual fan control and set to the static speed ($STATICSPEEDBASE16)
                ipmitool -I lanplus -H $IDRACIP -U $IDRACUSER -P $IDRACPASSWORD raw 0x30 0x30 0x01 0x00
                ipmitool -I lanplus -H $IDRACIP -U $IDRACUSER -P $IDRACPASSWORD raw 0x30 0x30 0x02 0xff $STATICSPEEDBASE16
fi
