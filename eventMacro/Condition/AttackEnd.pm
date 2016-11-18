package eventMacro::Condition::AttackEnd;

use strict;
use Globals;

use base 'eventMacro::Conditiontypes::ListCondition';

my $id;

sub _hooks {
	['attack_end'];
}

sub validate_condition_status {
	my ( $self, $event_name, $args ) = @_;
	
	$id = $args->{ID};
	
	$self->SUPER::validate_condition_status(lc($monsters_old{$id}{'name'}));
}

sub get_new_variable_list {
	my ($self) = @_;
	my $new_variables;
	
	my $actor = $monsters_old{$id};
	
	$new_variables->{".lastMonster"} = $actor->{name};
	$new_variables->{".lastMonsterPos"} = sprintf("%d %d", $actor->{pos_to}{x}, $actor->{pos_to}{y});
	$new_variables->{".lastMonsterDist"} = sprintf("%.1f",distance(calcPosition($actor), calcPosition($char)));
	$new_variables->{".lastMonsterID"} = $actor->{binID};
	$new_variables->{".lastMonsterBinID"} = $actor->{binType};
	
	return $new_variables;
}

sub is_event_only {
	1;
}

#should never be called
sub is_fulfilled {
	0;
}

1;