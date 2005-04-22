#!/usr/bin/perl -w

use strict;
use CAM::PDF;
use Getopt::Long;
use Pod::Usage;

my %opts = (
            template   => "crunchjpg_tmpl.pdf",

            verbose    => 0,
            help       => 0,
            version    => 0,
            skip       => {},

            # Temporary values:
            skipval    => [],
            );

Getopt::Long::Configure("bundling");
GetOptions("S|skip=s"     => \@{$opts{skipval}},
           "v|verbose"  => \$opts{verbose},
           "h|help"     => \$opts{help},
           "V|version"  => \$opts{version},
           ) or pod2usage(1);
pod2usage(-exitstatus => 0, -verbose => 2) if ($opts{help});
print("CAM::PDF v$CAM::PDF::VERSION\n"),exit(0) if ($opts{version});

foreach my $flag (qw( skip ))
{
   foreach my $val (@{$opts{$flag."val"}})
   {
      foreach my $key (split /\D+/, $val)
      {
         $opts{$flag}->{$key} = 1;
      }
   }
}
if (!-f $opts{template})
{
   die "Cannot find the template pdf called $opts{template}\n";
}

if (@ARGV < 2)
{
   pod2usage(1);
}

my $infile = shift;
my $outdir = shift;

my $doc = CAM::PDF->new($infile);
die "$CAM::PDF::errstr\n" if (!$doc);

my $pages = $doc->numPages();
my $nimages = 0;
my $rimages = 0;
my %doneobjs = ();

for (my $p=1; $p <= $pages; $p++)
{
   my $c = $doc->getPageContent($p);
   my @parts = split /(\/[\w]+\s*Do)\b/s, $c;
   foreach my $part (@parts)
   {
      if ($part =~ /^(\/[\w]+)\s*Do$/s)
      {
         my $ref = $1;
         my $xobj = $doc->dereference($ref, $p);
         my $objnum = $xobj->{objnum};
         my $im = $doc->getValue($xobj);
         my $w = $im->{Width} || $im->{W} || 0;
         $w = $doc->getValue($w) if ($w);
         my $h = $im->{Height} || $im->{H} || 0;
         $h = $doc->getValue($h) if ($h);

         next if (exists $doneobjs{$objnum});

         $nimages++;
         print STDERR "Image $nimages page $p, $ref = object $objnum, (w,h)=($w,$h)\n" if ($opts{verbose});

         if (exists $opts{skip}->{$objnum})
         {
            print STDERR "Skipping object $objnum\n" if ($opts{verbose});
            next;
         }

         my $isjpg = 0;
         if ($im->{Filter})
         {
            my $f = $im->{Filter};
            if ($f->{type} eq "array")
            {
               foreach my $e (@{$f->{value}})
               {
                  my $name = $doc->getValue($e);
                  $name = $name->{value} if (ref $name);
                  #warn "Checking $name\n";
                  if ($name eq "DCTDecode")
                  {
                     $isjpg = 1;
                     last;
                  }
               }
            }
            else
            {
               my $name = $doc->getValue($f);
               $name = $name->{value} if (ref $name);
               #warn "Checking $name\n";
               if ($name eq "DCTDecode")
               {
                  $isjpg = 1;
               }
            }
         }

         if (!$isjpg)
         {
            print STDERR "Not a jpeg\n" if ($opts{verbose});
         }
         else
         {
            my $oldsize = $doc->getValue($im->{Length});
            if (!$oldsize)
            {
               die "PDF error: Failed to get size of image\n";
            }

            my $tmpl = CAM::PDF->new($opts{template});
            die "$CAM::PDF::errstr\n" if (!$tmpl);
            
            # Get a handle on the needed data bits from the template
            my $media_array = $tmpl->getValue($tmpl->getPage(1)->{MediaBox});
            my $rawpage = $tmpl->getPageContent(1);
            
            $media_array->[2]->{value} = $w;
            $media_array->[3]->{value} = $h;
            my $page = $rawpage;
            $page =~ s/xxx/$w/ig;
            $page =~ s/yyy/$h/ig;
            $tmpl->setPageContent(1, $page);
            $tmpl->replaceObject(9, $doc, $objnum, 1);

            my $ofile = "/tmp/crunchjpg.$$";
            $tmpl->cleanoutput($ofile);

            if (!-d $outdir)
            {
               `mkdir -p $outdir`;
            }
            `convert -quality 50 -density 72x72 -page ${w}x$h pdf:$ofile jpg:$outdir/$objnum.jpg`;

            $doneobjs{$objnum} = 1;
            $rimages++;
         }
      }
   }
}

print STDERR "Extracted $rimages of $nimages images\n" if ($opts{verbose});


__END__

=head1 NAME

extractjpgs.pl - Save copies of all PDF JPG images to a directory

=head1 SYNOPSIS

extractjpgs.pl [options] infile.pdf outdirectory

 Options:
   -S --skip=imnum     don't output the specified images (can be used mutliple times)
   -v --verbose        print diagnostic messages
   -h --help           verbose help message
   -V --version        print CAM::PDF version

C<imnum> is a comma-separated list of integers indicating the images
in order that they appear in the PDF.  Use listimages.pl to retrieve
the image numbers.

=head1 DESCRIPTION

Requires the ImageMagick C<convert> program to be available

Searches the PDF for JPG images and saves them as individual files in the
specified directory.  The files are named <imnum>.jpg.

=head1 SEE ALSO

CAM::PDF

crunchjpgs.pl

listimages.pl

extractallimages.pl

uninlinepdfimages.pl

=head1 AUTHOR

Clotho Advanced Media Inc., I<cpan@clotho.com>