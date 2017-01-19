#!/usr/bin/perl
#
use CGI;
use JSON;
use Data::Dumper;

%stocks = ( 'apple'   => [ 'Apple Computer', 'AAPL' ],
            'h s b c' => [ 'HSBC', 'HSBA.L' ],
            'hsbc'    => [ 'HSBC', 'HSBA.L' ],
            'm and s' => [ 'Marks And Spencer', 'MKS.L' ],
            'marks'   => [ 'Marks And Spencer', 'MKS.L' ],
            'marks and spencer' 
                      => [ 'Marks And Spencer', 'MKS.L' ],
            'arm'     => [ 'Arm Holdings', 'ARM.L' ],
            'Astra Zeneca'  
                      => [ 'Astra Zeneca', 'AZN.L' ],
            'B P'     => [ 'BP', 'BP.L' ],
);

use constant APP_ID => 'amzn1.ask.skill.6bd0202b-eb83-4522-99f7-4278301add54';

sub mylog {
 print LOG scalar localtime . " " . @_[0] . "\n";
}

my $cgi = CGI->new();
my $postData = $cgi->param('POSTDATA');

$json=$postData;

open(LOG,">>/var/www/html/log/foo.txt");
$x=decode_json $json;
mylog("request->intent->name is " . $x->{request}->{intent}->{name});

# Validate app id, must be ours
if($x->{session}->{application}->{applicationId} ne APP_ID) {
 mylog("duff app id " . $x->{session}->{application}->{applicationId} . " should be " . APP_ID);
 die;
}

# Validate type is LaunchRequest or SessionEndedRequest
mylog("type is " . $x->{request}->{type});
if($x->{request}->{type} ne 'LaunchRequest' &&
   $x->{request}->{type} ne 'IntentRequest' &&
   $x->{request}->{type} ne 'SessionEndedRequest') {
 mylog("duff type " . $x->{request}->{type} . " should be LaunchRequest or IntentRequest or SessionEndedRequest");
 die;
}

# command
mylog("cmd is " . $x->{request}->{intent}->{slots}->{command}->{name} );

# if it's a session ended request, we're done, finish
if($x->{request}->{type} eq 'SessionEndedRequest') {
 exit;
}

if($x->{request}->{type} eq 'LaunchRequest') {
 SendResponse("okey cokey, stock now started","start stock","Start my stock skill");
}

if($x->{request}->{type} eq 'IntentRequest') {
 mylog("intent is " . $x->{request}->{intent}->{name} );
 mylog("slot is " . $x->{request}->{intent}->{slots}->{Share}->{value} );
 $b=lc($x->{request}->{intent}->{slots}->{Share}->{value});
 mylog($b);
 $ticker='';
 unless(exists($stocks{$b})) {
  SendResponse("unknown ticker","Share Price : unknown ticker","Unknown ticker $b specified");
 }
 
 $name=$stocks{$b}[0];
 $ticker=$stocks{$b}[1];

 if($ticker eq '') {
  SendResponse("unknown ticker $b","Share Price : unknown ticker","Unknown ticker $b specified");
 }
 open(A,"curl -s 'http://download.finance.yahoo.com/d/quotes.csv?s=" . $ticker . "&f=l1' |");
 while(<A>) {
  chomp;
  SendResponse("$name price is $_","Share Price : $b","Result was $_" . 'p');
 }
 close A;
}
exit;
 
sub SendResponse {
 my($msg,$cardtitle,$cardcontent)=@_;
 mylog("sending response of $msg");
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
 $outputSpeech_hash->{text} = $msg;

 $card_hash->{type} = 'Simple';
 $card_hash->{title} = $cardtitle;
 $card_hash->{content} = $cardcontent;
 
 $reprompt_hash->{outputSpeech} = $outputSpeech_hash;

 my $json = encode_json $json_hash;
 print "Content-Type: application/json;charset=UTF-8\nContent-Length: " . length($json) . "\n\n" . $json . "\n";
}
