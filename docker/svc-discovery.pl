#!/usr/bin/perl -w

use Net::DNS;
 
my $num_args = $#ARGV + 1;
if ($num_args != 1) {
    print "\nUsage: svc-discovery.pl service_name\n";
    exit;
}
 
my $service_name = $ARGV[0];
 
my $resolver = new Net::DNS::Resolver( config_file => '/etc/resolv.conf' );
my $reply = $resolver->search($service_name, 'SRV');
my @addrs;
 
if ($reply) {
    foreach my $ans ($reply->answer) {
        my $q = $resolver->search($ans->target);
        if ($q) {
            foreach my $q_ans ($q->answer) {
                next unless $q_ans->type eq "A";
                push @addrs, $q_ans->address;
            }
        }
    }
}
 
if (0+@addrs > 0) {
    my $joined_addrs = join(",", @addrs);
    print($joined_addrs);
}