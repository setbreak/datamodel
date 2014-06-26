use 5.010;
# use strict;

# DBI is the standard database interface for Perl
# DBD is the Perl module that we use to connect to the MySQL database
use DBI;
use DBD::mysql;

use LWP::Simple;                # From CPAN
use JSON qw( decode_json ); 
use Data::Dumper; 

use warnings;
 
 
 
say "Load event and recording tables";

my $getrows = 25;
# my $performer = "Ween";

# my $archiveurl    = "http://archive.org/advancedsearch.php?q=$performer&fl%5B%5D=avg_rating&fl%5B%5D=collection&fl%5B%5D=creator&fl%5B%5D=date&fl%5B%5D=description&fl%5B%5D=format&fl%5B%5D=headerImage&fl%5B%5D=identifier&fl%5B%5D=imagecount&fl%5B%5D=mediatype&fl%5B%5D=month&fl%5B%5D=oai_updatedate&fl%5B%5D=publicdate&fl%5B%5D=source&fl%5B%5D=subject&fl%5B%5D=title&fl%5B%5D=type&fl%5B%5D=volume&fl%5B%5D=week&fl%5B%5D=year&sort%5B%5D=&sort%5B%5D=&sort%5B%5D=&rows=" . $getrows . "&page=1&output=json#raw";



# 'get' is exported by LWP::Simple; install LWP from CPAN unless you have it.
# You need it or something similar (HTTP::Tiny, maybe?) to get web pages.
# my $json = get( $archiveurl );
# die "Could not get $archiveurl!" unless defined $json;

# This next line isn't Perl.  don't know what you're going for.
#my $decoded_json = @{decode_json{shares}};

# Decode the entire JSON
# $decoded_json = decode_json( $json );

# you'll get this (it'll print out); comment this when done.
# print Dumper $decoded_json;

# Access the shares like this:
# print "Shares: ",
#      $decoded_json->{'http://www.filestube.com'}{'shares'},
#     "\n";
# print "numFOund: ",
#       $decoded_json->{'response'}{'numFound'},
#      "\n";

#     foreach $event(@{$decoded_json->{'response'}{'docs'}}) {
#       # my %ep_hash = ();
#      print "Mediatype: ", $event->{'mediatype'}, "\n";
#      print "Identifier: ",  $event->{'identifier'}, "\n";
#      if ($event->{'mediatype'} eq 'etree') {
#            print "Type: ",  $event->{'type'}, "\n";
#      }
             
#    }




my $totals = 0;

my $mediasource_id = 1;

# invoke the ConnectToMySQL sub-routine to make the database connection
my $dbh = ConnectToMySql();


$query = "select archive_org_collection, id, name from performer";

# prepare your statement for connecting to the database
$statement = $dbh->prepare($query);

# execute your SQL statement
$statement->execute();

# we will loop through the returned results that are in the @data array
# even though, for this example, we will only be returning one row of data

while (@data = $statement->fetchrow_array()) {
  
  my $performer = $data[0];
  my $performer_id = $data[1];
  my $performer_name = $data[2];
  
  print "Performer : $performer_name \n";
      
  my $archiveurl    = "http://archive.org/advancedsearch.php?q=$performer&fl%5B%5D=avg_rating&fl%5B%5D=collection&fl%5B%5D=creator&fl%5B%5D=date&fl%5B%5D=description&fl%5B%5D=format&fl%5B%5D=headerImage&fl%5B%5D=identifier&fl%5B%5D=imagecount&fl%5B%5D=mediatype&fl%5B%5D=month&fl%5B%5D=oai_updatedate&fl%5B%5D=publicdate&fl%5B%5D=source&fl%5B%5D=subject&fl%5B%5D=title&fl%5B%5D=type&fl%5B%5D=volume&fl%5B%5D=week&fl%5B%5D=year&sort%5B%5D=&sort%5B%5D=&sort%5B%5D=&rows=$getrows&page=1&output=json#raw";
      
  # 'get' is exported by LWP::Simple; install LWP from CPAN unless you have it.
  # You need it or something similar (HTTP::Tiny, maybe?) to get web pages.
  my $json = get( $archiveurl );
  die "Could not get $archiveurl!" unless defined $json;

  # Decode the entire JSON
  $decoded_json = decode_json( $json );            
   
  print "Retrieved and decoded response, len = " . length($json) . "\n"; 
      
  foreach $event(@{$decoded_json->{'response'}{'docs'}}) {
    print ".";
    if ($event->{'mediatype'} eq 'collection') {
      if ($event->{'headerImage'} && $event->{'headerImage'} ne "" && $event->{'title'} eq $performer_name) { 
        my $sth0 = $dbh->prepare("UPDATE performer
                            SET default_image_path = ?
                            WHERE id = ?");
               
  $sth0->execute( $event->{'headerImage'} , $performer_id) 
      or die $DBI::errstr;
  $sth0->finish();
    
    print "\n>>>> ", $performer_name, ":", $event->{'headerImage'} , "\n";
  }
    
    } elsif  ($event->{'mediatype'} eq 'etree') {
      
          # my %ep_hash = ();
  #  print "Mediatype: ", $event->{'mediatype'}, "\n";
  #   print "Identifier: ",  $event->{'identifier'}, "\n";
  
  #     print "Type: ",  $event->{'type'}, "\n";
  #     print "Date: ",  $event->{'date'}, "\n";
  #     print "PublicDate: ",  $event->{'publicdate'}, "\n";
  #     print "Title: ",  $event->{'title'}, "\n";
  #     print "Source: ",  $event->{'source'}, "\n";
  #     print "Description: ",  $event->{'description'}, "\n";
  
  
  my $query1 =  $dbh->prepare("select id, title from event where title = ?");


  # execute your SQL statement
  $query1->execute($event->{'title'});
  
  my $event_exists;
  my $event_id;
  my $event_title;
  my $last_id;
  
  $event_exists = 0;
  
  while (@data = $query1->fetchrow_array()) {
    $event_exists = 1;
    $event_id = $data[0];
    $event_title = $data[1];
  }
  
  if ($event_exists) {
  
    $last_id = $event_id;  
    print "\nFOUND AN EXISTING EVENT : $event_title\n"; 
  
  } else {
  
  
      my $sth1 = $dbh->prepare("INSERT INTO event
                       (performer_id, performer_name, title, event_date)
                        values
                       (?, ?, ?, ?)");
      $sth1->execute($performer_id, $performer_name, $event->{'title'},  $event->{'date'}) 
          or die $DBI::errstr;
      $sth1->finish();
      
      $last_id = $dbh->{mysql_insertid};
      
  }
      
      my $sound_type;
      
      my $tsource;
      
      $tsource = "";
       
      $tsource = $event->{'source'};
      
      $sound_type = 'un';
      
      if ((index($tsource, 'SBD') != -1) || (index($tsource, 'sdb') != -1) || (index($tsource, 'Soundboard') != -1) || (index($tsource, 'soundboard') != -1)) {
          $sound_type = 'sb';    
      
      } elsif ((index($tsource, 'AUD') != -1) || (index($tsource, 'aud') != -1) || (index($tsource, 'Audience') != -1) || (index($tsource, 'audience') != -1)) {
         $sound_type = 'au';
      }  
      
      # print "Last ID is : $last_id\n";
      
      my $sth2 = $dbh->prepare("INSERT INTO recording
                       (performer_id, performer_name, title, mediasource_id, event_id, external_identifier, show_source, description, recorded_date, published_date, average_rating, recording_type )
                        values
                       (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");
      $sth2->execute($performer_id, $performer_name, $event->{'title'}, $mediasource_id, $last_id, $event->{'identifier'}, $event->{'source'}, $event->{'description'},  $event->{'date'}, $event->{'publicdate'}, $event->{'avg_rating'}, $sound_type) 
          or die $DBI::errstr;
      $sth2->finish();
      
      
      
      $totals++;
    }
             
  } # foreach recording in JSON response   
  print "\n"; 

} # while each perform

print "loaded in tables: $totals";


# exit the script
exit;

#--- start sub-routine ------------------------------------------------
sub ConnectToMySql {
#----------------------------------------------------------------------

my ($db) = @_;


# assign the values in the accessDB file to the variables
my $database = "setbreak2";
my $host = "localhost";
my $userid = "root";
my $passwd = "";

# assign the values to your connection variable
my $connectionInfo="dbi:mysql:$database;$host";

# close the accessDB file
# close(ACCESS_INFO);

# the chomp() function will remove any newline character from the end of a string
chomp ($database, $host, $userid, $passwd);

# make connection to database
my $l_connection = DBI->connect($connectionInfo,$userid,$passwd);

# the value of this connection is returned by the sub-routine
return $l_connection;

}

#--- end sub-routine ----------------