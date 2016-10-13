#!/usr/bin/env perl

for (my $i = 1;$i<=100;$i++)
{
  ($i % 15 == 0 ? print "FizzBuzz\n" :
    $i % 3 == 0 ? print "Fizz\n" :
    $i % 5 == 0 ? print "Buzz\n" :
                  print "$i\n" );
 
}
exit(0);
print "XXX\n";
for (my $i = 1;$i<=100;$i++)
{
  if    ($i % 15 == 0){print "FizzBuzz\n"}
  elsif ($i % 3 == 0) {print "Fizz\n";}
  elsif ($i % 5 == 0) {print "Buzz\n";}
  else                {print "$i\n";}
}


