# AI slop by Gemini 3.1 Pro

{ config, pkgs, ... }:
{
  systemd.services.fetch-icss = {
    description = "Fetch daily ICS file from URL";
    path = with pkgs; [
      curl
      coreutils
    ];

    script = ''
      DIR="/home/albi/icss"
      URL_FILE="$DIR/url.txt"

      if [ ! -f "$URL_FILE" ]; then
        echo "Error: $URL_FILE does not exist."
        exit 1
      fi

      # Read the URL, stripping any accidental newlines or carriage returns
      URL=$(tr -d '\n\r' < "$URL_FILE")

      # Get the current ISO date (YYYY-MM-DD)
      DATE=$(date -I)

      OUTPUT_FILE="$DIR/$DATE.ics"

      curl -sL "$URL" -o "$OUTPUT_FILE"

      echo "Successfully downloaded to $OUTPUT_FILE"
    '';

    serviceConfig = {
      Type = "oneshot";
      User = "albi";
      Group = "users";
    };
  };

  systemd.timers.fetch-icss = {
    description = "Timer to fetch ICS file daily";
    wantedBy = [ "timers.target" ];

    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };
}
