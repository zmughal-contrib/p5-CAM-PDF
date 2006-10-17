package CAM::PDF::Renderer::Text;

use 5.006;
use warnings;
use strict;
use CAM::PDF::Renderer::TextFB;
use base qw(CAM::PDF::GS);

our $VERSION = '1.08';

=for stopwords framebuffer

=head1 NAME

CAM::PDF::Renderer::Text - Render an ASCII image of a PDF page

=head1 LICENSE

See CAM::PDF.

=head1 SYNOPSIS

    use CAM::PDF;
    my $pdf = CAM::PDF->new($filename);
    my $contentTree = $pdf->getPageContentTree(4);
    $contentTree->render("CAM::PDF::Renderer::Text");

=head1 DESCRIPTION

This class is used to print to STDOUT the coordinates of each node of
a page layout.  It is written both for debugging and as a minimal
example of a renderer.

=head1 GLOBALS

The $CAM::PDF::Renderer::Text::xdensity and
$CAM::PDF::Renderer::Text::ydensity define the scale of the ASCII
graphical output device.  They both default to 6.0.

=cut

our $xdensity = 6.0;
our $ydensity = 6.0;

=head1 FUNCTIONS

=over

=item $pkg->new()

Calls the superclass constructor, and initializes the ASCII PDF page.

=cut

sub new
{
   my $pkg = shift;

   my $self = $pkg->SUPER::new(@_);
   if ($self)
   {
      my $fw = ($self->{refs}->{mediabox}->[2] - $self->{refs}->{mediabox}->[0]) / $xdensity;
      my $fh = ($self->{refs}->{mediabox}->[3] - $self->{refs}->{mediabox}->[1]) / $ydensity;
      my $w = int $fw;
      my $h = int $fh;
      $self->{refs}->{framebuffer} = CAM::PDF::Renderer::TextFB->new($w, $h);
      $self->{mode} = 'c';
   }
   return $self;
}

=item $self->renderText($string)

Prints the characters of the screen to our virtual ASCII framebuffer.

=cut

sub renderText
{
   my $self = shift;
   my $string = shift;

   my ($x, $y) = $self->textToDevice(0,0);
   $x = int $x / $xdensity;
   $y = int $y / $ydensity;

   $self->{refs}->{framebuffer}->add_string($x, $y, $string);
   #print "($x,$y) $string\n";
   return;
}

1;
__END__

=back

=head1 AUTHOR

Clotho Advanced Media Inc., I<cpan@clotho.com>

=cut
