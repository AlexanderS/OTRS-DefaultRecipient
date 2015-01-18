# --
# Kernel/Output/HTML/ResponseChangeDefaultTo.pm
# Copyright (C) 2015 Alexander Sulfrian <alex@spline.inf.fu-berlin.de>
# --

package Kernel::Output::HTML::ResponseChangeDefaultTo;

use strict;
use warnings;

our @ObjectDependencies = qw(
    Kernel::Config
    Kernel::System::DB
    Kernel::System::Encode
    Kernel::System::Log
    Kernel::System::Main
    Kernel::System::ResponseChangeDefaultTo
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    $Self->{LayoutObject} = $Param{$_} || die "Got no $_!";
    $Self->{ConfigObject} = $Kernel::OM->Get('Kernel::Config');
    $Self->{DBObject} = $Kernel::OM->Get('Kernel::System::DB');
    $Self->{EncodeObject} = $Kernel::OM->Get('Kernel::System::Encode');
    $Self->{LogObject} = $Kernel::OM->Get('Kernel::System::Log');
    $Self->{MainObject} = $Kernel::OM->Get('Kernel::System::Main');
    $Self->{ResponseChangeDefaultToObject} =
        $Kernel::OM->Get('Kernel::System::ResponseChangeDefaultTo');
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;
    return if !$Self->{LayoutObject};

    for (qw(DBObject EncodeObject ConfigObject LogObject MainObject
            LayoutObject ResponseChangeDefaultToObject)) {
        return if !$Self->{$_};
    }

    # check needed stuff
    if ( !defined $Param{Data} ) {
        $Self->{LogObject}->Log(
            Priority => 'error',
            Message => 'Need Data!'
        );
        $Self->{LayoutObject}->FatalDie();
    }

    my @BlockData = $Self->{LayoutObject}->{BlockData};

    # get ticket data
    my %Ticket = ();
    BLOCK:
    for my $block ( @BlockData ) {
        if ( $block->{Name} eq 'TicketBack' ) {
            %Ticket = $block->{Data};
            last BLOCK;
        }
    } 

    # remove preselected "To" address
    $Self->{LayoutObject}->{BlockData} =
        grep { $_->{Name} ne 'PreFilledToRow' } @BlockData;

    return $Param{Data};
}

1;
