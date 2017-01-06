#!/usr/bin/perl
# quick and dirty alexa cgi script, to announce a stock ticket price
#
use CGI;
use JSON;
use Data::Dumper;

use constant APP_ID => 'amzn1.ask.skill.1234';
use constant USER_ID => 'amzn1.ask.account.ZZZZZ';

sub mylog {
 print LOG scalar localtime . " " . @_[0] . "\n";
}

my $cgi = CGI->new();
my $postData = $cgi->param('POSTDATA');

$json=$postData;

open(LOG,">>/var/www/html/log/foo.txt");
mylog("Starting");
mylog("json is set to " . $json);
$x=decode_json $json;
mylog("request->intent->name is " . $x->{request}->{intent}->{name});

# Validate app id, must be ours
if($x->{session}->{application}->{applicationId} ne APP_ID) {
 mylog("duff app id " . $x->{session}->{application}->{applicationId} . " should be " . APP_ID);
 die;
}

# Validate user id, must be ours
if($x->{session}->{user}->{userId} ne USER_ID) {
 mylog("duff user id " . $x->{session}->{user}->{userId} . " should be " . USER_ID);
 die;
}

# Validate type is LaunchRequest or SessionEndedRequest
mylog("type is " . $x->{request}->{type});
if($x->{request}->{type} ne 'LaunchRequest' &&
   $x->{request}->{type} ne 'SessionEndedRequest') {
 mylog("duff type " . $x->{request}->{type} . " should be LaunchRequest or SessionEndedRequest");
 die;
}

mylog("ok, validated!");

# command
mylog("cmd is " . $x->{request}->{intent}->{slots}->{command}->{name} );

# if it's a session ended request, we're done, finish
if($x->{request}->{type} eq 'SessionEndedRequest') {
 exit;
}

# give a response
my $json_hash = {};
my $response_hash = {};
my $outputSpeech_hash = {};
my $card_hash = {};
my $reprompt_hash = {};

$json_hash->{version} = $x->{version};
mylog("have set json reply version to " . $x->{version});
$json_hash->{sessionAttributes} = JSON::null;
$json_hash->{response} = $response_hash;

$response_hash->{outputSpeech} = $outputSpeech_hash;
$response_hash->{card} = $card_hash;
$response_hash->{reprompt} = $reprompt_hash;
$response_hash->{ShouldEndSession} = JSON::true;

$outputSpeech_hash->{type} = "PlainText";

open(A,"curl -s 'http://download.finance.yahoo.com/d/quotes.csv?s=hsba.l&f=l1' |");
while(<A>) {
 chomp;
 $outputSpeech_hash->{text} = "HSBC share price is " . $_ . " pounds, woo hoo";
}
close A;

$card_hash->{type} = 'Simple';
$card_hash->{title} = 'gosh';
$card_hash->{content} = 'gosh';

$reprompt_hash->{outputSpeech} = $outputSpeech_hash;

my $json = encode_json $json_hash;
print "Content-Type: application/json;charset=UTF-8\nContent-Length: " . length($json) . "\n\n";
print $json . "\n";
close A;
