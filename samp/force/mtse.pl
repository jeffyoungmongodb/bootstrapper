#!/usr/bin/env perl
use strict;



sub util::stdout($);

$main::DEBUG = 0;

die "Cannot use JSON, try as root : 'cpan install json'"
  unless json::can_use();

die "Cannot use force cli, Please visit https://force-cli.heroku.com/ and install it"
  unless force_cli::can_use();

my $commandLineOpts = mtse::get_command_line();

json::print($commandLineOpts, 'CMDLINE');
  
force_cli::login()
  unless force_cli::is_logged_in();

my $mtseConf = mtse::load_config($commandLineOpts);

my $cache = mtse::load_cache($mtseConf);
mtse::summarize_tse_data($cache);

json::print($cache, 'CACHE');


mtse::print_summary_report($cache);




exit(0);

#use DateTime; my $dt = DateTime->now; my $x = $dt->iso8601(); print "X: $x\n";
#######

package util;

sub util::stdout($)
{ 
  my $x = shift;
  print "mtse: $x\n"; 
}

sub util::debug($)
{
  my $x = shift;
  print "mtse-debug: $x\n"; 
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

  print "JSON: \n{{\n$json\n}}\n" if $main::DEBUG;
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

  my $tries = 2;

  while ($tries--)
  {

    my ($ex,$rc,$ret) = force_cli::exec("query \"$q\" --format:json");
    if ($ret =~ /^ERROR/)
    {
      util::stdout "retrying... after force cli error ($ret)";
      next;
    }

    my $d = json::decode($ret);

    return $d;
  }

  return undef;
}

####

package mtse;

sub mtse::get_command_line
{
  use Getopt::Long;
  my $commandLineOpts = {};
  my $ret = GetOptions($commandLineOpts, 
                        'debug+',
                        'tse=s@'
                      );
  util::debug("GetOptions ret=$ret");
  die "Invalid commandline instructions" unless (1==$ret);

  return $commandLineOpts;
}

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
  my $cmdLine = shift;
  my $dir = mtse::ensure_dir();

  my $fil = "$dir/mtse_conf.json";

  die "$fil does not exist, create one '\n{\n  \"tses\" : \n  {  \"First Last\" : {}\n  }\n}\n'" 
    unless -f $fil;

  my $ds = json::load_file($fil);

  if (defined $cmdLine)
  {
  }


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


sub mtse::get_case_select_clause
{
  my $str = 'Select Case.OwnerId,Case.Status,Case.CaseNumber,Case.LastModifiedDate,Id,Subject,AccountId,CreatedDate,ClosedDate,Comment_Count__c,Components__c,Project__c,Owner__c from Case';
  return $str;
}

sub mtse::get_tse_data
{
  my ($nm,$id) = @_;

  my $data = {};
  $data ->{Name} = $nm;

  my $sel = get_case_select_clause();

  my 
  $soql = "$sel WHere Case.OwnerId = '$id'";
 
  util::stdout "querying cases for $nm";
  my $CaseList = force_cli::query($soql);
  $data->{CaseList} = $CaseList;

  $soql = "Select CreatedDate,Is_Published__c,Case__c,Id,CreatedById,Created_By_Name__c,Is_FTS_Comment__c,Name from Case_Comment__c where CreatedById = '$id' order by CreatedDate DESC" ;
  util::stdout "querying comments for $nm";
  my $CommentList = force_cli::query($soql);
  $data->{CommentList}  = $CommentList;

  $soql = "SELECT Id, CreatedDate, OwnerId, Markdown_Text__c FROM Review_Comment__c where OwnerId = '$id' ORDER BY CreatedDate DESC";

  util::stdout "querying reviews by $nm";
  my $ReviewList = force_cli::query($soql);
  $data->{ReviewList} = $ReviewList;


  return $data;

}



sub mtse::is_closed_status
{
  my $val = shift;

  return 1 if $val eq 'Resolved';
  return 1 if $val eq 'Closed';
  return 0 ;
}


sub mtse::print_summary_report
{
  my $cache = shift;


  print "BEGIN TSE SUMMARY REPORT.\n";

  while (my ($k,$v) = each %{$cache->{tses}})
  {
    print "TSE: $k TotalCases=$v->{Summary}->{CaseCount}, TotalComments=$v->{Summary}->{CommentCount} \n";
    print "  Open Cases:\n";
    foreach my $x (@{$v->{Summary}->{OpenCases}}) { print "    $x\n"; }  
    print "  Latest Comments:\n";
    foreach my $y (@{$v->{Summary}->{LatestComments}}) { print "    $y\n"; }  

    print "\n";
  }


  print "END TSE SUMMARY REPORT.\n";
}

sub mtse::summarize_tse_data
{
  my $cache = shift;


  while (my ($k,$v) = each %{$cache->{tses}})
  {

    my $CaseHash = {};

    my $caseList = $v->{Data}->{CaseList};
    my $commentList = $v->{Data}->{CommentList};
    my $reviewList = $v->{Data}->{ReviewList};

    my $case_cnt = 0;
    my $comment_cnt = 0;
    my $review_cnt = 0;


    foreach my $case (sort { $a->{LastModifiedDate} cmp $b->{LastModifiedDate} } (@$caseList)) 
    { 
      $case_cnt++; 
      if ( ! mtse::is_closed_status($case->{Status})) 
      {
        $v->{Summary}->{OpenCases} = [] unless defined $v->{Summary}->{OpenCases};
        push(@{$v->{Summary}->{OpenCases}}, "$case->{CaseNumber} : $case->{Status} : $case->{Subject} : $case->{LastModifiedDate}");
        $CaseHash->{$case->{Id}} = $case;
      }

    }   
   

     
    foreach my $comment (@$commentList) 
    { 
      $comment_cnt++; 
        
      $v->{Summary}->{LatestComments} = [] unless defined $v->{Summary}->{LatestComments};
     

      if ($comment_cnt < 10)
      {
        my $case = $CaseHash->{$comment->{'Case__c'}};
        if (! defined $case)
        {
          my $sel  = mtse::get_case_select_clause();
          my $soql = "$sel Where Id = '$comment->{'Case__c'}'";

          my $retrvCase = force_cli::query($soql);
          $case = pop (@{$retrvCase});
        }

        my $str = "$case->{CaseNumber} : $comment->{Name} : $comment->{CreatedDate} : $case->{Subject}";

        push(@{$v->{Summary}->{LatestComments}},$str)
          unless $comment_cnt > 10;
      }
      
    }   

    foreach my $review (@$reviewList) 
    { 
      $review_cnt++; 
      $v->{Summary}->{LatestReviews} = [] unless defined $v->{Summary}->{LatestReviews};
    }

    $v->{Summary}->{CaseCount} = $case_cnt; 
    $v->{Summary}->{CommentCount} = $comment_cnt; 
    $v->{Summary}->{ReviewCount} = $review_cnt; 

  }
  
}




