#!/usr/bin/env perl
use strict;
use v5.10.0;
use warnings;
use strict;

$main::INVOKED = $0;
#$main::PID = $$;


sub util_get_display_pwd()
{
    my $homedir = $ENV{HOME};
    my $user = $ENV{USER};
    my $pwd = `pwd`;
    if ( $pwd =~ /^$homedir\/(.+)/ )
    {
        my $rest = $1;
        return "~$user/$rest";
    }

    return $pwd;
}

sub cmd_nt { exec('gnome-terminal --hide-menubar'); }
sub cmd_e 
{
    my $first_arg = $ARGV[0];

    my $display_dir = util_get_display_pwd();
    print STDERR "first_arg: $first_arg\n";
    my $exec_str  
               = "gnome-terminal --hide-menubar --window-with-profile=ide_cmd_e";
    $exec_str .= " --command=\'";
    #$exec_str .= "view $first_arg\'";
    $exec_str .= "bash -c \"source ~/.bashrc;set-title XXX;view $first_arg\"\'";
    exec($exec_str);

#   exec('gnome-terminal --hide-menubar --window-with-profile=ide_cmd_e'); 
#   exec('gnome-terminal --hide-menubar --window-with-profile=ide_cmd-e --command=\'vi xxx\''); 
    
}

sub interpret_invoked()
{
    if ( $main::INVOKED =~ /nt/ ) { cmd_nt(); }
    if ( $main::INVOKED =~ /e/ ) { cmd_e(); }
    
    print STDERR "ide.pl could not interpret $main::INVOKED\n";
    exit(-1);
}
#main
#

interpret_invoked();


#
#

