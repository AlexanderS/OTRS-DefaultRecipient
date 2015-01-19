# --
# Kernel/System/ResponseChangeDefaultTo.pm - core module
# Copyright (C) 2015 Alexander Sulfrian <alex@spline.inf.fu-berlin.de>
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::ResponseChangeDefaultTo;

use strict;
use warnings;

our @ObjectDependencies = qw(
    Kernel::System::DB
    Kernel::System::Log
    Kernel::System::StandardTemplate
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    $Self->{DBObject} = $Kernel::OM->Get('Kernel::System::DB');
    $Self->{LogObject} = $Kernel::OM->Get('Kernel::System::Log');
    $Self->{StandardTemplateObject} =
        $Kernel::OM->Get('Kernel::System::StandardTemplate');
    bless ($Self, $Type);

    return $Self;
}

sub Add {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(Title RemoveDefault AddNew NewAddress)) {
        if ( !$Param{$Needed} ) {
            $Self->{LogObject}->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    # insert new ResponseChangeDefaultTo
    return if !$Self->{DBObject}->Do(
        SQL => 'INSERT INTO response_change_default_to '
             . '(title, remove_default, add_new, new_address) '
             . 'VALUES (?, ?, ?, ?)',
        Bind => [
            \$Param{Title},
            \$Param{RemoveDefault},
            \$Param{AddNew},
            \$Param{NewAddress},
        ],
    );

    # get new id
    return if !$Self->{DBObject}->Prepare(
        SQL   => 'SELECT MAX(id) FROM response_change_default_to WHERE title = ?',
        Bind  => [ \$Param{Title}, ],
        Limit => 1,
    );

    my $ID;
    while ( my @Row = $Self->{DBObject}->FetchrowArray() ) {
        $ID = $Row[0];
    }

    # log notice
    $Self->{LogObject}->Log(
        Priority => 'notice',
        Message  => "ResponseChangeDefaultTo '$ID' created successfully!",
    );

    return $ID;
}

sub Update {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(ID Title RemoveDefault AddNew NewAddress)) {
        if ( !$Param{$Needed} ) {
            $Self->{LogObject}->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    # insert new ResponseChangeDefaultTo
    return if !$Self->{DBObject}->Do(
        SQL => 'UPDATE response_change_default_to SET title = ?, '
             . 'remove_default = ?, add_new = ?, new_address = ? '
             . 'WHERE id = ?',
        Bind => [
            \$Param{Title},
            \$Param{RemoveDefault},
            \$Param{AddNew},
            \$Param{NewAddress},
            \$Param{ID},
        ],
    );

    return 1;
}

sub Get {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{ID} ) {
        $Self->{LogObject}->Log(
            Priority => 'error',
            Message  => 'Need ID!',
        );
        return;
    }

    # get RrsponseChangeDefaultTO obejct
    return if !$Self->{DBObject}->Prepare(
        SQL => 'SELECT id, title, remove_default, add_new, new_address '
             . 'FROM response_change_default_to WHERE id = ?',
        Bind  => [ \$Param{ID} ],
        Limit => 1,
    );

    my %ResponseChangeDefaultTo;
    while ( my @Data = $Self->{DBObject}->FetchrowArray() ) {
        %ResponseChangeDefaultTo = (
            ID            => $Data[0],
            Title         => $Data[1],
            RemoveDefault => $Data[2],
            AddNew        => $Data[3],
            NewAddress    => $Data[4],
        );
    }

    # make sure we have a valid object
    return unless %ResponseChangeDefaultTo;

    # get the assigned responses
    return if !$Self->{DBObject}->Prepare(
        SQL => 'SELECT id, response_id '
             . 'FROM response_change_default_to_response '
             . 'WHERE response_change_default_to_id = ?',
        Bind => [ \$ResponseChangeDefaultTo{ID} ],
    );

    while ( my @Data = $Self->{DBObject}->FetchrowArray() ) {
        my $Response =
            $Self->{StandardTemplateObject}->StandardTemplateLookup(
                StandardTemplateID => $Data[1],
            );

        if ( $Response ) {
            $ResponseChangeDefaultTo{Responses}->{$Data[0]} = {
                ID => $Data[1],
                Name => $Response,
            };
        }        
    }

    return %ResponseChangeDefaultTo;
}

sub Delete {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{ID} ) {
        $Self->{LogObject}->Log(
            Priority => 'error',
            Message  => 'Need ID!',
        );
        return;
    }

    # delete mapping
    return if !$Self->{DBObject}->Do(
        SQL => 'DELETE FROM response_change_default_to_response '
             . 'WHERE response_change_default_to_id = ?',
        Bind => [ \$Param{ID} ],
    );

    # delete entry
    return $Self->{DBObject}->Do(
        SQL => 'DELETE FROM response_change_default_to WHERE id = ?',
        Bind  => [ \$Param{ID} ],
    );
}

sub List {
    my ( $Self, %Param ) = @_;

    $Self->{DBObject}->Prepare(
        SQL => 'SELECT id, title FROM response_change_default_to',
    );

    my %ResponseChangeDefaultTo;
    while ( my @Data = $Self->{DBObject}->FetchrowArray() ) {
        $ResponseChangeDefaultTo{ $Data[0] } = $Data[1];
    }

    return %ResponseChangeDefaultTo;
}

sub MappingAdd {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(ResponseID ResponseChangeDefaultToID)) {
        if ( !$Param{$Needed} ) {
            $Self->{LogObject}->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    # insert new mapping
    return if !$Self->{DBObject}->Do(
        SQL => 'INSERT INTO response_change_default_to_response '
             . '(response_id, response_change_default_to_id) VALUES (?, ?)',
        Bind => [
            \$Param{ResponseID},
            \$Param{ResponseChangeDefaultToID},
        ],
    );

    # get new id
    return if !$Self->{DBObject}->Prepare(
        SQL   => 'SELECT MAX(id) FROM response_change_default_to_response '
               . 'WHERE response_id = ? AND response_change_default_to_id = ?',
        Bind  => [
            \$Param{ResponseID},
            \$Param{ResponseChangeDefaultToID}, ],
        Limit => 1,
    );

    my $ID;
    while ( my @Row = $Self->{DBObject}->FetchrowArray() ) {
        $ID = $Row[0];
    }

    # log notice
    $Self->{LogObject}->Log(
        Priority => 'notice',
        Message  => "ResponseChangeDefaultTo mapping '$ID' "
                  . "created successfully!",
    );

    return $ID;
}

sub MappingDelete {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{ID} ) {
        $Self->{LogObject}->Log(
            Priority => 'error',
            Message  => 'Need ID!',
        );
        return;
    }

    # delete mapping
    return $Self->{DBObject}->Do(
        SQL => 'DELETE FROM response_change_default_to_response '
             . 'WHERE id = ?',
        Bind => [ \$Param{ID} ],
    );
}

sub MappingList {
    my ( $Self, %Param ) = @_;

     # check needed stuff
    if ( !$Param{ResponseID} && !$Param{ResponseChangeDefaultToID} ) {
        $Self->{LogObject}->Log(
            Priority => 'error',
            Message  => 'Got no ResponseID or ResponseChangeDefaultToID!'
        );
        return;
    }

    my %Mapping;

    if ( $Param{All} ) {
        # get list all all objects
        my %List;
        if ( $Param{ResponseID} ) {
            %List = $Self->List();
        }
        else {
            %List = $Self->{StandardTemplateObject}->StandardTemplateList();
        }

        foreach ( keys %List ) {
            $Mapping{$_} = {
                Title => $List{$_},
            };
        }
    }

    # find mapped objects
    if ( $Param{ResponseID} ) {
        $Self->{DBObject}->Prepare(
            SQL => 'SELECT id, response_change_default_to_id '
                 . 'FROM response_change_default_to_response '
                 . 'WHERE response_id = ?',
            Bind => [ \$Param{ResponseID}, ],
        );
    }
    else {
        $Self->{DBObject}->Prepare(
            SQL => 'SELECT id, response_id '
                 . 'FROM response_change_default_to_response '
                 . 'WHERE response_change_default_to_id = ?',
            Bind => [ \$Param{ResponseChangeDefaultToID}, ],
        );
    }

    while ( my @Data = $Self->{DBObject}->FetchrowArray() ) {
        $Mapping{ $Data[0] }->{MappingID} = $Data[1];
    }

    return %Mapping;
}

1;
