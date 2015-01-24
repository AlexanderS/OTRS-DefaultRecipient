# --
# Kernel/Modules/AdminDefaultToTemplates.pm - to manage DefaultTo <-> templates assignments
# Copyright (C) 2015 Alexander Sulfrian <alex@spline.inf.fu-berlin.de>
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::AdminDefaultToTemplates;

use strict;
use warnings;

our @ObjectDependencies = qw(
    Kernel::Output::HTML::Layout
    Kernel::System::DB
    Kernel::System::DefaultTo
    Kernel::System::StandardTemplate
    Kernel::System::Web::Request
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    # check all needed objects
    for (qw(ParamObject DBObject LayoutObject)) {
        if ( !$Self->{$_} ) {
            $Self->{LayoutObject}->FatalError( Message => "Got no $_!" );
        }
    }

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    # ------------------------------------------------------------ #
    # template <-> DefaultTo 1:n
    # ------------------------------------------------------------ #
    if ( $Self->{Subaction} eq 'Template' ) {

        # get template data
        my $ID = $Self->{ParamObject}->GetParam( Param => 'ID' );
        my $StandardTemplateObject = $Kernel::OM->Get('Kernel::System::StandardTemplate');
        my %StandardTemplateData = $StandardTemplateObject->StandardTemplateGet( ID => $ID );
        my $StandardTemplateType = $Self->{LayoutObject}->{LanguageObject}->Translate(
            $StandardTemplateData{TemplateType},
        );
        my $Name = $StandardTemplateType . ' - ' . $StandardTemplateData{Name};

        # get DefaultTo data
        my $DefaultToObject = $Kernel::OM->Get('Kernel::System::DefaultTo');
        my %DefaultToData = $DefaultToObject->List();
        my %Member = $DefaultToObject->MappingList(
            TemplateID => $ID,
        );

        my $Output = $Self->{LayoutObject}->Header();
        $Output .= $Self->{LayoutObject}->NavigationBar();
        $Output .= $Self->_Change(
            Data    => \%DefaultToData,
            ID      => $ID,
            Name    => $Name,
            Mapping => \%Member,
            Type     => 'Template',
        );
        $Output .= $Self->{LayoutObject}->Footer();
        return $Output;
    }

    # ------------------------------------------------------------ #
    # templates <-> DefaultTo n:1
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'DefaultTo' ) {

        my $ID = $Self->{ParamObject}->GetParam( Param => 'ID' );
        my $DefaultToObject = $Kernel::OM->Get('Kernel::System::DefaultTo');
        my %DefaultToData = $DefaultToObject->Get( ID => $ID );

        # get templates
        my $StandardTemplateObject = $Kernel::OM->Get('Kernel::System::StandardTemplate');
        my %StandardTemplateData = $StandardTemplateObject->StandardTemplateList(
            Valid => 1,
        );

        if (%StandardTemplateData) {
            for my $StandardTemplateID ( sort keys %StandardTemplateData ) {
                my %Data = $StandardTemplateObject->StandardTemplateGet(
                    ID => $StandardTemplateID
                );
                $StandardTemplateData{$StandardTemplateID}
                    = $Self->{LayoutObject}->{LanguageObject}->Translate( $Data{TemplateType} )
                    . ' - '
                    . $Data{Name};
            }
        }

        # get assigned templates
        my %Member = $DefaultToObject->MappingList(
            DefaultToID => $ID,
        );

        my $Output = $Self->{LayoutObject}->Header();
        $Output .= $Self->{LayoutObject}->NavigationBar();
        $Output .= $Self->_Change(
            Data    => \%StandardTemplateData,
            ID      => $ID,
            Name    => $DefaultToData{Title},
            Mapping => \%Member,
            Type    => 'DefaultTo',
        );
        $Output .= $Self->{LayoutObject}->Footer();
        return $Output;
    }

    # ------------------------------------------------------------ #
    # add templates to DefaultTo
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'ChangeDefaultTo' ) {

        # challenge token check for write action
        $Self->{LayoutObject}->ChallengeTokenCheck();

        # get current mapping
        my $ID = $Self->{ParamObject}->GetParam( Param => 'ID' );
        my $DefaultToObject = $Kernel::OM->Get('Kernel::System::DefaultTo');
        my %Mapping = $DefaultToObject->MappingList(
            DefaultToID => $ID,
        );

        # get new templates
        my @TemplatesSelected = $Self->{ParamObject}->GetArray( Param => 'ItemsSelected' );
        my @TemplatesAll      = $Self->{ParamObject}->GetArray( Param => 'ItemsAll' );

        # create hash with selected templates
        my %TemplatesSelected = map { $_ => 1 } @TemplatesSelected;

        # check all used templates
        for my $TemplateID (@TemplatesAll) {
            if ( $TemplatesSelected{$TemplateID} ) {
                if ( ! $Mapping{$TemplateID} ) {
                    $DefaultToObject->MappingAdd(
                        TemplateID => $TemplateID,
                        DefaultToID => $ID,
                    );
                }
            }
            else {
                if ( $Mapping{$TemplateID} ) {
                    $DefaultToObject->MappingDelete(
                        ID => $Mapping{$TemplateID},
                    );
                }
            }
        }

        return $Self->{LayoutObject}->Redirect( OP => "Action=$Self->{Action}" );
    }

    # ------------------------------------------------------------ #
    # add queues to template
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'ChangeTemplate' ) {

        # challenge token check for write action
        $Self->{LayoutObject}->ChallengeTokenCheck();

        # get current mapping
        my $ID = $Self->{ParamObject}->GetParam( Param => 'ID' );
        my $DefaultToObject = $Kernel::OM->Get('Kernel::System::DefaultTo');
        my %Mapping = $DefaultToObject->MappingList(
            TemplateID => $ID,
        );

        # get new queues
        my @Selected = $Self->{ParamObject}->GetArray( Param => 'ItemsSelected' );
        my @All      = $Self->{ParamObject}->GetArray( Param => 'ItemsAll' );

        # create hash with selected queues
        my %Selected = map { $_ => 1 } @Selected;

        # check all used queues
        for my $DefaultToID (@All) {
            if ( $Selected{$DefaultToID} ) {
                if ( ! $Mapping{$DefaultToID} ) {
                    $DefaultToObject->MappingAdd(
                        TemplateID => $ID,
                        DefaultToID => $DefaultToID,
                    );
                }
            }
            else {
                if ( $Mapping{$DefaultToID} ) {
                    $DefaultToObject->MappingDelete(
                        ID => $Mapping{$DefaultToID},
                    );
                }
            }
        }

        return $Self->{LayoutObject}->Redirect( OP => "Action=$Self->{Action}" );
    }

    # ------------------------------------------------------------ #
    # overview
    # ------------------------------------------------------------ #
    my $Output = $Self->{LayoutObject}->Header();
    $Output .= $Self->{LayoutObject}->NavigationBar();
    $Output .= $Self->_Overview();
    $Output .= $Self->{LayoutObject}->Footer();
    return $Output;
}

sub _Change {
    my ( $Self, %Param ) = @_;

    my %Data    = %{ $Param{Data} };
    my %Mapping = %{ $Param{Mapping} };
    my $Type    = $Param{Type} || 'Template';
    my $NeType  = 'DefaultTo';
    $NeType     = 'Template' if $Type eq 'DefaultTo';

    $Self->{LayoutObject}->Block( Name => 'Overview' );
    $Self->{LayoutObject}->Block( Name => 'ActionList' );
    $Self->{LayoutObject}->Block( Name => 'ActionOverview' );
    $Self->{LayoutObject}->Block( Name => 'Filter' );

    $Self->{LayoutObject}->Block(
        Name => 'Change',
        Data => {
            ID         => $Param{ID},
            Name       => $Param{Name},
            ActionHome => 'Admin' . $Type,
            NeType     => $NeType,
        },
    );

    $Self->{LayoutObject}->Block( Name => "ChangeHeader$NeType" );

    for my $ID ( sort { uc( $Data{$a} ) cmp uc( $Data{$b} ) } keys %Data ) {

        # set output class
        my $Selected = $Mapping{$ID} ? ' checked="checked"' : '';

        $Self->{LayoutObject}->Block(
            Name => 'ChangeRow',
            Data => {
                Type      => $NeType,
                ID        => $ID,
                Name      => $Data{$ID},
                Selected  => $Selected,
            },
        );
    }

    return $Self->{LayoutObject}->Output(
        TemplateFile => 'AdminDefaultToTemplates',
        Data         => \%Param,
    );
}

sub _Overview {
    my ( $Self, %Param ) = @_;

    $Self->{LayoutObject}->Block(
        Name => 'Overview',
        Data => {},
    );

    # no actions in action list
    #    $Self->{LayoutObject}->Block(Name=>'ActionList');
    $Self->{LayoutObject}->Block( Name => 'FilterTemplate' );
    $Self->{LayoutObject}->Block( Name => 'FilterDefaultTo' );
    $Self->{LayoutObject}->Block( Name => 'OverviewResult' );

    # get std template list
    my $StandardTemplateObject = $Kernel::OM->Get('Kernel::System::StandardTemplate');
    my %StandardTemplateData = $StandardTemplateObject->StandardTemplateList(
        Valid => 1,
    );

    # if there are results to show
    if (%StandardTemplateData) {
        for my $StandardTemplateID ( sort keys %StandardTemplateData ) {
            my %Data = $StandardTemplateObject->StandardTemplateGet(
                ID => $StandardTemplateID,
            );
            $StandardTemplateData{$StandardTemplateID}
                = $Self->{LayoutObject}->{LanguageObject}->Translate( $Data{TemplateType} )
                . ' - '
                . $Data{Name};
        }
        for my $StandardTemplateID (
            sort { uc( $StandardTemplateData{$a} ) cmp uc( $StandardTemplateData{$b} ) }
            keys %StandardTemplateData
            )
        {

            # set output class
            $Self->{LayoutObject}->Block(
                Name => 'List1n',
                Data => {
                    Name      => $StandardTemplateData{$StandardTemplateID},
                    Subaction => 'Template',
                    ID        => $StandardTemplateID,
                },
            );
        }
    }

    # otherwise it displays a no data found message
    else {
        $Self->{LayoutObject}->Block(
            Name => 'NoTemplatesFoundMsg',
            Data => {},
        );
    }

    # get queue data
    my $DefaultToObject = $Kernel::OM->Get('Kernel::System::DefaultTo');
    my %DefaultToData = $DefaultToObject->List();

    # if there are results to show
    if (%DefaultToData) {
        for my $ID (
            sort { uc( $DefaultToData{$a} ) cmp uc( $DefaultToData{$b} ) }
            keys %DefaultToData
            )
        {

            # set output class
            $Self->{LayoutObject}->Block(
                Name => 'Listn1',
                Data => {
                    Name      => $DefaultToData{$ID},
                    Subaction => 'DefaultTo',
                    ID        => $ID,
                },
            );
        }
    }

    # otherwise it displays a no data found message
    else {
        $Self->{LayoutObject}->Block(
            Name => 'NoDefaultToFoundMsg',
            Data => {},
        );
    }

    # return output
    return $Self->{LayoutObject}->Output(
        TemplateFile => 'AdminDefaultToTemplates',
        Data         => \%Param,
    );
}

1;
