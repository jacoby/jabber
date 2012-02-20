#!/usr/bin/perl
use 5.010 ;
use strict ;
use warnings ;
use Carp ;
use Data::Dumper ;
use Net::XMPP ;
use YAML qw{ LoadFile DumpFile } ;

my $config = config() ;

my $recipient = shift @ARGV ;

#msg
my $message = join ' ', @ARGV ;
if ( $message eq '' ) {
    while ( <STDIN> ) {
        $message .= $_ ;
        }
    }
send_jabber( $recipient, $message ) ;
exit 1 ;

# --------- --------- --------- --------- --------- --------- ---------
sub send_jabber {
    my ( $recipient, $message ) = @_ ;
    my $agent      = $config->{ agent } ;
    my $connection = $config->{ connection } ;
    my $Connection = new Net::XMPP::Client() ;

    # Connect to talk.google.com
    my $status = $Connection->Connect(
        hostname       => $connection->{ hostname },
        port           => $connection->{ port },
        componentname  => $connection->{ componentname },
        connectiontype => $connection->{ connectiontype },
        tls            => $connection->{ tls }
        ) ;
    if ( !( defined( $status ) ) ) {
        say 'ERROR: XMPP connection failed.' ;
        print " ($!)\n" ;
        exit( 0 ) ;
        }

    # Change hostname
    my $sid = $Connection->{ SESSION }->{ id } ;
    $Connection->{ STREAM }->{ SIDS }->{ $sid }->{ hostname } =
        $connection->{ componentname } ;

    # Authenticate
    my @result = $Connection->AuthSend(
        username => $agent->{ username },
        password => $agent->{ password },
        resource => $agent->{ resource }
        ) ;

    if ( $result[ 0 ] ne "ok" ) {
        print "ERROR: Authorization failed: $result[0] - $result[1]\n" ;
        exit( 0 ) ;
        }

    # Send messages

    $Connection->MessageSend(
        to       => $recipient,
        resource => $agent->{ resource },
        subject  => "Notification",
        type     => "chat",
        body     => $message
        ) ;

    sleep 1 ;

    $Connection->Disconnect() ;
    }

# --------- --------- --------- --------- --------- --------- ---------
sub config {
    my $config ;
    my $config_file = $ENV{ HOME } . '/.xmpp.cnf' ;
    if ( $config_file && -f $config_file ) {
        $config = LoadFile( $config_file ) ;
        }
    return $config ;
    }
