#!/usr/bin/env perl
use strict;

sub util::stdout($);
die "Cannot use JSON, try as root : 'cpan install json'"
  unless json::can_use();

die "Cannot use force cli, Please visit https://force-cli.heroku.com/ and install it"
  unless force_cli::can_use();

force_cli::login()
  unless force_cli::is_logged_in();

my $mtseConf = mtse::load_config();
my $cache = mtse::load_cache($mtseConf);

json::print($cache, 'CACHE');


exit(0);

#######


package util;

sub util::stdout($)
{ 
  my $x = shift;
  print "mtse: $x\n"; 
}

sub util::slurp_file
{
  my $file  = shift;
  local $/;
  open( my $fh, '<', $file ) || die "could not open file $file, $!";
  my $json = <$fh>;
  return $json;
}


package json;

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
  my $tst = util::slurp_file($path);
  my $ds = json::decode($tst);
  return $ds;
}

sub json::print
{
  my $ds = shift;
  my $label =  shift; 
  $label = 'none' 
    unless defined $label;
  my $str = json::encode($ds);

  print "BEGIN JSON ($label):\n";
  print $str;
  print "END   JSON ($label).\n";

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
    util::stdout "detected login [$id]";
    my ($ex,$rc,$ret) = force_cli::exec('whoami');
    if ( 1 == $ex )
    {
      util::stdout("warning looks stale, logging out [$id]");
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


package mtse;



sub mtse::ensure_dir
{
  my $HOME = $ENV{HOME};
  
  die "HOME environment variable returns a non existent directory, I need that to be valid [$HOME]"
    unless -d $HOME;

  my $mtseDir = "$HOME/.mtse";

  mkdir $mtseDir, 0700
    unless -d $mtseDir;

  return $mtseDir;
}

sub mtse::load_config
{
  my $dir = mtse::ensure_dir();

  my $fil = "$dir/mtse_conf.json";

  die "$fil does not exist, create one '\n{\n  \"tses\" : \n  {  \"First Last\" : {}\n  }\n}\n'" 
    unless -f $fil;

  my $ds = json::load_file($fil);
  return $ds;
}

sub mtse::load_cache
{
  my $config = shift;
  my $cache = {};

  my $inClause = undef; 

  while (my ($k,$v) = each %{$config->{tses}})
  {
    $inClause .= ', ' if  defined $inClause;
    $inClause .= "'$k'";
  }

  my $rs = mtse::get_user_ids($inClause); 

  foreach my $rec (@{$rs})
  {
    my $nm = $rec->{Name};
    my $id = $rec->{Id};

    $cache->{tses}->{$nm}->{Id} = $id;
    my $tseData = mtse::get_tse_data($nm,$id);
    $cache->{tses}->{$nm}->{Data} = $tseData; 

  }

  return $cache;
}


sub mtse::get_user_ids
{
  my $inList = shift;
  my $soql = "Select User.Id,User.Name from User WHere User.Name in ($inList)";
  util::stdout "querying user ids for configured TSEs ($inList)";
  my $res = force_cli::query($soql);
  return $res;
}

sub mtse::get_tse_data
{
  my ($nm,$id) = @_;

  my $data = {};
  $data ->{Name} = $nm;

  my 
  $soql = "Select Case.OwnerId,Case.Status,Case.CaseNumber,AccountId,CreatedDate,ClosedDate,Comment_Count__c,Components__c from Case WHere Case.OwnerId = '$id'";
 
  util::stdout "querying cases for $nm";
  my $CaseList = force_cli::query($soql);
  $data->{CaseList} = $CaseList;

  $soql = "Select CreatedDate,Is_Published__c,Case__c,Id,CreatedById,Created_By_Name__c,Is_FTS_Comment__c,Name from Case_Comment__c where CreatedById = '$id'" ;
  util::stdout "querying comments for $nm";
  my $CommentList = force_cli::query($soql);
  $data->{CommentList}  = $CommentList;

  return $data;

  
}
