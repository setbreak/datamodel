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
 
 
 
say "Load performer table";

# invoke the ConnectToMySQL sub-routine to make the database connection
$dbh = ConnectToMySql();

my $filename = 'performer.txt';
# if (open(my $fh, '<:encoding(UTF-8)', $filename)) {
if (open(my $fh, $filename)) {
  while (my $row = <$fh>) {
    chomp $row;
    print "$row\n";
    my ($it1, $it2, $it3, $it4) = split/,/, $row;
    $it1 =~ s/\W//g;
    print "$it1:$it3:\n"; 
    my $sth = $dbh->prepare("INSERT INTO performer
                       (archive_org_collection, name)
                        values
                       (?,?)");
    $sth->execute($it1,$it3) 
          or die $DBI::errstr;
    $sth->finish();
    # $dbh->commit or die $DBI::errstr;
  }
} else {
  warn "Could not open file '$filename' $!";
}

dbh->disconnect;





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