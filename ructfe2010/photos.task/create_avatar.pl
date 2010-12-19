#!/usr/bin/perl

use GD;

$filename = shift @ARGV || die "USAGE: $0 <filename>";
$SIZE = 128;

# Create new image with TrueColor
$im = new GD::Image($SIZE, $SIZE, 1);
$im->interlaced('true');

$n = 0;
while (<>)
{
  @str = split /\s+/;
  for (0..$SIZE - 1)
  {
    $r = int(7 * rand) % 7 + 1;
    $color = $im->colorAllocate($r & 1 ? $str[$_] : 0, $r & 2 ? $str[$_] : 0, $r & 4 ? $str[$_] : 0);
    $im->setPixel($n, $_, $color);
  }
  ++$n;
}

# Open file to write
open(PICTURE, '>'.$filename) or die("Cannot open file for writing");
binmode PICTURE;
print PICTURE $im->png;
close PICTURE;