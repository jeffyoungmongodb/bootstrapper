#!/usr/bin/env perl
use strict;

die "Cannot use JSON, try as root : cpan install json"
  unless json::can_use();

die "Cannot use force cli, Please visit https://force-cli.heroku.com/ and install it"
  unless force_cli::can_use();

force_cli::login()
  unless force_cli::is_logged_in();



exit(0);


package json;

sub json::slurp_file
{
  my $file  = shift;
  local $/;
  open( my $fh, '<', $file ) || die "could not open file $file, $!";
  my $json = <$fh>;
  return $json;
}


sub json::can_use
{
  my $res = eval 'require JSON;';
  if ( defined $res ) { return 1;}
  else                { return 0;}
}

sub json::decode
{
  my $json = shift;
  require JSON;
  my $res = JSON::decode_json($json);
  return $res;
}

sub json::encode
{
  my $ds = shift;
  my $opts = shift;
 
  require JSON;
  my $json = JSON->new->utf8;

  #default
  $json->pretty(1); 
  $json->allow_unknown(1);
  
  if (defined $opts)
  {
    if ( defined $opts->{pretty} )
    {
      if ( $opts->{pretty} )  { $json->pretty(1); }
      else                    { $json->pretty(0); }
    } 
  }

  #$json->allow_blessed(1);
  #$json->convert_blessed(1);

  my $str = $json->encode($ds);
  return $str;
}

package force_cli;

sub force_cli::exec
{
  my $arg = shift;
  my $cmd = "force $arg";
  my $ret = `$cmd`;
  my $rc = $?;
  my $ex = $rc >> 8;  
  return ($ex,$rc,$ret); 
}

sub force_cli::can_use
{
  my ($ex,$rc,$ret) = force_cli::exec('version');

  if ( -1 == $rc )
  {
    print STDERR "could not execute force cli program\n";
    return 0;
  }

  return 1; 
}

sub force_cli::login
{
  my ($ex,$rc,$ret) = force_cli::exec('login -i=mongodb.my.salesforce.com');
  return 1;
}

sub force_cli::is_logged_in
{
  my ($ex,$rc,$ret) = force_cli::exec('logins');

  if ($ret =~ /no logins/)
  {
    return 0;
  }
  return 1; 

}
