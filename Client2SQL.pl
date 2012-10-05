#!/usr/bin/perl

use Ham::APRS::IS;
use Ham::APRS::FAP qw(parseaprs);

use Date::Manip;

use DBI;
use DBD::mysql;

# SQL config
$database = "APRSC";
$host = "localhost";
$tablename = "APRSPackest";
$user = "APRS";
$pw = "password";
$port = "3306";

# APRS-IS config
$IShost = "hostname:14580";
$ISmycall = "N0CALL";
$ISfilter = "t/poimqstunw";
$ISclient = "APRSC_MySQL_Client 1.0";

$connect = DBI->connect("DBI:mysql:database=$database;host=$host;port=$port",$user,$pw);

my $is = new Ham::APRS::IS($IShost, $ISmycall, 'filter' => $ISfilter, 'appid' => $ISclient);
$is->connect('retryuntil' => 3) || die "Failed to connect: $is->{error}";

for (;;){
        my $l = $is->getline_noncomment();
        next if (!defined $l);

        print "\n--- new packet ---\n";

        my %packetdata;
        my $retval = parseaprs($l, \%packetdata);

        if ($retval == 1) {
# Comment out 'print' as this is only here for debug information
# Should probably add a 'verbose' function later
                        print "CALLSIGN: $packetdata{srccallsign}\n";
                        print "TYPE: $packetdata{type}\n";
                        print "PACKET: $packetdata{origpacket}\n";
                        print "LATITUDE: $packetdata{latitude}\n";
                        print "LONGITUDE: $packetdata{longitude}\n";
                        print "SYMBOLtable: $packetdata{symboltable}\n";
                        print "SYMBOL: $packetdata{symbolcode}\n";
                        print "SPEED: $packetdata{speed}\n";
                        print "COURSE: $packetdata{course}\n";
                        print "ALTITUDE: $packetdata{altitude}\n";
                        print "BODY: $packetdata{body}\n";

                        if($packetdata{type} eq 'location')
                        {
                        ($Second, $Minute, $Hour, $DayOfMonth, $Month, $Year, $Weekday, $DayOfYear, $IsDST) = localtime(time);
                        $RealMonth = $Month + 1;
                        $GMTTime = gmtime(time);
                        $Time = &UnixDate($GMTTime, '%Y-%m-%d %H:%M:%S');

	# Commented out until we know how and what we want to store in SQL

	#$sqlquery = "INSERT INTO APRSPackets VALUES (\'" . $packetdata{srccallsign} . "\',\'" . $Time . "\',1,1,\'" . $packetdata{origpacket} . "\')";
	#$query = $connect->prepare($sqlquery);
	#$query->execute();
	#printf('%d-%02d-%02d %02d:%02d:%02d', $Year+1900, $RealMonth, $DayOfMonth, $Hour, $Minute, $Second);

                        } elsif($packetdata{type} eq 'object')
                        {
                        print "Debug: object";
                        } elsif($packetdata{type} eq 'item')
                        {
                        print "Debug: item";
                        } elsif($packetdata{type} eq 'message')
                        {
                        print "Debug: message";
                        print "BODY: $packetdata{body}\n";
                        }
        } else {
                warn "Parsing failed: $packetdata{resultmsg} ($packetdata{resultcode})\n";
        }
}

$is->disconnect() || die "Failed to disconnect: $is->{error}";




