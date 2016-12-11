#!/usr/bin/env perl
use strict;

die "Cannot use JSON, try as root : cpan install json"
  unless json::can_use();

my $x = force_cli::can_use();

print "X $x can_use Force\n";




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

sub force_cli::can_use
{
  my $tst = `force version` ;
  print "$tst\n";
  
}

