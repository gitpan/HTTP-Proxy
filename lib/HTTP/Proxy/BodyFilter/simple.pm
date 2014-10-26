package HTTP::Proxy::BodyFilter::simple;

use strict;
use Carp;
use HTTP::Proxy::BodyFilter;
use vars qw( @ISA );
@ISA = qw( HTTP::Proxy::BodyFilter );

=head1 NAME

HTTP::Proxy::BodyFilter::simple - A class for creating simple filters

=head1 SYNOPSIS

    use HTTP::Proxy::BodyFilter::simple;

    # a simple s/// filter
    my $filter = HTTP::Proxy::BodyFilter::simple->new(
        sub { ${ $_[0] } =~ s/foo/bar/g; }
    );
    $proxy->push_filter( response => $filter );

=head1 DESCRIPTION

HTTP::Proxy::BodyFilter::simple can create BodyFilter without going
through the hassle of creating a full-fledged class. Simply pass
a code reference to the filter() method of your filter to the constructor,
and you'll get the adequate filter.

=head2 Constructor calling convention

The constructor can be called in several ways, which are shown in the
synopsis:

=over 4

=item single code reference

The code reference must conform to the standard filter() signature:

    sub filter {
        my ( $self, $dataref, $message, $protocol, $buffer ) = @_;
        ...
    }

It is assumed to be the code for the filter() method.
See HTTP::Proxy::BodyFilter.pm for more details about the filter() method.

=item name/coderef pairs

The name is the name of the method (C<filter>, C<begin>, C<end>)
and the coderef is the method itself.

See HTTP::Proxy::BodyFilter for the methods signatures.

=back

=cut

my $methods = join '|', qw( begin start filter end );
$methods = qr/^(?:$methods)$/;

sub init {
    my $self = shift;

    croak "Constructor called without argument" unless @_;
    if ( @_ == 1 ) {
        croak "Single parameter must be a CODE reference"
          unless ref $_[0] eq 'CODE';
        $self->{_filter} = $_[0];
    }
    else {
        while (@_) {
            my ( $name, $code ) = splice @_, 0, 2;

            # basic error checking
            croak "Parameter to $name must be a CODE reference"
              unless ref $code eq 'CODE';
            croak "Unkown method $name"
              unless $name =~ $methods;

            $self->{"_$name"} = $code;
        }
    }
}

# transparently call the actual methods
sub begin       { goto &{ $_[0]{_begin} }; }
sub start       { goto &{ $_[0]{_start} }; } # DEPRECATED
sub filter      { goto &{ $_[0]{_filter} }; }
sub end         { goto &{ $_[0]{_end} }; }

sub can {
    my ( $self, $method ) = @_;
    return $method =~ $methods
      ? $self->{"_$method"}
      : UNIVERSAL::can( $self, $method );
}

=head1 AUTHOR

Philippe "BooK" Bruhat, E<lt>book@cpan.orgE<gt>.

=head1 COPYRIGHT

Copyright 2003-2005, Philippe Bruhat

=head1 LICENSE

This module is free software; you can redistribute it or modify it under
the same terms as Perl itself.

=cut

1;
