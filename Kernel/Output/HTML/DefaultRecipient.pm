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
    my %Addresses = ( To => [], Cc => [], Bcc => [] );
    foreach my $ID ( values %MappedDefaultRecipient ) {
        my %DefaultRecipient = $DefaultRecipientObject->Get(
            ID => $ID,
        );

        $RemoveTo = 1 if $DefaultRecipient{RemoveTo};

        for my $addr (qw(To Cc Bcc)) {
            if ( $DefaultRecipient{ $addr } ne '' ) {
                push $Addresses{ $addr }, $DefaultRecipient{ $addr };
            }
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
    for my $addr (qw(To Cc Bcc)) {
        for my $Address ( @{$Addresses{ $addr }} ) {
            $Self->{LayoutObject}->AddJSOnDocumentComplete(
                Code => 'Core.Agent.CustomerSearch.AddTicketCustomer( '
                      . "'${addr}Customer', "
                      . $Self->{LayoutObject}->JSONEncode( Data => $Address )
                      . ' );',
            );
        }
    }

    # set focus to text field
    $Self->{LayoutObject}->AddJSOnDocumentComplete(
        Code => "\$('#RichText').focus();"
    );

    return $Param{Data};
}

1;
