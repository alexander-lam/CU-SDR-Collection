function utcg = gpst2utcg(weekNum, TOW)
% Accepts week number and time of week in seconds and returns UTCG

% Calculate time since GPS Epoch
gpsEpoch = datetime(1980,1,6,'TimeZone','UTCLeapSeconds', 'Format', "uuuu-MM-dd'T'HH:mm:ss.SSSSSSSSS'Z'");
utcg = gpsEpoch + seconds(weekNum*604800) + seconds(TOW);   % 604,800 sec in a week

% Return time in UTCG
utcg.TimeZone = 'UTC';