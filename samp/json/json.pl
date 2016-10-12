#!/usr/bin/env perl
use strict;

die "Cannot use JSON"
  unless json::can_use();

my $jsonStr = '{"x":"xxx","y":"yyy"}';
my $ds = json::decode($jsonStr);
while (my ($k,$v) = each %$ds) { print "K $k,V $v\n"; }

my 
$jsonBack = json::encode($ds);
print "DEFAULT JSON:\n$jsonBack";

$jsonBack = json::encode($ds, { 'pretty' => 0} );
print "NOT PRETTY JSON:\n$jsonBack\n";

$jsonBack = json::encode($ds, { 'pretty' => 1} );
print "EXPLICITLY PRETTY JSON:\n$jsonBack";


my $Fil = json::slurp_file("./x.json");
print "Fil:\n$Fil";
my $x = json::decode($Fil);
$jsonBack = json::encode($x);
print "JSONBACK:\n$jsonBack";
print "done.\n";
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
