#Change databasename as required
#Setup borrowed from javaaprssrv - Pete Loveall AE5PL
#This setup is probably going to be changed when FAPClient2MySQL evolving 

CREATE DATABASE database_name;
USE database_name;

CREATE TABLE APRSPackets
(
CallsignSSID varchar(9) not null,
ReportTime datetime not null,
PacketType tinyint not null,
IsWx tinyint not null,
Packet blob null
);

CREATE TABLE APRSPosits
(
CallsignSSID varchar(9) not null,
ReportTime datetime not null,
Latitude float not null,
Longitude float not null,
Course smallint null,
Speed int null,
Altitude int null,
Packet blob null,
Icon char (2) null
);

CREATE TABLE APRSTrack
(
CallsignSSID varchar(9) not null,
ReportTime datetime not null,
Latitude float not null,
Longitude float not null,
Icon char (2) null,
Course smallint null,
Speed int null,
Altitude int null
);

CREATE TABLE APRSWx
(
CallsignSSID varchar(9) not null,
ReportTime datetime not null,
WindDir smallint null,
WindSpeed smallint null,
GustSpeed smallint null,
Temperature smallint null,
HourRain decimal(4, 2) null,
DayRain decimal(6, 2) null,
MidnightRain decimal(6, 2) null,
Humidity tinyint null,
BarPressure decimal(5, 1)null
);

CREATE TABLE APRSMsg
(
CallsignSSID varchar(9) not null,
CallsignTo varchar(9) not null,
ReportTime datetime not null,
Message blob,
Packet blob
);

CREATE INDEX IX_APRSPackets_RT ON APRSPackets(ReportTime);

CREATE INDEX IX_APRSTrack_RT ON APRSTrack(ReportTime);

CREATE INDEX IX_APRSWx_RT ON APRSWx(ReportTime);

CREATE INDEX IX_APRSPackets ON APRSPackets(CallsignSSID, ReportTime);

ALTER IGNORE TABLE APRSPosits ADD
CONSTRAINT PK_APRSPosits PRIMARY KEY NONCLUSTERED
(
CallsignSSID
);

CREATE INDEX IX_APRSPosits ON APRSPosits(ReportTime);

CREATE INDEX IX_APRSTrack ON APRSTrack(CallsignSSID, ReportTime);

CREATE INDEX IX_APRSWx ON APRSWx(CallsignSSID, ReportTime);
