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
 
 
 
say "Load song table";


# my $performer = "Ween";

# my $archiveurl    = "http://archive.org/advancedsearch.php?q=$performer&fl%5B%5D=avg_rating&fl%5B%5D=collection&fl%5B%5D=creator&fl%5B%5D=date&fl%5B%5D=description&fl%5B%5D=format&fl%5B%5D=headerImage&fl%5B%5D=identifier&fl%5B%5D=imagecount&fl%5B%5D=mediatype&fl%5B%5D=month&fl%5B%5D=oai_updatedate&fl%5B%5D=publicdate&fl%5B%5D=source&fl%5B%5D=subject&fl%5B%5D=title&fl%5B%5D=type&fl%5B%5D=volume&fl%5B%5D=week&fl%5B%5D=year&sort%5B%5D=&sort%5B%5D=&sort%5B%5D=&rows=50&page=1&output=json#raw";



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


$query = "select id, external_identifier from recording";

# prepare your statement for connecting to the database
$statement = $dbh->prepare($query);

# execute your SQL statement
$statement->execute();

# we will loop through the returned results that are in the @data array
# even though, for this example, we will only be returning one row of data

while (@data = $statement->fetchrow_array()) {
  
  
  my $recording_id = $data[0];
  my $identifier = $data[1];
  
  print "Identifier : $identifier \n";
      
  # my $archiveurl    = "http://archive.org/advancedsearch.php?q=$performer&fl%5B%5D=avg_rating&fl%5B%5D=collection&fl%5B%5D=creator&fl%5B%5D=date&fl%5B%5D=description&fl%5B%5D=format&fl%5B%5D=headerImage&fl%5B%5D=identifier&fl%5B%5D=imagecount&fl%5B%5D=mediatype&fl%5B%5D=month&fl%5B%5D=oai_updatedate&fl%5B%5D=publicdate&fl%5B%5D=source&fl%5B%5D=subject&fl%5B%5D=title&fl%5B%5D=type&fl%5B%5D=volume&fl%5B%5D=week&fl%5B%5D=year&sort%5B%5D=&sort%5B%5D=&sort%5B%5D=&rows=99&page=1&output=json#raw";
  
  my $archiveurl = "http://archive.org/details/$identifier?output=json#raw";
      
  # 'get' is exported by LWP::Simple; install LWP from CPAN unless you have it.
  # You need it or something similar (HTTP::Tiny, maybe?) to get web pages.
  my $json = get( $archiveurl );
  die "Could not get $archiveurl!" unless defined $json;

  # Decode the entire JSON
  $decoded_json = decode_json( $json );            
  
  # print Dumper $decoded_json;
  
  # print "ITS:   $decoded_json->{'server'}    $decoded_json->{'dir'}  \n";
  
  my $sth0 = $dbh->prepare("UPDATE recording
                            SET external_recording_path = ?, lineage = ?, recorded_by = ?, venue = ?, location = ?, notes = ?, default_image_path = ?, downloads = ?
                            WHERE id = ?");
               
  $sth0->execute( $decoded_json->{'server'} .  $decoded_json->{'dir'}, $decoded_json->{'metadata'}->{'lineage'}[0] , $decoded_json->{'metadata'}->{'taper'}[0], $decoded_json->{'metadata'}->{'venue'}[0], $decoded_json->{'metadata'}->{'coverage'}[0], $decoded_json->{'metadata'}->{'notes'}[0], $decoded_json->{'misc'}->{'header_image'}, $decoded_json->{'item'}->{'downloads'},$recording_id) 
      or die $DBI::errstr;
  $sth0->finish();
  
  
  my %songfiles = %{$decoded_json->{'files'}};
      
  # print "%songfiles\n";    
      
      
  # foreach @songfiles(@{$decoded_json->{'files'}}) {
  # foreach (@songfiles) {
    foreach my $key ( keys %songfiles) {
    # my %ep_hash = ();
  #  print "Mediatype: ", $event->{'mediatype'}, "\n";
  #   print "Identifier: ",  $event->{'identifier'}, "\n";
  
  print "Key is : $key \n";  
    
  # print  ": $songfiles{$key}->{'format'}";
  
  if ($songfiles{$key}->{'format'} eq 'VBR MP3') {
     # print  ": $songfiles{$key}->{'length'}";
     # print  ": $songfiles{$key}->{'bitrate'}";
     # print  ": $songfiles{$key}->{'size'}";
     # print  ": $songfiles{$key}->{'album'}";
     # print  ": $songfiles{$key}->{'title'}";
     # print  ": $songfiles{$key}->{'track'}";
     
     # print "\n";  
  
    
     # my $sth = $dbh->prepare("INSERT INTO song
     #              (performer_id, performer_name, title)
     #                    values
     #                   (?, ?, ?)");
      # $sth->execute($performer_id, $performer_name, $event->{'title'}) 
      #     or die $DBI::errstr;
      # $sth->finish();
      
      # my $last_id = $dbh->{mysql_insertid};
      
      # print "Last ID is : $last_id\n";
      
      my $sth1 = $dbh->prepare("INSERT INTO song
                        (recording_id, title, song_order, album, length_time)
                         values
                        (?, ?, ?, ?, ?)");
      $sth1->execute($recording_id, $songfiles{$key}->{'title'},$songfiles{$key}->{'track'}, $songfiles{$key}->{'album'}, "00:" . $songfiles{$key}->{'length'}) 
        or die $DBI::errstr;
      $sth1->finish();
      
      my $last_id = $dbh->{mysql_insertid};
      
      my $sth2 = $dbh->prepare("INSERT INTO songpath
                        (song_id, path, recording_format, bitrate, size)
                         values
                        (?, ?, ?, ?, ?)");
      $sth2->execute($last_id, $key, $songfiles{$key}->{'format'},$songfiles{$key}->{'bitrate'},$songfiles{$key}->{'size'}) 
        or die $DBI::errstr;
      $sth2->finish();
      
      
      
      $totals++;
  } #if
             
  } # foreach recording in JSON response   

  sleep(6);

} # while each perform

print "loaded in table: $totals";


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
#--- end sub-routine ----------------