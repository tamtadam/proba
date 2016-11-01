#!/usr/bin/perl -w

package client_tcp;

use strict;
use IO::Socket;
use Data::Dumper;
use Sys::Hostname;
use POSIX;
use Carp;
use IO::Socket::Timeout;

$| = 1; # flush after every wright

sub new {
   my $instance = shift;
   my $class    = ref $instance || $instance;
   my $self     = {};

   $self = {
              'socket_m'   => undef               ,
              'host'       => $_[ 0 ]->{ 'host' } ,
              'port'       => $_[ 0 ]->{ 'port' } ,
              'autoconn'   => $_[ 0 ]->{ 'autoconn' },
              'connect_retry'   => $_[ 0 ]->{ 'connect_retry' } // 10,
           };
	bless $self, $class;
	$self
}

sub connect{
   my $self = shift;
   $self->{'socket_m'} = undef ;
   my $cnt = 0;
   until( $self->{'socket_m'} or $cnt > $self->{'connect_retry'} ){
       $self->{'socket_m'} =  new IO::Socket::INET(
            		   PeerAddr => $self->{ 'host' } ,
      				   PeerPort => $self->{ 'port' } ,
      				   Reuse    => 1                 ,
      				   Timeout  => 1                 ,
      				   Proto    => 'tcp') or print "CONNECTION ERROR: $cnt\n";
       $cnt++;
   }
   IO::Socket::Timeout->enable_timeouts_on( $self->{'socket_m'} );
   $self->{'socket_m'}->read_timeout(2);
   $self->{'socket_m'}->write_timeout(2);
   return $self->{'socket_m'};
}

sub send_msg{
    my $self = shift;
    my $msg  = shift;
    my $without_recv = shift ;
    my $rv  = $self->{'socket_m' }->send( "$msg\r\n", 0 );
    if ( $self->{ autoconn } && (!defined $rv or $rv == 0 or $rv == -1 ) ){
        $self->my_close();
        $self->{'socket_m'} = undef;
        $self->connect() ;
        return undef ; # trigger reconnect
    }
    return $rv;
}

sub my_recv{
    my $self = shift ;
    my $rv2 ;
    my $msg ;
    $rv2 = $self->{'socket_m' }->recv( $msg, POSIX::BUFSIZ, 0 );
    #print "RECV bytes: ".  $rv2 . "\n";
    #print "MSG:       ---->". $msg . "<---\n";       
    if ( defined $rv2 ) {
        return $msg;
        
    } else {
        print Dumper $!;
        $self->my_close();
        $self->{'socket_m'} = undef;
        $self->connect() ;
        return '';
    }
}

sub my_close {
	my $self = shift ;
	shutdown( $self->{ 'socket_m' }, 2);
	close $self->{ 'socket_m' } ;
}

sub init_relay{
    my $self = shift;
    print "Ret:" . $self ->send_msg("") . "\n";
    print "Ret:" . $self ->send_msg("B") . "\n";
    print "Ret:" . $self ->send_msg("C") . "\n";
    print "Ret:" . $self ->send_msg("n", 1 ) . "\n";
}

1;