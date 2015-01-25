# --
# Kernel/System/DefaultRecipient.pm - core module
# Copyright (C) 2015 Alexander Sulfrian <alex@spline.inf.fu-berlin.de>
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::DefaultRecipient;

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
    for my $Needed (qw(Title RemoveTo NewAddress Comment UserID)) {
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

    # insert new DefaultRecipient
    return if !$DBObject->Do(
        SQL => 'INSERT INTO default_recipient '
             . '(title, remove_to, new_address, comments, '
             . ' create_time, create_by, change_time, change_by) '
             . 'VALUES (?, ?, ?, ?, current_timestamp, ?, current_timestamp, ?)',
        Bind => [
            \$Param{Title},
            \$Param{RemoveTo},
            \$Param{NewAddress},
            \$Param{Comment},
            \$Param{UserID},
            \$Param{UserID},
        ],
    );

    # get new id
    return if !$DBObject->Prepare(
        SQL   => 'SELECT MAX(id) FROM default_recipient WHERE title = ?',
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
        Message  => "DefaultRecipient '$ID' created successfully!",
    );

    return $ID;
}

sub Update {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(ID Title RemoveTo NewAddress Comment UserID)) {
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

    # insert new DefaultRecipient
    return if !$DBObject->Do(
        SQL => 'UPDATE default_recipient SET title = ?, remove_to = ?, '
             . 'new_address = ?, comments = ?, change_by = ?, '
             . 'change_time = current_timestamp '
             . 'WHERE id = ?',
        Bind => [
            \$Param{Title},
            \$Param{RemoveTo},
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
        SQL => 'SELECT id, title, remove_to, new_address, '
             . 'comments, create_time, create_by, change_time, change_by '
             . 'FROM default_recipient WHERE id = ?',
        Bind  => [ \$Param{ID} ],
        Limit => 1,
    );

    my %DefaultRecipient;
    while ( my @Data = $DBObject->FetchrowArray() ) {
        %DefaultRecipient = (
            ID         => $Data[0],
            Title      => $Data[1],
            RemoveTo   => $Data[2],
            NewAddress => $Data[3],
            Comment    => $Data[4],
            CreateTime => $Data[5],
            CreateBy   => $Data[6],
            ChangeTime => $Data[7],
            ChangeBy   => $Data[8],
        );
    }

    return %DefaultRecipient;
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
        SQL => 'DELETE FROM default_recipient_response '
             . 'WHERE default_recipient_id = ?',
        Bind => [ \$Param{ID} ],
    );

    # delete entry
    return $DBObject->Do(
        SQL => 'DELETE FROM default_recipient WHERE id = ?',
        Bind  => [ \$Param{ID} ],
    );
}

sub List {
    my ( $Self, %Param ) = @_;
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    $DBObject->Prepare(
        SQL => 'SELECT id, title FROM default_recipient',
    );

    my %DefaultRecipient;
    while ( my @Data = $DBObject->FetchrowArray() ) {
        $DefaultRecipient{ $Data[0] } = $Data[1];
    }

    return %DefaultRecipient;
}

sub TitleExistsCheck {
    my ( $Self, %Param ) = @_;
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    return if !$DBObject->Prepare(
        SQL  => 'SELECT id FROM default_recipient WHERE title = ?',
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
    for my $Needed (qw(TemplateID DefaultRecipientID)) {
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
        SQL => 'INSERT INTO default_recipient_response '
             . '(template_id, default_recipient_id) VALUES (?, ?)',
        Bind => [
            \$Param{TemplateID},
            \$Param{DefaultRecipientID},
        ],
    );

    # get new id
    return if !$DBObject->Prepare(
        SQL   => 'SELECT MAX(id) FROM default_recipient_response '
               . 'WHERE template_id = ? AND default_recipient_id = ?',
        Bind  => [
            \$Param{TemplateID},
            \$Param{DefaultRecipientID}, ],
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
        Message  => "DefaultRecipient mapping '$ID' "
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
        SQL => 'DELETE FROM default_recipient_response '
             . 'WHERE id = ?',
        Bind => [ \$Param{ID} ],
    );
}

sub MappingList {
    my ( $Self, %Param ) = @_;

     # check needed stuff
    if ( !$Param{TemplateID} && !$Param{DefaultRecipientID} ) {
        my $LogObject = $Kernel::OM->Get('Kernel::System::Log');
        $LogObject->Log(
            Priority => 'error',
            Message  => 'Got no TemplateID or DefaultRecipientID!'
        );
        return;
    }

    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # find mapped objects
    if ( $Param{TemplateID} ) {
        $DBObject->Prepare(
            SQL => 'SELECT id, default_recipient_id '
                 . 'FROM default_recipient_response '
                 . 'WHERE template_id = ?',
            Bind => [ \$Param{TemplateID}, ],
        );
    }
    else {
        $DBObject->Prepare(
            SQL => 'SELECT id, template_id '
                 . 'FROM default_recipient_response '
                 . 'WHERE default_recipient_id = ?',
            Bind => [ \$Param{DefaultRecipientID}, ],
        );
    }

    my %Mapping;
    while ( my @Data = $DBObject->FetchrowArray() ) {
        $Mapping{ $Data[1] } = $Data[0];
    }

    return %Mapping;
}

1;
