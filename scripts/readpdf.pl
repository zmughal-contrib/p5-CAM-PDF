#!/usr/bin/perl -w

use strict;
use CAM::PDF;
use Getopt::Long;
use Pod::Usage;

my %opts = (
            verbose    => 0,
            decode     => 0,
            askforpass => 0,
            help       => 0,
            version    => 0,
            );

Getopt::Long::Configure("bundling");
GetOptions("v|verbose"  => \$opts{verbose},
           "d|decode"   => \$opts{decode},
           "p|pass"     => \$opts{askforpass},
           "h|help"     => \$opts{help},
           "V|version"  => \$opts{version},
           ) or pod2usage(1);
pod2usage(-exitstatus => 0, -verbose => 2) if ($opts{help});
print("CAM::PDF v$CAM::PDF::VERSION\n"),exit(0) if ($opts{version});

if (@ARGV < 1)
{
   pod2usage(1);
}

my $file = shift || "-";
my $doc = CAM::PDF->new($file, "", "", $opts{askforpass});
die "$CAM::PDF::errstr\n" if (!$doc);

if ($opts{decode})
{
   foreach my $obj (keys %{$doc->{xref}})
   {
      $doc->decodeObject($obj);
   }
}
if ($opts{verbose})
{
   $doc->cacheObjects(); # to force parsing of whole file
   print $doc->toString();
}

__END__

=head1 NAME

readpdf.pl - Read a PDF document

=head1 SYNOPSIS

readpdf.pl [options] file.pdf

 Options:
   -d --decode         uncompress internal PDF components
   -p --pass           prompt for a user password if needed
   -v --verbose        print the internal representation of the PDF
   -h --help           verbose help message
   -V --version        print CAM::PDF version

=head1 DESCRIPTION

Read a PDF document into memory and, optionally, output it's internal
representation.  This is primarily useful for debugging, but it can
also be a way to validate a PDF document.

=head1 SEE ALSO

CAM::PDF

rewritepdf.pl

=head1 AUTHOR

Clotho Advanced Media Inc., I<cpan@clotho.com>
