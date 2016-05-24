package Kernel::Language::de_AgentDefaultRecipient;

use strict;
use warnings;
use utf8;

sub Data {
    my $Self = shift;

    $Self->{Translation}->{'DefaultRecipient'} = 'Standardempfänger';
    $Self->{Translation}->{'Create and manage DefaultRecipients.'} = 'Standardempfänger erstellen und verwalten.';
    $Self->{Translation}->{'Templates <-> DefaultRecipient'} = 'Vorlagen <-> Standardempfänger';
    $Self->{Translation}->{'Link templates to DefaultRecipients.'} = 'Standardempfänger zu Vorlagen zuweisen.';
   
    $Self->{Translation}->{'Manage DefaultRecipient'} = 'Standardempfängerverwaltung';
    $Self->{Translation}->{'Add DefaultRecipient'} = 'Standardempfänger hinzufügen';
    $Self->{Translation}->{'Edit DefaultRecipient'} = 'Standardempfänger bearbeiten';
    $Self->{Translation}->{'With DefaultRecipient you could change or extend the default addresses in a ticket response dependent on the used template.'} = 
        'Mit Standardempfängern können Sie die Standardadressen in Ticketantworten auf Basis der Vorlage ändern oder ergänzen.';
    $Self->{Translation}->{"Don't forget to add new DefaultRecipients to templates."} =
        'Vergessen Sie nicht, die Standardempfänger den Vorlagen zuzuordnern.';
    $Self->{Translation}->{"Remove 'To'"} = "'An' entfernen";
    $Self->{Translation}->{"Remove 'Cc'"} = "'Cc' entfernen";
 
    $Self->{Translation}->{'Manage Template-DefaultRecipient Relations'} = 'Standardempfänger-Vorlagenzuordnungen verwalten';
    $Self->{Translation}->{'Default Recipients'} = 'Standardempfänger';
    $Self->{Translation}->{'Filter for DefaultRecipient'} = 'Filter für Standardempfänger';
    $Self->{Translation}->{'Change DefaultRecipient Relations for Template'} = 'Standardempfänger-Zuordnungen für Vorlage verändern';
    $Self->{Translation}->{'Change Template Relations for DefaultRecipient'} = 'Vorlagen-Zuordnungen für Standardempfänger verändern';
    

    return 1;
}

1;
