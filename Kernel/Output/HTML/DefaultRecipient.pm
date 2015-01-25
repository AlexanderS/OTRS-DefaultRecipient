# --
# Kernel/Output/HTML/DefaultRecipient.pm
# Copyright (C) 2015 Alexander Sulfrian <alex@spline.inf.fu-berlin.de>
# --

package Kernel::Output::HTML::DefaultRecipient;

use strict;
use warnings;

our @ObjectDependencies = qw(
    Kernel::System::Log
    Kernel::System::DefaultRecipient
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    $Self->{LayoutObject} = $Param{LayoutObject} || die "Got no LayoutObject!";
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;
    return if !$Self->{LayoutObject};

    # check needed stuff
    if ( !defined $Param{Data} ) {
        my $LogObject = $Kernel::OM->Get('Kernel::System::Log');
        $LogObject->Log(
            Priority => 'error',
            Message => 'Need Data!'
        );
        $Self->{LayoutObject}->FatalDie();
    }

    my $BlockData = $Self->{LayoutObject}->{BlockData};

    # get ticket data
    my $Ticket;
    BLOCK:
    for my $block ( @$BlockData ) {
        if ( $block->{Name} eq 'TicketBack' ) {
            $Ticket = $block->{Data};
            last BLOCK;
        }
    } 

    # return if not generated from template
    return unless $Ticket->{ResponseID};

    # get all DefaultRecipient
    my $DefaultRecipientObject = $Kernel::OM->Get('Kernel::System::DefaultRecipient');
    my %MappedDefaultRecipient = $DefaultRecipientObject->MappingList(
        TemplateID => $Ticket->{ResponseID},
    );

    my $RemoveTo = 0;
    my @ToAddresses = ();
    my @CcAddresses = ();
    my @BccAddresses = ();
    foreach my $ID ( values %MappedDefaultRecipient ) {
        my %DefaultRecipient = $DefaultRecipientObject->Get(
            ID => $ID,
        );

        $RemoveTo = 1 if $DefaultRecipient{RemoveTo};
        if ( $DefaultRecipient{To} ne '' ) {
            push @ToAddresses, $DefaultRecipient{To};
        }
        if ( $DefaultRecipient{Cc} ne '' ) {
            push @CcAddresses, $DefaultRecipient{Cc};
        }
        if ( $DefaultRecipient{Bcc} ne '' ) {
            push @BccAddresses, $DefaultRecipient{Bcc};
        }
    }

    if ( $RemoveTo ) {
        # remove preselected "To" address
        for my $block ( @$BlockData ) {
            if ( $block->{Name} eq 'PreFilledToRow' ) {
                $block->{Data} = undef;
            }
        }

        $Self->{LayoutObject}->{BlockData} = $BlockData;
    }

    # add new addresses
    foreach my $Address ( @ToAddresses ) {
        $Self->{LayoutObject}->Block(
            Name => 'PreFilledToRow',
            Data => {
                Email => $Address,
            },
        );
    }

    foreach my $Address ( @CcAddresses ) {
        $Self->{LayoutObject}->Block(
            Name => 'PreFilledCcRow',
            Data => {
                Email => $Address,
            },
        );
    }

    foreach my $Address ( @BccAddresses ) {
        $Self->{LayoutObject}->AddJSOnDocumentComplete(
            Code => 'Core.Agent.CustomerSearch.AddTicketCustomer( '
                  . "'BccCustomer', "
                  . $Self->{LayoutObject}->JSONEncode( Data => $Address )
                  . ' );',
        );
    }

    return $Param{Data};
}

1;
