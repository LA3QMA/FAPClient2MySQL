#!/usr/bin/perl

use Ham::APRS::IS;
use Ham::APRS::FAP qw(parseaprs);

use Date::Manip;

use DBI;
use DBD::mysql;

# SQL config
$database = "APRSC";
$host = "localhost";
$tablename = "APRSPackets";
$user = "APRS";
$pw = "";
$port = "3306";

# APRS-IS config
$IShost = "servername:14580";
$ISmycall = "N0CALL";
$ISfilter = "t/poimqstunw";
$ISclient = "APRSC_MySQL_Client 1.0";

$connect = DBI->connect("DBI:mysql:database=$database;host=$host;port=$port",$user,$pw);

my $is = new Ham::APRS::IS($IShost, $ISmycall, 'filter' => $ISfilter, 'appid' => $ISclient);
$is->connect('retryuntil' => 3) || die "Failed to connect: $is->{error}";

for (;;){
        my $l = $is->getline_noncomment();
        next if (!defined $l);

        my %packetdata;
        my $retval = parseaprs($l, \%packetdata);

        if ($retval == 1) {
# Comment out 'print' as this is only here for debug information
# Should probably add a 'verbose' function later
#                        print "CALLSIGN: $packetdata{srccallsign}\n";
#                        print "TYPE: $packetdata{type}\n";
#                        print "PACKET: $packetdata{origpacket}\n";
#                        print "LATITUDE: $packetdata{latitude}\n";
#                        print "LONGITUDE: $packetdata{longitude}\n";
#                        print "SYMBOLtable: $packetdata{symboltable}\n";
#                        print "SYMBOL: $packetdata{symbolcode}\n";
#                        print "SPEED: $packetdata{speed}\n";
#                        print "COURSE: $packetdata{course}\n";
#                        print "ALTITUDE: $packetdata{altitude}\n";
#                        print "BODY: $packetdata{body}\n";

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
#			print "$Time\n";
#PacketType
			if($packetdata{type} eq 'message')
			{
#			print "Message/Bulletin: 1\n";
			$Ptype = 1;
			}
			if ($packetdata{type} eq 'object')
			{
#			print "Object/Item: 2 - Object\n";
			$Ptype = 2;
			}
			if ($packetdata{type} eq 'item')
			{
#			print "Object/Item: 2 - Item\n";
			$Ptype = 2;
			}
			if($packetdata{type} eq 'location')
			{
#			print "Position: 3\n";
			$Ptype = 3;
			} elsif ($packetdata{type} eq '!')
			{
#			print "Position: 3b\n";
			$Ptype = 3;
			}
			if($packetdata{type} eq 'wx')
			{
			$IsWx = 1;
			} else {
			$IsWx = 0;
			}

	# Commented out until we know how and what we want to store in SQL
	# APRSPackets
	$sqlquery = "INSERT INTO APRSPackets VALUES (\'" . $packetdata{srccallsign} . "\',\'" . $Time . "\',\'" . $Ptype . "\',\'" . $IsWx . "\',\'" . $packetdata{origpacket} . "\')";
#	print $sqlquery;
#	print "\n";
	$query = $connect->prepare($sqlquery);
	$query->execute();

	#APRSPosits
	# CallsignSSID, ReportTime, Latitude, Longitude, Course, Speed, Altitude, Packet, Icon

	$sqlquery = "REPLACE INTO APRSPosits VALUES (\'" . $packetdata{srccallsign} . "\',\'" . $Time . "\',\'" . $packetdata{latitude} . "\',\'" . $packetdata{longitude} . "\',\'" . $packetdata{course} . "\',\'" . $packetdata{speed} . "\',\'" . $packetdata{altitude} . "\',\'" . $packetdata{origpacket} . "\',\'" . $packetdata{symboltable} . $packetdata{symbolcode} . "\')";
#	print $sqlquery;
#	print "\n";
        $query = $connect->prepare($sqlquery);
        $query->execute();

        } else {
                warn "Parsing failed: $packetdata{resultmsg} ($packetdata{resultcode})\n";
        }
}

$is->disconnect() || die "Failed to disconnect: $is->{error}";




