#!/usr/bin/env perl

my $DEBUG = 0;

my $VAL = $ARGV[0];

die "Please provide a number to find the square root for." 
  unless defined $VAL;
die "Please provide a positive number"
  unless $VAL > 0.0;

my $x = square_root($VAL);
my $y = sqr_rt($VAL);
my $z = sqrt($VAL);
print "sqrt: iteratively computed=$x,recursively computed=$z,  perl runtime=$z\n";

exit(0);
# 

sub sqr_rt
{
  my ($val,$hi,$lo) = @_;

  my $MARGIN = 0.000000001;
  if (!defined $hi ) { $hi = $val; $hi = 1 if ($val < 1); }
  if (!defined $lo ) { $lo = 0; $lo = 1 if ($val >=1); }

  my $guess = ($hi + $lo )/ 2;
  my   $chk = $guess * $guess;
  if ( abs($chk - $val) <= $MARGIN ) { return sprintf("%.8f",$guess); }
  if ( $chk > $val ) { $hi = $guess; }
  else { $lo = $guess; }
  return sqr_rt($val,$hi,$lo);
}

sub square_root
{
  my $val = shift;

  my $MARGIN = 0.000000001;

  my $hi = $val; $hi = 1 if ($val < 1);
  my $lo = 0; $lo = 1 if ($val >=1);

  my $guess = -1;
  my $chk = -1;

  while (1)
  {
    $guess = ($hi + $lo )/ 2;
    $chk = $guess * $guess;
    if ( abs($chk - $val) <= $MARGIN ) { return sprintf("%.8f",$guess); }
    if ( $chk > $val )  { $hi = $guess; }
    else                { $lo = $guess; }
  } 

}

