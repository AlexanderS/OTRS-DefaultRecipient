# --
# Kernel/Output/HTML/ResponseChangeDefaultTo.pm
# Copyright (C) 2015 Alexander Sulfrian <alex@spline.inf.fu-berlin.de>
# --

package Kernel::Output::HTML::ResponseChangeDefaultTo;

use strict;
use warnings;

our @ObjectDependencies = qw(
    Kernel::System::Log
    Kernel::System::ResponseChangeDefaultTo
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    $Self->{LayoutObject} = $Param{LayoutObject} || die "Got no LayoutObject!";
    $Self->{LogObject} = $Kernel::OM->Get('Kernel::System::Log');
    $Self->{ResponseChangeDefaultToObject} =
        $Kernel::OM->Get('Kernel::System::ResponseChangeDefaultTo');
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;
    return if !$Self->{LayoutObject};

    for (qw(LogObject LayoutObject ResponseChangeDefaultToObject)) {
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

    # return if not generated from template
    return unless $Ticket{ResponseID};

    # get all ResponseChangeDefaultTo
    my %MappedResponseChangeDefaultTo =
        $Self->{ResponseChangeDefaultToObject}->MappingList(
            ResponseID => $Ticket{ResponseID},        
        );

    my $RemoveDefault = 0;
    my @Addresses = ();
    foreach ( values %MappedResponseChangeDefaultTo ) {
        my $ID = $_->{MappingID};
        my %ResponseChangeDefaultTo =
            $Self->{ResponseChangeDefaultToObject}->Get(
                ID => $ID,
            );

        $RemoveDefault = 1 if $ResponseChangeDefaultTo{RemoveDefault};
        if ( $ResponseChangeDefaultTo{AddNew} ) {
            push @Addresses, $ResponseChangeDefaultTo{NewAddress};
        }
    }

    if ( $RemoveDefault ) {
        # remove preselected "To" address
        $Self->{LayoutObject}->{BlockData} =
            grep { $_->{Name} ne 'PreFilledToRow' } @BlockData;
    }

    # add new addresses
    foreach my $Address ( @Addresses ) {
        $Self->{LayoutObject}->Block(
            Name => 'PreFilledToRow',
            Data => {
                Email => $Address,
            },
        );
    }

    return $Param{Data};
}

1;
