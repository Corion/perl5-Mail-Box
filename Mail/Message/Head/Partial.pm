
use strict;

package Mail::Message::Head::Partial;
use base 'Mail::Message::Head::Complete';

use Scalar::Util 'weaken';

=chapter NAME

Mail::Message::Head::Partial - subset of header information of a message

=chapter SYNOPSIS

 my $partial = $head->strip;
 $partial->isa('M<Mail::Message::Head>')  # true
 $partial->isDelayed                      # false
 $partial->isPartial                      # true

=chapter DESCRIPTION

Header information consumes a considerable amount of memory.  Most of this
information is only useful during a short period of time in your program,
or sometimes it is not used at all.  You then can decide to remove most
of the header information.  However, be warned that it will be lost
permanently: the header (and therefore the messsage) gets mutulated!

=chapter METHODS

=section Access to the header

=method removeFields STRING|REGEXP, [STRING|REGEXP, ...]

Remove the fields from the header which are exactly named 'STRING' (case
insensitive) or match the REGular EXPresssion.  Do not forget to add the
'i' modifier to the REGEXP, because fields are case insensitive.

See also M<removeField()> which is used to remove one field object from
the header.  The reverse specification can be made with
C<removeFieldsExcept()>.

=examples

 $head->removeFields('bcc', 'received');
 $head->removeFields( qr/^content-/i );

=cut

sub removeFields(@)
{   my $self  = shift;
    my $known = $self->{MMH_fields};

    foreach my $match (@_)
    {
        if(ref $match)
        {   $_ =~ $match && delete $known->{$_} foreach keys %$known;
        }
        else { delete $known->{lc $match} }
    }

    $self->cleanupOrderedFields;
}

#------------------------------------------

=method removeFieldsExcept STRING|REGEXP, [STRING|REGEXP, ...]

Remove all fields from the header which are not equivalent to one of the
specified STRINGs (case-insensitive) and which are not matching one of
the REGular EXPressions.  Do not forget to add the 'i' modifier to the
REGEXP, because fields are case insensitive.

See also M<removeField()> which is used to remove one field object from
the header.  The reverse specification can be made with C<removeFields()>.

=example

 $head->removeFieldsExcept('subject', qr/^content-/i ); 
 $head->removeFieldsExcept( qw/subject to from sender cc/ );

=cut

sub removeFieldsExcept(@)
{   my $self   = shift;
    my $known  = $self->{MMH_fields};
    my %remove = map { ($_ => 1) } keys %$known;

    foreach my $match (@_)
    {   if(ref $match)
        {   $_ =~ $match && delete $remove{$_} foreach keys %remove;
        }
        else { delete $remove{lc $match} }
    }

    delete @$known{ keys %remove };

    $self->cleanupOrderedFields;
}

#------------------------------------------

=method removeResentGroups

Removes all header lines which are member of a I<resent group>, which
are explained in M<Mail::Message::Head::ResentGroup>.  For removing single
groups (for instance because you want to keep the last), use
M<Mail::Message::Head::ResentGroup::delete()>.

=cut

sub removeResentGroups()
{   my $self = shift;
    require Mail::Message::Head::ResentGroup;
    
    my $known = $self->{MMH_fields};
    foreach my $name (keys %$known)
    {   delete $known->{$_}
           if $name =~ $Mail::Message::Head::ResentGroup::resent_field_names
    }

    $self->cleanupOrderedFields;
}

#------------------------------------------

=method cleanupOrderedFields

The header maintains a list of fields which are ordered in sequence of
definition.  It is required to maintain the header order to keep the
related fields of resent groups together.  The fields are also included
in a hash, sorted on their name for fast access.

The references to field objects in the hash are real, those in the ordered 
list are weak.  So when field objects are removed from the hash, their
references in the ordered list are automagically undef'd.

When many fields are removed, for instance with M<removeFields()> or
M<removeFieldsExcept()>, then it is useful to remove the list of undefs
from the ordered list as well.  In those cases, this method is called
automatically, however you may have your own reasons to call this method.

=cut

sub cleanupOrderedFields()
{   my $self = shift;
    my @take = grep { defined $_ } @{$self->{MMH_order}};
    weaken($_) foreach @take;
    $self->{MMH_order} = \@take;
    $self;
}

#------------------------------------------

1;
