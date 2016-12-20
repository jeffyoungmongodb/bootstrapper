#!/usr/bin/env perl
use strict;

die "Cannot use JSON, try as root : 'cpan install json'"
  unless json::can_use();

die "Cannot use force cli, Please visit https://force-cli.heroku.com/ and install it"
  unless force_cli::can_use();

force_cli::login()
  unless force_cli::is_logged_in();

tse::ensure_dir();

my $config = json::load_file("./dat.json");

my $cache = tse::check_cache($config);


exit(0);

#######
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

sub json::load_file
{
  my $path = shift;
  my $tst = json::slurp_file($path);
  my $ds = json::decode($tst);
  return $ds;
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
  my $ret = `$cmd 2>&1`;
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
  else
  {
    my $id = '';
    if ( $ret =~ /(.*)\s\(active\)/ )
    {
      $id = $1;
    }
    print "detected login: $id\n"; 
    my ($ex,$rc,$ret) = force_cli::exec('whoami');
    if ( 1 == $ex )
    {
      print "warning: looks stale, logging out $id\n";
      force_cli::exec("logout $id");
      return 0;
    } 
  }

  return 1; 
}

sub force_cli::query
{
  my $q = shift;
  my ($ex,$rc,$ret) = force_cli::exec("query \"$q\" --format:json");
  my $d = json::decode($ret);
  return $d;
}


package tse;

sub tse::ensure_dir
{
  my $HOME = $ENV{HOME};
  
  die "HOME environment variable returns a non existent directory, I need that to be valid [$HOME]"
    unless -d $HOME;

  mkdir "$HOME/.tse",0700
    unless -d "$HOME/.tse";


}


sub tse::check_cache
{
  my $config = shift;
  my $cache = {};


  my $inClause = undef; 


  while (my ($k,$v) = each %{$config->{tses}})
  {
    $inClause .= ', ' if  defined $inClause;
    $inClause .= "'$k'";
  }

  tse::get_user_ids($inClause); 
  return $cache;
}


sub tse::get_user_ids
{
  my $inList = shift;
  my $soql = "Select User.Id,User.Name from User WHere User.Name in ($inList)";
  my $res = force_cli::query($soql);
  my $str = json::encode($res);
  print "STR: $str\n";
  return $res;
}

