# --
# Kernel/Modules/AdminDefaultRecipient.pm - provides admin DefaultRecipient module
# Copyright (C) 2015 Alexander Sulfrian <alex@spline.inf.fu-berlin.de>
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::AdminDefaultRecipient;

use strict;
use warnings;

our $ObjectManagerDisabled = 1;

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ParamObject  = $Kernel::OM->Get('Kernel::System::Web::Request');

    # ------------------------------------------------------------ #
    # change
    # ------------------------------------------------------------ #
    if ( $Self->{Subaction} eq 'Change' ) {
        my $ID = $ParamObject->GetParam( Param => 'ID' ) || '';
        my $DefaultRecipientObject = $Kernel::OM->Get('Kernel::System::DefaultRecipient');
        my %Data = $DefaultRecipientObject->Get(
            ID => $ID,
        );

        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();
        $Self->_Edit(
            $LayoutObject,
            $ConfigObject,
            Action => 'Change',
            %Data,
        );
        $Output .= $LayoutObject->Output(
            TemplateFile => 'AdminDefaultRecipient',
            Data         => \%Param,
        );
        $Output .= $LayoutObject->Footer();
        return $Output;
    }

    # ------------------------------------------------------------ #
    # change action
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'ChangeAction' ) {
        # challenge token check for write action
        $LayoutObject->ChallengeTokenCheck();

        my $DefaultRecipientObject = $Kernel::OM->Get('Kernel::System::DefaultRecipient');
        my @NewIDs = $ParamObject->GetArray( Param => 'IDs' );
        my ( %GetParam, %Errors );
        for my $Parameter (qw(ID Title RemoveTo To Cc Bcc Comment)) {
            $GetParam{$Parameter} = $ParamObject->GetParam(
                Param => $Parameter
            );
        }

        # check needed data
        $Errors{TitleInvalid} = 'ServerError' if !$GetParam{Title};

        # check if a DefaultRecipient entry exist with this title
        my $TitleExists = $DefaultRecipientObject->TitleExistsCheck(
            Title => $GetParam{Title},
            ID    => $GetParam{ID}
        );

        if ($TitleExists) {
            $Errors{TitleExists} = 1;
            $Errors{TitleInvalid} = 'ServerError';
        }

        # if no errors occurred
        if ( !%Errors ) {

            if ( $DefaultRecipientObject->Update(
                     %GetParam,
                     UserID => $Self->{UserID},
                 )
               )
            {
                $Self->_Overview($LayoutObject);
                my $Output = $LayoutObject->Header();
                $Output .= $LayoutObject->NavigationBar();
                $Output .= $LayoutObject->Notify( Info => 'DefaultRecipient updated!' );
                $Output .= $LayoutObject->Output(
                    TemplateFile => 'AdminDefaultRecipient',
                    Data         => \%Param,
                );
                $Output .= $LayoutObject->Footer();
                return $Output;
            }
        }

        # something has gone wrong
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();
        $Output .= $LayoutObject->Notify( Priority => 'Error' );
        $Self->_Edit(
            $LayoutObject,
            $ConfigObject,
            Action              => 'Change',
            Errors              => \%Errors,
            %GetParam,
        );
        $Output .= $LayoutObject->Output(
            TemplateFile => 'AdminDefaultRecipient',
            Data         => \%Param,
        );
        $Output .= $LayoutObject->Footer();
        return $Output;
    }

    # ------------------------------------------------------------ #
    # add
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'Add' ) {
        my $Title = $ParamObject->GetParam( Param => 'Title' );

        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();
        $Self->_Edit(
            $LayoutObject,
            $ConfigObject,
            Action => 'Add',
            Title => $Title,
        );
        $Output .= $LayoutObject->Output(
            TemplateFile => 'AdminDefaultRecipient',
            Data         => \%Param,
        );
        $Output .= $LayoutObject->Footer();
        return $Output;
    }

    # ------------------------------------------------------------ #
    # add action
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'AddAction' ) {
        # challenge token check for write action
        $LayoutObject->ChallengeTokenCheck();

        my $DefaultRecipientObject = $Kernel::OM->Get('Kernel::System::DefaultRecipient');
        my @NewIDs = $ParamObject->GetArray( Param => 'IDs' );
        my ( %GetParam, %Errors );

        for my $Parameter (qw(ID Title RemoveTo To Cc Bcc Comment)) {
            $GetParam{$Parameter} = $ParamObject->GetParam( Param => $Parameter );
        }

        # check needed data
        $Errors{TitleInvalid} = 'ServerError' if !$GetParam{Title};
        
        # check if a DefaultRecipient entry exists with this title
        my $TitleExists = $DefaultRecipientObject->TitleExistsCheck( Title => $GetParam{Title} );
        if ($TitleExists) {
            $Errors{TitleExists} = 1;
            $Errors{TitleInvalid} = 'ServerError';
        }

        # if no errors occurred
        if ( !%Errors ) {

            # add DefaultRecipient entry
            my $ID = $DefaultRecipientObject->Add(
                %GetParam,
                UserID => $Self->{UserID},
            );

            if ($ID) {
                $Self->_Overview($LayoutObject);
                my $Output = $LayoutObject->Header();
                $Output .= $LayoutObject->NavigationBar();
                $Output .= $LayoutObject->Notify( Info => 'DefaultRecipient added!' );
                $Output .= $LayoutObject->Output(
                    TemplateFile => 'AdminDefaultRecipient',
                    Data         => \%Param,
                );
                $Output .= $LayoutObject->Footer();
                return $Output;
            }
        }

        # something has gone wrong
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();
        $Output .= $LayoutObject->Notify( Priority => 'Error' );
        $Self->_Edit(
            $LayoutObject,
            $ConfigObject,
            Action              => 'Add',
            Errors              => \%Errors,
            %GetParam,
        );
        $Output .= $LayoutObject->Output(
            TemplateFile => 'AdminDefaultRecipient',
            Data         => \%Param,
        );
        $Output .= $LayoutObject->Footer();
        return $Output;
    }

    # ------------------------------------------------------------ #
    # delete action
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'Delete' ) {
        # challenge token check for write action
        $LayoutObject->ChallengeTokenCheck();

        my $DefaultRecipientObject = $Kernel::OM->Get('Kernel::System::DefaultRecipient');
        my $ID = $ParamObject->GetParam( Param => 'ID' );

        my $Delete = $DefaultRecipientObject->Delete(
            ID => $ID,
        );
        if ( !$Delete ) {
            return $LayoutObject->ErrorScreen();
        }

        return $LayoutObject->Redirect( OP => "Action=$Self->{Action}" );
    }

    # ------------------------------------------------------------
    # overview
    # ------------------------------------------------------------
    else {
        $Self->_Overview($LayoutObject);
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();
        $Output .= $LayoutObject->Output(
            TemplateFile => 'AdminDefaultRecipient',
            Data         => \%Param,
        );
        $Output .= $LayoutObject->Footer();
        return $Output;
    }
}

sub _Edit {
    my ( $Self, $LayoutObject, $ConfigObject, %Param ) = @_;
    $Param{Errors} = {} unless defined $Param{Errors};

    $LayoutObject->Block(
        Name => 'Overview',
        Data => \%Param,
    );

    $LayoutObject->Block( Name => 'ActionList' );
    $LayoutObject->Block( Name => 'ActionOverview' );

    $Param{DefaultRecipientRemoveToOption} = $LayoutObject->BuildSelection(
        Data       => $ConfigObject->Get('YesNoOptions'),
        Name       => 'RemoveTo',
        SelectedID => $Param{RemoveTo} || 0,
    );

    $LayoutObject->Block(
        Name => 'OverviewUpdate',
        Data => {
            %Param,
            %{ $Param{Errors} },
        },
    );

    # shows header
    if ( $Param{Action} eq 'Change' ) {
        $LayoutObject->Block( Name => 'HeaderEdit' );
    }
    else {
        $LayoutObject->Block( Name => 'HeaderAdd' );
    }

    # show appropriate messages for ServerError
    if ( defined $Param{Errors}->{TitleExists} && $Param{Errors}->{TitleExists} == 1 ) {
        $LayoutObject->Block( Name => 'ExistTitleServerError' );
    }
    else {
        $LayoutObject->Block( Name => 'TitleServerError' );
    }

    return 1;
}

sub _Overview {
    my ( $Self, $LayoutObject, %Param ) = @_;

    $LayoutObject->Block(
        Name => 'Overview',
        Data => \%Param,
    );

    $LayoutObject->Block( Name => 'ActionList' );
    $LayoutObject->Block( Name => 'ActionAdd' );
    $LayoutObject->Block( Name => 'Filter' );

    $LayoutObject->Block(
        Name => 'OverviewResult',
        Data => \%Param,
    );

    my $DefaultRecipientObject = $Kernel::OM->Get('Kernel::System::DefaultRecipient');
    my %List = $DefaultRecipientObject->List();

    for my $ID ( sort { $List{$a} cmp $List{$b} } keys %List )
    {
        my %DefaultRecipient = $DefaultRecipientObject->Get(
            ID => $ID,
        );

        my %YesNo = ( 0 => 'No', 1 => 'Yes' );
        $LayoutObject->Block(
            Name => 'OverviewResultRow',
            Data => {
                RemoveToYesNo => $YesNo{ $DefaultRecipient{RemoveTo} },
                %DefaultRecipient,
            },
        );
    }

    # otherwise it displays a no data found message
    if ( ! %List ) {
        $LayoutObject->Block(
            Name => 'NoDataFoundMsg',
            Data => {},
        );
    }

    return 1;
}

1;
