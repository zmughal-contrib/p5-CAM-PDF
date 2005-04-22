#!/usr/bin/perl -w

use strict;
use Getopt::Long;
use Pod::Usage;

my %opts = (
            count      => 0,
            verbose    => 0,
            help       => 0,
            version    => 0,
            );

Getopt::Long::Configure("bundling");
GetOptions("c|count"      => \$opts{count},
           "v|verbose"    => \$opts{verbose},
           "h|help"       => \$opts{help},
           "V|version"    => \$opts{version},
           ) or pod2usage(1);
pod2usage(-exitstatus => 0, -verbose => 2) if ($opts{help});
require("CAM::PDF"),print("CAM::PDF v$CAM::PDF::VERSION\n"),exit(0) if ($opts{version});

if (@ARGV < 1)
{
   pod2usage(1);
}

my $infile = shift;
my $outfile = shift || "-";

local *IN;
local *OUT;

open(IN, $infile) or die "Failed to read file $infile\n";
my $content = join("", <IN>);
close(IN);

my @matches = ($content =~ /[\r\n]%%EOF *[\r\n]/sg);
my $revs = @matches;

if ($opts{count})
{
   print "$revs\n";
}
elsif ($revs < 1)
{
   die "Error: this does not seem to be a PDF document\n";
}
elsif ($revs == 1)
{
   die "Error: there is only one revision in this PDF document.  It cannot be reverted.\n";
}
else
{
   if ($outfile eq "-")
   {
      *OUT = *STDOUT;
   }
   else
   {
      open(OUT, ">$outfile") or die "Cannot write to $outfile\n";
   }

   # Figure out line end character
   $content =~ /(.)%%EOF.*?$/s;
   my $lineend = $1;
   
   my $i = rindex($content, "$lineend%%EOF");
   my $j = rindex($content, "$lineend%%EOF", $i-1);
   print OUT substr($content, 0, $j);
   print OUT $lineend . "%%EOF" . $lineend;
}


__END__

=head1 NAME

revertpdf.pl - Remove the last edits to a PDF document

=head1 SYNOPSIS

revertpdf.pl [options] infile.pdf [outfile.pdf]\n";

 Options:
   -c --count          just print the number of revisions and exits
   -v --verbose        print diagnostic messages
   -h --help           verbose help message
   -V --version        print CAM::PDF version

=head1 DESCRIPTION

PDF documents have the interesting feature that edits can be applied
just to the end of the file without altering the original content.
This makes it possible to recover previous versions of a document.
This is only possible if the editor writes out an 'unoptimized'
version of the PDF.

This program remove the last layer of edits from the PDF document.  If
there is just one revision, we emit a message and abort.

The --count option just prints the number of generations the document
has endured and applies no changes.

=head1 SEE ALSO

CAM::PDF

=head1 AUTHOR

Clotho Advanced Media Inc., I<cpan@clotho.com>
