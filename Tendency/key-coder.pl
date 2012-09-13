#!/usr/bin/perl
use strict;
use Getopt::Long;

my $_SQUARE = 0; # 0 is don't output as square
my $_AUTO_SQUARE = 0; # should we find the smallest fitting square?
my $_TEXT = ""; # the text to encode

GetOptions(
    "square=i" => \$_SQUARE
	,	"auto-square" => \$_AUTO_SQUARE
  , "text=s" => \$_TEXT
);


################################################################################
# Usage message and valid params
################################################################################

if( $_TEXT eq "" ){
  die "usage: $0 [-square dim] -text \"text to encode\"\n";
}
if( $_SQUARE < 0 ){
  die "Error: The dimension of the output square must be positive.\n";
}


################################################################################
# Set up the encoding Char -> Int table
################################################################################

my @_KEY = qw(0 1 2 3 4 5 6 7 8 9 a b c d e f g h i j k l m n o p q r s t u v w x y z - #);
my %_ENC_TABLE = ();

#converts an int to a (3bit,3bit) dword
sub getDoubleWord{
  my( $i ) = @_;
  $i = $i & 0x3f; #save only the low 6 bits;
  return [$i >> 3, $i & 7];
}

{
  my $i = 0;
  for my $key (@_KEY){
    $_ENC_TABLE{$key} = getDoubleWord($i);
    $i ++;
  }
	$_ENC_TABLE{" "} = getDoubleWord(0xFE);
  $_ENC_TABLE{"null"} = getDoubleWord(-1); # we are dealing with 3 bit double words and null is 111111
}

sub encode {
  my( $char ) = @_;
  if( not exists $_ENC_TABLE{$char} ){
    die "Error: '$char' does not have a valid encoding.\n";
  }
  return $_ENC_TABLE{$char};
}

#flattens an array of arrays
sub flatten{
  my @encoding = @_;
  my @flat = ();
  for my $e (@encoding){
    @flat = (@flat, @$e);
  }
  return @flat;
}


################################################################################
# Main
################################################################################

my @chars = map(lc, split('', $_TEXT)); #string -> [lower case chars]
my @encoding = map {encode($_)} @chars; #encode each element of $chars

#handle auto square
if( $_AUTO_SQUARE ){
	$_SQUARE = 1;
	while( $_SQUARE*$_SQUARE < 2*@encoding ){
		$_SQUARE++;
	}
}

# just print serially by default
if( $_SQUARE == 0 ){
  for my $dword (@encoding){
    print "($dword->[0], $dword->[1])\n";
  }
}

#print in an $_SQUAREx$_SQUARE grid
elsif( $_SQUARE*$_SQUARE >= 2*@encoding ){
  my @flat = flatten(@encoding);
  #append null encodings to the end of the flattened list
  @flat = (@flat, (flatten(encode("null")))x(($_SQUARE*$_SQUARE - (2*@encoding) + 1)/2));

  #print the square
  for my $y (0..$_SQUARE-1){
    print "-"x(4*$_SQUARE+1), "\n";
    for my $x (0..$_SQUARE-1){
      print "| ", $flat[$x+$y*$_SQUARE], " ";
    }
    print "|\n";
  }
  print "-"x(4*$_SQUARE+1), "\n";
}

#Square is not big enough
else{
  die "Error: The given square dimensions are not large enough to contain the encoded text.\n";
}

