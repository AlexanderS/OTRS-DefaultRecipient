# --
# Kernel/Output/HTML/ArticleCompose/DefaultRecipient.pm
# Copyright (C) 2015 Alexander Sulfrian <alex@spline.inf.fu-berlin.de>
# --

package Kernel::Output::HTML::ArticleCompose::DefaultRecipient;

use strict;
use warnings;

our @ObjectDependencies = qw(
    Kernel::Output::HTML::Layout
    Kernel::System::DefaultRecipient
    Kernel::System::Log
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');;

    # check needed stuff
    if ( !defined $Param{Data} ) {
        my $LogObject = $Kernel::OM->Get('Kernel::System::Log');
        $LogObject->Log(
            Priority => 'error',
            Message => 'Need Data!'
        );
        $LayoutObject->FatalDie();
    }

    my $BlockData = $LayoutObject->{BlockData};

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
    unless ($Ticket->{ResponseID}) {
        my $LogObject = $Kernel::OM->Get('Kernel::System::Log');
        $LogObject->Log(
            Priority => 'error',
            Message => 'Need Data!'
        );
        $LayoutObject->FatalDie();
    }
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
                push @{$Addresses{ $addr }}, $DefaultRecipient{ $addr };
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

        $LayoutObject->{BlockData} = $BlockData;
    }

    # add new addresses
    for my $addr (qw(To Cc Bcc)) {
        for my $Address ( @{$Addresses{ $addr }} ) {
            $LayoutObject->AddJSOnDocumentComplete(
                Code => 'Core.Agent.CustomerSearch.AddTicketCustomer( '
                      . "'${addr}Customer', "
                      . $LayoutObject->JSONEncode( Data => $Address )
                      . ' );',
            );
        }
    }

    # set focus to text field
    $LayoutObject->AddJSOnDocumentComplete(
        Code => "\$('#RichText').focus();"
    );

    return $Param{Data};
}

1;
