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

our @ObjectDependencies = qw(
    Kernel::Config
    Kernel::Output::HTML::Layout
    Kernel::System::DB
    Kernel::System::Web::Request
    Kernel::System::DefaultRecipient
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    # check all needed objects
    for my $Needed (qw(ParamObject DBObject LayoutObject ConfigObject)) {
        if ( !$Self->{$Needed} ) {
            $Self->{LayoutObject}->FatalError( Message => "Got no $Needed!" );
        }
    }

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    # ------------------------------------------------------------ #
    # change
    # ------------------------------------------------------------ #
    if ( $Self->{Subaction} eq 'Change' ) {
        my $ID = $Self->{ParamObject}->GetParam( Param => 'ID' ) || '';
        my $DefaultRecipientObject = $Kernel::OM->Get('Kernel::System::DefaultRecipient');
        my %Data = $DefaultRecipientObject->Get(
            ID => $ID,
        );

        my $Output = $Self->{LayoutObject}->Header();
        $Output .= $Self->{LayoutObject}->NavigationBar();
        $Self->_Edit(
            Action => 'Change',
            %Data,
        );
        $Output .= $Self->{LayoutObject}->Output(
            TemplateFile => 'AdminDefaultRecipient',
            Data         => \%Param,
        );
        $Output .= $Self->{LayoutObject}->Footer();
        return $Output;
    }

    # ------------------------------------------------------------ #
    # change action
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'ChangeAction' ) {
        # challenge token check for write action
        $Self->{LayoutObject}->ChallengeTokenCheck();

        my $DefaultRecipientObject = $Kernel::OM->Get('Kernel::System::DefaultRecipient');
        my @NewIDs = $Self->{ParamObject}->GetArray( Param => 'IDs' );
        my ( %GetParam, %Errors );
        for my $Parameter (qw(ID Title RemoveDefault AddNew NewAddress
                              Comment)) {
            $GetParam{$Parameter} = $Self->{ParamObject}->GetParam(
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
                $Self->_Overview();
                my $Output = $Self->{LayoutObject}->Header();
                $Output .= $Self->{LayoutObject}->NavigationBar();
                $Output .= $Self->{LayoutObject}->Notify( Info => 'DefaultRecipient updated!' );
                $Output .= $Self->{LayoutObject}->Output(
                    TemplateFile => 'AdminDefaultRecipient',
                    Data         => \%Param,
                );
                $Output .= $Self->{LayoutObject}->Footer();
                return $Output;
            }
        }

        # something has gone wrong
        my $Output = $Self->{LayoutObject}->Header();
        $Output .= $Self->{LayoutObject}->NavigationBar();
        $Output .= $Self->{LayoutObject}->Notify( Priority => 'Error' );
        $Self->_Edit(
            Action              => 'Change',
            Errors              => \%Errors,
            %GetParam,
        );
        $Output .= $Self->{LayoutObject}->Output(
            TemplateFile => 'AdminDefaultRecipient',
            Data         => \%Param,
        );
        $Output .= $Self->{LayoutObject}->Footer();
        return $Output;
    }

    # ------------------------------------------------------------ #
    # add
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'Add' ) {
        my $Title = $Self->{ParamObject}->GetParam( Param => 'Title' );

        my $Output = $Self->{LayoutObject}->Header();
        $Output .= $Self->{LayoutObject}->NavigationBar();
        $Self->_Edit(
            Action => 'Add',
            Title => $Title,
        );
        $Output .= $Self->{LayoutObject}->Output(
            TemplateFile => 'AdminDefaultRecipient',
            Data         => \%Param,
        );
        $Output .= $Self->{LayoutObject}->Footer();
        return $Output;
    }

    # ------------------------------------------------------------ #
    # add action
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'AddAction' ) {
        # challenge token check for write action
        $Self->{LayoutObject}->ChallengeTokenCheck();

        my $DefaultRecipientObject = $Kernel::OM->Get('Kernel::System::DefaultRecipient');
        my @NewIDs = $Self->{ParamObject}->GetArray( Param => 'IDs' );
        my ( %GetParam, %Errors );

        for my $Parameter (qw(ID Title RemoveDefault AddNew NewAddress
                              Comment)) {
            $GetParam{$Parameter} = $Self->{ParamObject}->GetParam( Param => $Parameter );
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
                $Self->_Overview();
                my $Output = $Self->{LayoutObject}->Header();
                $Output .= $Self->{LayoutObject}->NavigationBar();
                $Output .= $Self->{LayoutObject}->Notify( Info => 'DefaultRecipient added!' );
                $Output .= $Self->{LayoutObject}->Output(
                    TemplateFile => 'AdminDefaultRecipient',
                    Data         => \%Param,
                );
                $Output .= $Self->{LayoutObject}->Footer();
                return $Output;
            }
        }

        # something has gone wrong
        my $Output = $Self->{LayoutObject}->Header();
        $Output .= $Self->{LayoutObject}->NavigationBar();
        $Output .= $Self->{LayoutObject}->Notify( Priority => 'Error' );
        $Self->_Edit(
            Action              => 'Add',
            Errors              => \%Errors,
            %GetParam,
        );
        $Output .= $Self->{LayoutObject}->Output(
            TemplateFile => 'AdminDefaultRecipient',
            Data         => \%Param,
        );
        $Output .= $Self->{LayoutObject}->Footer();
        return $Output;
    }

    # ------------------------------------------------------------ #
    # delete action
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'Delete' ) {
        # challenge token check for write action
        $Self->{LayoutObject}->ChallengeTokenCheck();

        my $DefaultRecipientObject = $Kernel::OM->Get('Kernel::System::DefaultRecipient');
        my $ID = $Self->{ParamObject}->GetParam( Param => 'ID' );

        my $Delete = $DefaultRecipientObject->Delete(
            ID => $ID,
        );
        if ( !$Delete ) {
            return $Self->{LayoutObject}->ErrorScreen();
        }

        return $Self->{LayoutObject}->Redirect( OP => "Action=$Self->{Action}" );
    }

    # ------------------------------------------------------------
    # overview
    # ------------------------------------------------------------
    else {
        $Self->_Overview();
        my $Output = $Self->{LayoutObject}->Header();
        $Output .= $Self->{LayoutObject}->NavigationBar();
        $Output .= $Self->{LayoutObject}->Output(
            TemplateFile => 'AdminDefaultRecipient',
            Data         => \%Param,
        );
        $Output .= $Self->{LayoutObject}->Footer();
        return $Output;
    }
}

sub _Edit {
    my ( $Self, %Param ) = @_;
    $Param{Errors} = {} unless defined $Param{Errors};

    $Self->{LayoutObject}->Block(
        Name => 'Overview',
        Data => \%Param,
    );

    $Self->{LayoutObject}->Block( Name => 'ActionList' );
    $Self->{LayoutObject}->Block( Name => 'ActionOverview' );

    $Param{DefaultRecipientTitleString} = '';

    $Param{DefaultRecipientRemoveDefaultOption} = $Self->{LayoutObject}->BuildSelection(
        Data       => $Self->{ConfigObject}->Get('YesNoOptions'),
        Name       => 'RemoveDefault',
        SelectedID => $Param{RemoveDefault} || 0,
    );

    $Param{DefaultRecipientAddNewOption} = $Self->{LayoutObject}->BuildSelection(
        Data       => $Self->{ConfigObject}->Get('YesNoOptions'),
        Name       => 'AddNew',
        SelectedID => $Param{AddNew} || 0,
    );

    $Param{DefaultRecipientNewAddressString} = '';

    $Self->{LayoutObject}->Block(
        Name => 'OverviewUpdate',
        Data => {
            %Param,
            %{ $Param{Errors} },
        },
    );

    # shows header
    if ( $Param{Action} eq 'Change' ) {
        $Self->{LayoutObject}->Block( Name => 'HeaderEdit' );
    }
    else {
        $Self->{LayoutObject}->Block( Name => 'HeaderAdd' );
    }

    # show appropriate messages for ServerError
    if ( defined $Param{Errors}->{TitleExists} && $Param{Errors}->{TitleExists} == 1 ) {
        $Self->{LayoutObject}->Block( Name => 'ExistTitleServerError' );
    }
    else {
        $Self->{LayoutObject}->Block( Name => 'TitleServerError' );
    }

    return 1;
}

sub _Overview {
    my ( $Self, %Param ) = @_;

    $Self->{LayoutObject}->Block(
        Name => 'Overview',
        Data => \%Param,
    );

    $Self->{LayoutObject}->Block( Name => 'ActionList' );
    $Self->{LayoutObject}->Block( Name => 'ActionAdd' );
    $Self->{LayoutObject}->Block( Name => 'Filter' );

    $Self->{LayoutObject}->Block(
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
        $Self->{LayoutObject}->Block(
            Name => 'OverviewResultRow',
            Data => {
                RemoveDefaultYesNo => $YesNo{ $DefaultRecipient{RemoveDefault} },
                AddNewYesNo => $YesNo{ $DefaultRecipient{AddNew} },
                %DefaultRecipient,
            },
        );
    }

    # otherwise it displays a no data found message
    if ( ! %List ) {
        $Self->{LayoutObject}->Block(
            Name => 'NoDataFoundMsg',
            Data => {},
        );
    }

    return 1;
}

1;
