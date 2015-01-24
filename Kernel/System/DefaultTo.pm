# --
# Kernel/System/DefaultTo.pm - core module
# Copyright (C) 2015 Alexander Sulfrian <alex@spline.inf.fu-berlin.de>
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::DefaultTo;

use strict;
use warnings;

our @ObjectDependencies = qw(
    Kernel::System::DB
    Kernel::System::Log
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless ($Self, $Type);

    return $Self;
}

sub Add {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(Title RemoveDefault AddNew NewAddress Comment UserID)) {
        if ( ! defined $Param{$Needed} ) {
            my $LogObject = $Kernel::OM->Get('Kernel::System::Log');
            $LogObject->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # insert new DefaultTo
    return if !$DBObject->Do(
        SQL => 'INSERT INTO default_to '
             . '(title, remove_default, add_new, new_address, comments, '
             . ' create_time, create_by, change_time, change_by) '
             . 'VALUES (?, ?, ?, ?, ?, current_timestamp, ?, current_timestamp, ?)',
        Bind => [
            \$Param{Title},
            \$Param{RemoveDefault},
            \$Param{AddNew},
            \$Param{NewAddress},
            \$Param{Comment},
            \$Param{UserID},
            \$Param{UserID},
        ],
    );

    # get new id
    return if !$DBObject->Prepare(
        SQL   => 'SELECT MAX(id) FROM default_to WHERE title = ?',
        Bind  => [ \$Param{Title}, ],
        Limit => 1,
    );

    my $ID;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $ID = $Row[0];
    }

    # log notice
    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');
    $LogObject->Log(
        Priority => 'notice',
        Message  => "DefaultTo '$ID' created successfully!",
    );

    return $ID;
}

sub Update {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(ID Title RemoveDefault AddNew NewAddress Comment
                       UserID)) {
        if ( ! defined $Param{$Needed} ) {
            my $LogObject = $Kernel::OM->Get('Kernel::System::Log');
            $LogObject->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # insert new DefaultTo
    return if !$DBObject->Do(
        SQL => 'UPDATE default_to SET title = ?, remove_default = ?, '
             . 'add_new = ?, new_address = ?, comments = ?, change_by = ?, '
             . 'change_time = current_timestamp '
             . 'WHERE id = ?',
        Bind => [
            \$Param{Title},
            \$Param{RemoveDefault},
            \$Param{AddNew},
            \$Param{NewAddress},
            \$Param{Comment},
            \$Param{UserID},
            \$Param{ID},
        ],
    );

    return 1;
}

sub Get {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{ID} ) {
        my $LogObject = $Kernel::OM->Get('Kernel::System::Log');
        $LogObject->Log(
            Priority => 'error',
            Message  => 'Need ID!',
        );
        return;
    }

    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # get RrsponseChangeDefaultTO obejct
    return if !$DBObject->Prepare(
        SQL => 'SELECT id, title, remove_default, add_new, new_address, '
             . 'comments, create_time, create_by, change_time, change_by '
             . 'FROM default_to WHERE id = ?',
        Bind  => [ \$Param{ID} ],
        Limit => 1,
    );

    my %DefaultTo;
    while ( my @Data = $DBObject->FetchrowArray() ) {
        %DefaultTo = (
            ID            => $Data[0],
            Title         => $Data[1],
            RemoveDefault => $Data[2],
            AddNew        => $Data[3],
            NewAddress    => $Data[4],
            Comment       => $Data[5],
            CreateTime    => $Data[6],
            CreateBy      => $Data[7],
            ChangeTime    => $Data[8],
            ChangeBy      => $Data[9],
        );
    }

    return %DefaultTo;
}

sub Delete {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{ID} ) {
        my $LogObject = $Kernel::OM->Get('Kernel::System::Log');
        $LogObject->Log(
            Priority => 'error',
            Message  => 'Need ID!',
        );
        return;
    }

    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # delete mapping
    return if !$DBObject->Do(
        SQL => 'DELETE FROM default_to_response '
             . 'WHERE default_to_id = ?',
        Bind => [ \$Param{ID} ],
    );

    # delete entry
    return $DBObject->Do(
        SQL => 'DELETE FROM default_to WHERE id = ?',
        Bind  => [ \$Param{ID} ],
    );
}

sub List {
    my ( $Self, %Param ) = @_;
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    $DBObject->Prepare(
        SQL => 'SELECT id, title FROM default_to',
    );

    my %DefaultTo;
    while ( my @Data = $DBObject->FetchrowArray() ) {
        $DefaultTo{ $Data[0] } = $Data[1];
    }

    return %DefaultTo;
}

sub TitleExistsCheck {
    my ( $Self, %Param ) = @_;
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    return if !$DBObject->Prepare(
        SQL  => 'SELECT id FROM default_to WHERE title = ?',
        Bind => [ \$Param{Title} ],
    );

    # fetch the result
    my $Flag;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        if ( !$Param{ID} || $Param{ID} ne $Row[0] ) {
            $Flag = 1;
        }
    }
    if ($Flag) {
        return 1;
    }
    return 0;
}

sub MappingAdd {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(TemplateID DefaultToID)) {
        if ( !$Param{$Needed} ) {
            my $LogObject = $Kernel::OM->Get('Kernel::System::Log');
            $LogObject->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # insert new mapping
    return if !$DBObject->Do(
        SQL => 'INSERT INTO default_to_response '
             . '(template_id, default_to_id) VALUES (?, ?)',
        Bind => [
            \$Param{TemplateID},
            \$Param{DefaultToID},
        ],
    );

    # get new id
    return if !$DBObject->Prepare(
        SQL   => 'SELECT MAX(id) FROM default_to_response '
               . 'WHERE template_id = ? AND default_to_id = ?',
        Bind  => [
            \$Param{TemplateID},
            \$Param{DefaultToID}, ],
        Limit => 1,
    );

    my $ID;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $ID = $Row[0];
    }

    # log notice
    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');
    $LogObject->Log(
        Priority => 'notice',
        Message  => "DefaultTo mapping '$ID' "
                  . "created successfully!",
    );

    return $ID;
}

sub MappingDelete {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{ID} ) {
        my $LogObject = $Kernel::OM->Get('Kernel::System::Log');
        $LogObject->Log(
            Priority => 'error',
            Message  => 'Need ID!',
        );
        return;
    }

    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # delete mapping
    return $DBObject->Do(
        SQL => 'DELETE FROM default_to_response '
             . 'WHERE id = ?',
        Bind => [ \$Param{ID} ],
    );
}

sub MappingList {
    my ( $Self, %Param ) = @_;

     # check needed stuff
    if ( !$Param{TemplateID} && !$Param{DefaultToID} ) {
        my $LogObject = $Kernel::OM->Get('Kernel::System::Log');
        $LogObject->Log(
            Priority => 'error',
            Message  => 'Got no TemplateID or DefaultToID!'
        );
        return;
    }

    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # find mapped objects
    if ( $Param{TemplateID} ) {
        $DBObject->Prepare(
            SQL => 'SELECT id, default_to_id '
                 . 'FROM default_to_response '
                 . 'WHERE template_id = ?',
            Bind => [ \$Param{TemplateID}, ],
        );
    }
    else {
        $DBObject->Prepare(
            SQL => 'SELECT id, template_id '
                 . 'FROM default_to_response '
                 . 'WHERE default_to_id = ?',
            Bind => [ \$Param{DefaultToID}, ],
        );
    }

    my %Mapping;
    while ( my @Data = $DBObject->FetchrowArray() ) {
        $Mapping{ $Data[0] } = $Data[1];
    }

    return %Mapping;
}

1;
