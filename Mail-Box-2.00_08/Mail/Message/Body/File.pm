use strict;
use warnings;

package Mail::Message::Body::File;
use base 'Mail::Message::Body';

use Mail::Box::Parser;

our $VERSION = '2.00_08';

use Carp;
use IO::File;
use POSIX 'tmpnam';

=head1 NAME

 Mail::Message::Body::File - Mail::Message::Body temporarily stored in a file

=head1 CLASS HIERARCHY

 Mail::Message::Body::File
 is a Mail::Message::Body
 is a Mail::Reporter

=head1 SYNOPSIS

 See Mail::Message::Body

=head1 DESCRIPTION

READ C<Mail::Message::Body> FIRST. This manual-page only describes the
extensions to the default body functionality.

The body (content) of a message can be stored in various ways.  In this
documentation you find the description of extra functionality you have
when a message is stored in a file.

Storing a whole message is a file is useful when the body is large.  Although
access through a file is slower, it is saving a lot of memory.

=head1 METHOD INDEX

The general methods for C<Mail::Message::Body::File> objects:

  MMB clone                            MMB nrLines
  MMB data FILE | LIST-OF-LINES |...       print [FILE]
   MR errors                           MMB reply OPTIONS
  MMB file                              MR report [LEVEL]
  MMB isDelayed                         MR reportAll [LEVEL]
  MMB isMultipart                      MMB size
  MMB lines                            MMB string
   MR log [LEVEL [,STRINGS]]           MMB stripSignature OPTIONS
  MMB message [MESSAGE]                 MR trace [LEVEL]
  MMB new OPTIONS                       MR warnings

The extra methods for extension writers:

      DESTROY                           MR notImplemented
  MMB load                             MMB read PARSER, HEAD, BODYTYPE...
   MR logPriority LEVEL                MMB start
   MR logSettings                          tempFilename [FILENAME]

Methods prefixed with an abbreviation are described in the following
manual-pages:

   MR = L<Mail::Reporter>
  MMB = L<Mail::Message::Body>

=head1 METHODS

=over 4

=cut

#------------------------------------------

sub clone()
{   my $self  = shift;
    my $clone = ref($self)->new;

    copy($self->tempFilename, $clone->tempFilename)
       or return;

    $clone->{MMBF_nrlines} = $self->{MMBF_nrlines};
    $clone->{MMBF_size}    = $self->{MMBF_size};
    $self;
}

#------------------------------------------

sub string()
{   my $self = shift;

    my $file = $self->tempFilename;
    open IN, '<', $file
        or die "Cannot read from $file: $!\n";

    my $return = join '', <IN>;
    close IN;

    $return;
}

#------------------------------------------

sub lines()
{   my $self = shift;

    my $file = $self->tempFilename;
    open OUT, '<', $file
        or die "Cannot read from $file: $!\n";

    my @return = <OUT>;
    close OUT;

    $self->{MMBF_nrlines} = @return;
    wantarray ? @return : \@return;
}

#------------------------------------------

sub file() { IO::File->new(shift->tempFilename, 'r') }

#------------------------------------------

sub nrLines()
{   my $self    = shift;
    return $self->{MMBF_nrlines} if defined $self->{MMBF_nrlines};

    my $file    = $self->tempFilename;
    my $nrlines = 0;

    open IN, '<', $file
        or die "Cannot read from $file: $!\n";

    $nrlines++ while <IN>;
    close IN;

    $self->{MMBF_nrlines} = $nrlines;
}

#------------------------------------------

sub size()
{   my $self = shift;

      exists $self->{MMBF_size}
    ? $self->{MMBF_size}
    : ($self->{MMBF_size} = -s $self->tempFilename);
}

#------------------------------------------

=item print [FILE]

=cut

sub print(;$)
{   my $self = shift;
    my $fh   = shift || \*STDOUT;
    my $file = $self->tempFilename;

    open IN, '<', $file or croak "Cannot read from $file: $!\n";
    if(ref $fh eq 'GLOB') {print $fh while <IN>}
    else {$fh->print($_) while <IN>}
    close IN;

    $self;
}

#------------------------------------------

=back

=head1 METHODS for extension writers

=over 4

=cut

#------------------------------------------

sub data(@)
{   my $self = shift;
    delete $self->{MMBF_nrlines};
    delete $self->{MMBF_size};
    $self->SUPER::data(@_);
}

sub _data_from_file(@_)
{   my ($self, $fh) = @_;
    my $file    = $self->tempFilename;
    my $nrlines = 0;

    open OUT, '>', $file or die "Cannot write to $file: $!\n";

    if(ref $fh eq 'GLOB') { while(<$fh>) { print OUT; $nrlines++ }}
    else { while(my $l = $fh->getline) { print OUT $l; $nrlines++ }}

    close OUT;

    $self->{MMBF_nrlines} = $nrlines;
    $self;
}

sub _data_from_lines(@_)
{   my ($self, $lines)  = @_;
    my $file = $self->tempFilename;

    open OUT, '>', $file or die "Cannot write to $file: $!\n";
    print OUT @$lines;
    close OUT;

    $self->{MMBF_nrlines} = @$lines;
    $self;
}

#------------------------------------------

sub read($$$;@)
{   my ($self, $parser, $head, $bodytype) = splice @_, 0, 4;
    my $file = $self->tempFilename;

    open OUT, '>', $file
        or die "Cannot write to $file: $!.\n";

    @$self{ qw/MMB_where MMBF_nrlines/ } = $parser->bodyAsFile(\*OUT, @_);
    close OUT;

    $self;
}

#------------------------------------------

=item tempFilename [FILENAME]

Returns the name of the temporary file which is used to store this body.

=cut

sub tempFilename(;$)
{   my $self = shift;

      @_                     ? ($self->{MMBF_filename} = shift)
    : $self->{MMBF_filename} ? $self->{MMBF_filename}
    :                          ($self->{MMBF_filename} = tmpnam);
}

#------------------------------------------

=item DESTROY

The temporary file is automatically removed when the body is
not required anymore.

=cut

sub DESTROY { unlink shift->tempFilename }

#------------------------------------------

=back

=head1 SEE ALSO

L<Mail::Box-Overview>

=head1 AUTHOR

Mark Overmeer (F<mailbox@overmeer.net>).
All rights reserved.  This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=head1 VERSION

This code is beta, version 2.00_08.

Copyright (c) 2001 Mark Overmeer. All rights reserved.
This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
