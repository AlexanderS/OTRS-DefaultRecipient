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
    Kernel::System::Web::Request
);

sub new {
    my ( $Type, %Param ) = @_;
    my $ParamObject = $Kernel::OM->Get('Kernel::System::Web::Request');

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    $Self->{LayoutObject} = $Param{LayoutObject};
    $Self->{ResponseID} = $ParamObject->GetParam( Param => 'ResponseID' );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !defined $Param{Data} ) {
        my $LogObject = $Kernel::OM->Get('Kernel::System::Log');
        $LogObject->Log(
            Priority => 'error',
            Message => 'Need Data!'
        );
        $Self->{LayoutObject}->FatalDie();
    }

    # return if not generated from template
    return unless $Self->{ResponseID};

    # get all DefaultRecipient
    my $DefaultRecipientObject = $Kernel::OM->Get('Kernel::System::DefaultRecipient');
    my %MappedDefaultRecipient = $DefaultRecipientObject->MappingList(
        TemplateID => $Self->{ResponseID},
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
        my @blocks = ();

        BLOCK:
        for my $block (@{$Self->{LayoutObject}{_JSOnDocumentComplete}}) {
            next BLOCK if $block =~ m/Core\.Agent\.CustomerSearch\.AddTicketCustomer\(\s*'ToCustomer'/;
            push @blocks, $block;
        }

        $Self->{LayoutObject}{_JSOnDocumentComplete} = \@blocks;
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

    return 1;
}

1;
