#!/usr/bin/perl
use strict;
use warnings;

use Ham::APRS::IS;
use Ham::APRS::FAP qw(parseaprs);

use Date::Manip;

use DBI;
use DBD::mysql;

# SQL config
my $database = "database_name";
my $host = "localhost";
my $user = "APRS";
my $pw = "somepassword";
my $port = "3306";

# APRS-IS config
my $IShost = "rotate.aprs.net:10152";
my $ISmycall = "N0CALL";
my $ISfilter = "t/poimqstunw";
my $ISclient = "Client2SQL 1.0";

my $connect = DBI->connect("DBI:mysql:database=$database;host=$host;port=$port",$user,$pw);
my $query_aprstrack = $connect->prepare("REPLACE INTO APRSTrack VALUES (?,?,?,?,?,?,?,?)");
my $query_aprsposits = $connect->prepare("REPLACE INTO APRSPosits VALUES (?,?,?,?,?,?,?,?,?)");
my $query_aprspackets = $connect->prepare("INSERT INTO APRSPackets VALUES (?,?,?,?,?)");
my $query_aprswx = $connect->prepare("INSERT INTO APRSWx VALUES (?,?,?,?,?,?,?,?,?,?,?)");

#Some local variables used
my ($GMTTime,$Time,$Ptype,$IsWx,$Symbol);

my $is = new Ham::APRS::IS($IShost, $ISmycall, 'filter' => $ISfilter, 'appid' => $ISclient);
$is->connect('retryuntil' => 3) || die "Failed to connect: $is->{error}";

for (;;){
        my $l = $is->getline_noncomment();
        next if (!defined $l);

        my %packetdata;
        my $retval = parseaprs($l, \%packetdata);

        if ($retval == 1) {

# Prepare to insert into APRSPackets
# PacketType:
# 0 = not identified
# 1 = Message/Bulletin
# 2 = Object/Item
# 3 = position

# Data needed: CallsignSSID, ReportTime, PacketType, IsWx, Packet
# Going to add: StatusReport,StationCapabilities,
			print "$packetdata{srccallsign}\n";
                        $GMTTime = gmtime(time);
                        $Time = &UnixDate($GMTTime, '%Y-%m-%d %H:%M:%S');
#			$Symbol = join($packetdata{symboltable},$packetdata{symbolcode});
#PacketType
#For now i'm not using all the IFs but when there are no valid position we should probably not execute the SQL query
#Or are the IFs more memory/cpu hungry?
#Going to use IFs to store messages in seperate tables.

			if($packetdata{type} eq 'message')
			{
			print "Message/Bulletin: 1\n";
			$Ptype = 1;
			}
			if ($packetdata{type} eq 'object')
			{
			print "Object/Item: 2 - Object\n";
			$Ptype = 2;
			}
			if ($packetdata{type} eq 'item')
			{
			print "Object/Item: 2 - Item\n";
			$Ptype = 2;
			}
			if($packetdata{type} eq 'location')
			{
			print "Position: 3\n";
			$Ptype = 3;
			} elsif ($packetdata{type} eq '!')
			{
#			print "Position: 3b\n";
			$Ptype = 3;
			}
			if($packetdata{type} eq 'wx')
			{
			$IsWx = 1;
	#APRSWx
			# CallsignSSID,ReportTime,WindDir,WindSpeed,GustSpeed,Temperature,HourRain,DayRain,MidnightRain,Humidity,BarPressure
			$query_aprswx->execute($packetdata{srccallsign},$Time,$packetdata{'wx'}->{'wind_direction'},$packetdata{'wx'}->{'wind_speed'},$packetdata{'wx'}->{'wind_gust'},$packetdata{'wx'}->{'temp'},$packetdata{'wx'}->{'rain_1h'},$packetdata{'wx'}->{'rain_24'},$packetdata{'wx'}->{'rain_midnight'},$packetdata{'wx'}->{'humidity'},$packetdata{'wx'}->{'pressure'});
			} else {
			$IsWx = 0;
			}

	# APRSPackets
	# CallsignSSID,ReportTime,PacketType,IsWx,Packet
	$query_aprspackets->execute($packetdata{srccallsign},$Time,$Ptype,$IsWx,$packetdata{origpacket});

	#APRSPosits
	# CallsignSSID, ReportTime, Latitude, Longitude, Course, Speed, Altitude, Packet, Icon

	$query_aprsposits->execute($packetdata{srccallsign},$Time,$packetdata{latitude},$packetdata{longitude},$packetdata{course},$packetdata{speed},$packetdata{altitude},$packetdata{origpacket},$packetdata{symboltable}.$packetdata{symbolcode});

	#APRSTrack
	# CallsignSSID, ReportTime, Latitude, Longitude, Icon, Course, Speed, Altitude
	$query_aprstrack->execute($packetdata{srccallsign},$Time,$packetdata{latitude},$packetdata{longitude},$packetdata{symboltable}.$packetdata{symbolcode},$packetdata{course},$packetdata{speed},$packetdata{altitude});

        } else {
		warn "Parsing failed: $packetdata{resultmsg} ($packetdata{resultcode})\n";
		# We should probably save this in a table.
        }
}

$is->disconnect() || die "Failed to disconnect: $is->{error}";
